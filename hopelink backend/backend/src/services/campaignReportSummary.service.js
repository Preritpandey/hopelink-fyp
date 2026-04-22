import axios from 'axios';
import fs from 'fs';
import path from 'path';
import { pipeline, env } from '@huggingface/transformers';
import { PDFParse } from 'pdf-parse';
import CampaignReport from '../models/campaignReport.model.js';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../errors/ApiError.js';
import { BadRequestError, NotFoundError } from '../errors/index.js';

const PDF_FETCH_TIMEOUT_MS = 30000;
const MAX_SOURCE_TEXT_LENGTH = 50000;
const MIN_SUMMARY_SOURCE_LENGTH = 200;
const CHUNK_SIZE = 1400;
const CHUNK_OVERLAP = 180;
const LOCAL_SUMMARIZATION_TIMEOUT_MS = 180000;
const LOCAL_SUMMARY_MODELS = [
  process.env.LOCAL_SUMMARY_MODEL || 'Xenova/distilbart-cnn-6-6',
  'Xenova/bart-large-cnn',
  'Xenova/t5-small',
].filter((value, index, array) => value && array.indexOf(value) === index);

const modelCacheDir = path.resolve(process.cwd(), '.cache', 'transformers');
env.cacheDir = process.env.TRANSFORMERS_CACHE_DIR || modelCacheDir;
env.allowLocalModels = true;
env.allowRemoteModels = process.env.ALLOW_REMOTE_MODEL_DOWNLOAD !== 'false';

let summarizerPromise = null;

const withTimeout = async (promise, timeoutMs, message) => {
  let timeoutId;

  const timeoutPromise = new Promise((_, reject) => {
    timeoutId = setTimeout(() => reject(new Error(message)), timeoutMs);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    clearTimeout(timeoutId);
  }
};

const splitIntoSentences = (text = '') =>
  text
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean);

const groupSentencesIntoParagraphs = (text, desiredParagraphs = 2) => {
  const sentences = splitIntoSentences(text);

  if (sentences.length <= 2) {
    return text.trim();
  }

  const paragraphCount = Math.min(Math.max(desiredParagraphs, 2), 3);
  const groupSize = Math.ceil(sentences.length / paragraphCount);
  const paragraphs = [];

  for (let index = 0; index < sentences.length; index += groupSize) {
    paragraphs.push(sentences.slice(index, index + groupSize).join(' ').trim());
  }

  return paragraphs.filter(Boolean).join('\n\n');
};

const fallbackSummaryFromText = (text) => {
  const cleanedText = text.trim();
  if (!cleanedText) {
    throw new BadRequestError('No readable text could be extracted from this PDF report');
  }

  const paragraphs = cleanedText
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter((paragraph) => paragraph.length > 40)
    .slice(0, 3);

  if (paragraphs.length >= 2) {
    return paragraphs.join('\n\n');
  }

  const sentences = splitIntoSentences(cleanedText).slice(0, 10).join(' ');
  return groupSentencesIntoParagraphs(sentences, 2);
};

const normalizeExtractedText = (rawText = '') => {
  const normalizedLines = rawText
    .split(/\r?\n/)
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter(Boolean);

  const dedupedLines = normalizedLines.filter((line, index, array) => {
    return index === 0 || line !== array[index - 1];
  });

  return dedupedLines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
};

const buildSourceUpdatedAt = (report) =>
  report.updatedAt || report.reportFile?.uploadedAt || new Date();

const getCachedSummaryContent = (report) =>
  report.summary || report.aiSummary?.content || null;

const getCachedGeneratedAt = (report) =>
  report.summaryGeneratedAt || report.aiSummary?.generatedAt || null;

const getCachedModel = (report) =>
  report.summaryModel || report.aiSummary?.model || null;

const getCachedSourceUpdatedAt = (report) =>
  report.summarySourceUpdatedAt || report.aiSummary?.sourceUpdatedAt || null;

const isSummaryCacheValid = (report) => {
  if (!getCachedSummaryContent(report) || !getCachedGeneratedAt(report)) {
    return false;
  }

  const sourceUpdatedAt = buildSourceUpdatedAt(report);
  const cachedSourceUpdatedAt = getCachedSourceUpdatedAt(report);

  if (!cachedSourceUpdatedAt) {
    return false;
  }

  return new Date(cachedSourceUpdatedAt).getTime() >= new Date(sourceUpdatedAt).getTime();
};

const loadPdfBuffer = async (report) => {
  const pdfUrl = report.reportFile?.url;
  const localPath = report.reportFile?.localPath;

  if (pdfUrl) {
    try {
      const response = await axios.get(pdfUrl, {
        responseType: 'arraybuffer',
        timeout: PDF_FETCH_TIMEOUT_MS,
      });

      return Buffer.from(response.data);
    } catch (error) {
      throw new ApiError(
        'Unable to retrieve the campaign report PDF for summarization',
        StatusCodes.BAD_GATEWAY
      );
    }
  }

  if (localPath && fs.existsSync(localPath)) {
    return fs.promises.readFile(localPath);
  }

  throw new NotFoundError('Report file is unavailable for summarization');
};

const extractTextFromPdf = async (report) => {
  let parser;

  try {
    const pdfBuffer = await loadPdfBuffer(report);
    parser = new PDFParse({ data: pdfBuffer });
    const parsed = await parser.getText();
    const normalizedText = normalizeExtractedText(parsed?.text);

    if (!normalizedText || normalizedText.length < MIN_SUMMARY_SOURCE_LENGTH) {
      throw new BadRequestError('The PDF report does not contain enough readable text to summarize');
    }

    return normalizedText.length > MAX_SOURCE_TEXT_LENGTH
      ? normalizedText.slice(0, MAX_SOURCE_TEXT_LENGTH)
      : normalizedText;
  } catch (error) {
    if (error.isOperational) {
      throw error;
    }

    throw new BadRequestError('The PDF report could not be parsed for summarization');
  } finally {
    if (parser) {
      await parser.destroy().catch(() => {});
    }
  }
};

