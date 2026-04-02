import { StatusCodes } from 'http-status-codes';
import CampaignReport from '../models/campaignReport.model.js';
import Campaign from '../models/campaign.model.js';
import Organization from '../models/organization.model.js';
import {
  BadRequestError,
  NotFoundError,
  UnauthorizedError,
} from '../errors/index.js';
import fs from 'fs';

const ensurePdfFile = (file) => {
  if (!file) {
    throw new BadRequestError('Please upload a PDF report');
  }

  if (file.mimetype !== 'application/pdf') {
    throw new BadRequestError('Only PDF files are allowed for reports');
  }
};

const buildReportResponse = (report) => ({
  id: report._id,
  campaign: report.campaign,
  organization: report.organization,
  status: report.status,
  submittedAt: report.submittedAt,
  reviewedBy: report.reviewedBy,
  reviewedAt: report.reviewedAt,
  rejectionReason: report.rejectionReason,
  reportFile: report.reportFile
    ? {
        localPath: report.reportFile.localPath,
        originalName: report.reportFile.originalName,
        mimeType: report.reportFile.mimeType,
        size: report.reportFile.size,
        uploadedAt: report.reportFile.uploadedAt,
      }
    : null,
});

// @desc    Upload or replace a campaign report (PDF)
// @route   POST /api/v1/campaign-reports/:campaignId
// @access  Private (Organization)
export const uploadCampaignReport = async (req, res) => {
  const file = req.files?.report?.[0];
  ensurePdfFile(file);

  const campaign = await Campaign.findById(req.params.campaignId);
  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.campaignId}`);
  }

  if (campaign.organization.toString() !== req.user.organization?.toString()) {
    throw new UnauthorizedError('You are not authorized to upload report for this campaign');
  }

  const organization = await Organization.findById(req.user.organization);
  if (!organization) {
    throw new BadRequestError('No organization found for this user');
  }

  const reportFile = {
    localPath: file.path,
    originalName: file.originalname,
    mimeType: file.mimetype,
    size: file.size,
    uploadedAt: new Date(),
  };

  const existingReport = await CampaignReport.findOne({ campaign: campaign._id });

  let report;
  if (existingReport) {
    if (existingReport.reportFile?.localPath && fs.existsSync(existingReport.reportFile.localPath)) {
      try {
        fs.unlinkSync(existingReport.reportFile.localPath);
      } catch (error) {
        console.warn('Failed to delete old report file:', error.message);
      }
    }

    existingReport.reportFile = reportFile;
    existingReport.status = 'pending';
    existingReport.submittedAt = new Date();
    existingReport.reviewedBy = null;
    existingReport.reviewedAt = null;
    existingReport.rejectionReason = null;
    report = await existingReport.save();
  } else {
    report = await CampaignReport.create({
      campaign: campaign._id,
      organization: organization._id,
      reportFile,
      status: 'pending',
      submittedAt: new Date(),
    });
  }

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: buildReportResponse(report),
    message: 'Report submitted for admin verification',
  });
};

// @desc    Get approved campaign report (public)
// @route   GET /api/v1/campaign-reports/campaign/:campaignId
// @access  Public
export const getApprovedCampaignReport = async (req, res) => {
  const report = await CampaignReport.findOne({
    campaign: req.params.campaignId,
    status: 'approved',
  });

  if (!report) {
    throw new NotFoundError('No approved report found for this campaign');
  }

  res.status(StatusCodes.OK).json({
    success: true,
    data: {
      campaign: report.campaign,
      reportFile: {
        originalName: report.reportFile.originalName,
        mimeType: report.reportFile.mimeType,
        size: report.reportFile.size,
        uploadedAt: report.reportFile.uploadedAt,
      },
      downloadEndpoint: `/api/v1/campaign-reports/campaign/${report.campaign}/download`,
      approvedAt: report.reviewedAt,
    },
  });
};

// @desc    Download approved campaign report (public)
// @route   GET /api/v1/campaign-reports/campaign/:campaignId/download
// @access  Public
export const downloadApprovedCampaignReport = async (req, res) => {
  const report = await CampaignReport.findOne({
    campaign: req.params.campaignId,
    status: 'approved',
  });

  if (!report) {
    throw new NotFoundError('No approved report found for this campaign');
  }

  const filePath = report.reportFile?.localPath;
  if (!filePath || !fs.existsSync(filePath)) {
    throw new NotFoundError('Report file not found');
  }

  return res.download(filePath, report.reportFile.originalName || 'campaign-report.pdf');
};

// @desc    Get reports for logged-in organization
// @route   GET /api/v1/campaign-reports/organization
// @access  Private (Organization)
export const getOrganizationReports = async (req, res) => {
  const reports = await CampaignReport.find({
    organization: req.user.organization,
  }).sort('-submittedAt');

  res.status(StatusCodes.OK).json({
    success: true,
    count: reports.length,
    data: reports.map(buildReportResponse),
  });
};

// @desc    Get pending reports (admin)
// @route   GET /api/v1/campaign-reports/pending
// @access  Private (Admin)
export const getPendingReports = async (req, res) => {
  const reports = await CampaignReport.find({ status: 'pending' })
    .populate('campaign', 'title')
    .populate('organization', 'organizationName')
    .sort('-submittedAt');

  res.status(StatusCodes.OK).json({
    success: true,
    count: reports.length,
    data: reports.map(buildReportResponse),
  });
};

// @desc    Approve report (admin)
// @route   PUT /api/v1/campaign-reports/:reportId/approve
// @access  Private (Admin)
export const approveReport = async (req, res) => {
  const report = await CampaignReport.findById(req.params.reportId);

  if (!report) {
    throw new NotFoundError('Report not found');
  }

  report.status = 'approved';
  report.reviewedBy = req.user._id;
  report.reviewedAt = new Date();
  report.rejectionReason = null;
  await report.save();

  res.status(StatusCodes.OK).json({
    success: true,
    data: buildReportResponse(report),
    message: 'Report approved',
  });
};

// @desc    Reject report (admin)
// @route   PUT /api/v1/campaign-reports/:reportId/reject
// @access  Private (Admin)
export const rejectReport = async (req, res) => {
  const { reason } = req.body;

  if (!reason || !reason.trim()) {
    throw new BadRequestError('Rejection reason is required');
  }

  const report = await CampaignReport.findById(req.params.reportId);

  if (!report) {
    throw new NotFoundError('Report not found');
  }

  report.status = 'rejected';
  report.reviewedBy = req.user._id;
  report.reviewedAt = new Date();
  report.rejectionReason = reason.trim();
  await report.save();

  res.status(StatusCodes.OK).json({
    success: true,
    data: buildReportResponse(report),
    message: 'Report rejected',
  });
};
