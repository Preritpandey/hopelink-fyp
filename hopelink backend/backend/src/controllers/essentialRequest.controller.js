import { StatusCodes } from 'http-status-codes';
import {
  createEssentialRequest,
  deleteEssentialRequest,
  getEssentialRequestDetails,
  listEssentialRequests,
  updateEssentialRequest,
} from '../services/essentialRequest.service.js';
import { handleMultipleFileUploads } from '../services/cloudinary.service.js';

const appendUploadedImages = async (req) => {
  if (!Array.isArray(req.files) || req.files.length == 0) {
    return;
  }

  const uploadResults = await handleMultipleFileUploads(
    req.files,
    'hopelink/essential-requests',
  );
  const uploadedUrls = uploadResults
    .map((item) => item.url)
    .filter((item) => typeof item === 'string' && item.trim().length > 0);

  const existingImages = Array.isArray(req.body.images) ? req.body.images : [];
  req.body.images = [...existingImages, ...uploadedUrls];
};

export const createRequest = async (req, res) => {
  await appendUploadedImages(req);
  const request = await createEssentialRequest({
    payload: req.body,
    user: req.user,
  });

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: request,
  });
};

export const getRequests = async (req, res) => {
  const requests = await listEssentialRequests({
    filters: {
      category: req.query.category,
      urgency: req.query.urgency,
    },
  });

  res.status(StatusCodes.OK).json({
    success: true,
    count: requests.length,
    data: requests,
  });
};

export const getRequestById = async (req, res) => {
  const request = await getEssentialRequestDetails(req.params.id);

  res.status(StatusCodes.OK).json({
    success: true,
    data: request,
  });
};

export const updateRequest = async (req, res) => {
  await appendUploadedImages(req);
  const request = await updateEssentialRequest({
    requestId: req.params.id,
    payload: req.body,
    user: req.user,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: request,
  });
};

export const deleteRequest = async (req, res) => {
  await deleteEssentialRequest({
    requestId: req.params.id,
    user: req.user,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: {},
  });
};