const createTextChunks = (text) => {
  const chunks = [];
  const normalizedText = text.replace(/\n+/g, ' ').replace(/\s+/g, ' ').trim();

  if (!normalizedText) {
    return chunks;
  }

  let start = 0;
  while (start < normalizedText.length) {
    let end = Math.min(start + CHUNK_SIZE, normalizedText.length);

    if (end < normalizedText.length) {
      const lastSentenceBoundary = Math.max(
        normalizedText.lastIndexOf('. ', end),
        normalizedText.lastIndexOf('! ', end),
        normalizedText.lastIndexOf('? ', end)
      );

      if (lastSentenceBoundary > start + 400) {
        end = lastSentenceBoundary + 1;
      }
    }

    const chunk = normalizedText.slice(start, end).trim();
    if (chunk) {
      chunks.push(chunk);
    }

    if (end >= normalizedText.length) {
      break;
    }

    start = Math.max(end - CHUNK_OVERLAP, start + 1);
  }

  return chunks;
};

const extractSummaryText = (result) => {
  if (Array.isArray(result) && result[0]?.summary_text) {
    return result[0].summary_text.trim();
  }

  if (typeof result === 'string') {
    return result.trim();
  }

  return '';
};

const loadLocalSummarizer = async () => {
  let lastError;

  for (const model of LOCAL_SUMMARY_MODELS) {
    try {
      const instance = await pipeline('summarization', model);
      return {
        model,
        instance,
      };
    } catch (error) {
      lastError = error;
      console.error(`Failed to load local summarizer model ${model}:`, error.message);
    }
  }

  throw new Error(
    `Unable to load any local summarization model. Last error: ${lastError?.message || 'Unknown error'}`
  );
};

const getLocalSummarizer = async () => {
  if (!summarizerPromise) {
    summarizerPromise = loadLocalSummarizer().catch((error) => {
      summarizerPromise = null;
      throw error;
    });
  }

  return summarizerPromise;
};

const summarizeChunk = async (chunk) => {
  const summarizer = await getLocalSummarizer();
  const output = await summarizer.instance(chunk, {
    max_new_tokens: 160,
    min_length: 40,
    do_sample: false,
  });

  const summary = extractSummaryText(output);
  if (!summary) {
    throw new Error('Local summarizer returned an empty summary');
  }

  return {
    summary: summary.replace(/\s+/g, ' ').trim(),
    model: summarizer.model,
  };
};

const summarizeTextHierarchically = async (text) => {
  const chunks = createTextChunks(text);

  if (!chunks.length) {
    throw new Error('No text chunks were generated for summarization');
  }

  const firstPassSummaries = [];
  let modelUsed = null;

  for (const chunk of chunks) {
    const result = await summarizeChunk(chunk);
    firstPassSummaries.push(result.summary);
    modelUsed = result.model;
  }

  let mergedSummary = firstPassSummaries.join(' ');
  if (firstPassSummaries.length > 1) {
    const secondPass = await summarizeChunk(mergedSummary);
    mergedSummary = secondPass.summary;
    modelUsed = secondPass.model;
  }

  return {
    summary: groupSentencesIntoParagraphs(mergedSummary, 2),
    model: modelUsed || 'local-transformer',
  };
};

const persistSummary = async ({ report, summary, model }) => {
  const sourceUpdatedAt = buildSourceUpdatedAt(report);
  const generatedAt = new Date();

  report.summary = summary;
  report.summaryGeneratedAt = generatedAt;
  report.summaryModel = model;
  report.summarySourceUpdatedAt = sourceUpdatedAt;
  report.aiSummary = {
    content: summary,
    generatedAt,
    model,
    sourceUpdatedAt,
  };
  await report.save();

  return {
    generatedAt,
    model,
  };
};

export const getCampaignReportSummary = async (campaignId) => {
  const report = await CampaignReport.findOne({
    campaign: campaignId,
    status: 'approved',
  }).populate('campaign', 'title');

  if (!report) {
    throw new NotFoundError('No approved campaign report found for this campaign');
  }

  if (isSummaryCacheValid(report)) {
    return {
      report,
      summary: getCachedSummaryContent(report),
      generatedAt: getCachedGeneratedAt(report),
      model: getCachedModel(report),
      cached: true,
    };
  }

  const reportText = await extractTextFromPdf(report);

  try {
    const summaryResult = await withTimeout(
      summarizeTextHierarchically(reportText),
      LOCAL_SUMMARIZATION_TIMEOUT_MS,
      'Local summarization timed out'
    );

    const persisted = await persistSummary({
      report,
      summary: summaryResult.summary,
      model: summaryResult.model,
    });

    return {
      report,
      summary: summaryResult.summary,
      generatedAt: persisted.generatedAt,
      model: persisted.model,
      cached: false,
    };
  } catch (error) {
    console.error('Local summarization failed, using extractive fallback:', error.message);

    const fallbackSummary = fallbackSummaryFromText(reportText);
    const persisted = await persistSummary({
      report,
      summary: fallbackSummary,
      model: 'extractive-fallback',
    });

    return {
      report,
      summary: fallbackSummary,
      generatedAt: persisted.generatedAt,
      model: persisted.model,
      cached: false,
    };
  }
};
