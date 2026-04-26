import express from 'express';
import asyncHandler from '../utils/asyncHandler.js';
import {
  createRequest,
  deleteRequest,
  getRequestById,
  getRequests,
  updateRequest,
} from '../controllers/essentialRequest.controller.js';
import {
  authenticate,
  authorize,
} from '../middleware/auth.middleware.js';
import validate from '../middleware/validate.middleware.js';
import {
  createEssentialRequestRules,
  listEssentialRequestsRules,
  requestIdParamRules,
  updateEssentialRequestRules,
} from '../utils/essentialDonation.validators.js';
import { uploadImage } from '../middleware/multer.js';

const router = express.Router();

const parseJsonField = (value, fallback) => {
  if (value == null || value === '') {
    return fallback;
  }
  if (typeof value !== 'string') {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch (_) {
    return value;
  }
};

const normalizeEssentialRequestPayload = (req, res, next) => {
  req.body.itemsNeeded = parseJsonField(req.body.itemsNeeded, []);
  req.body.pickupLocations = parseJsonField(req.body.pickupLocations, []);
  req.body.images = parseJsonField(req.body.images, []);
  return next();
};

router.get('/', validate(listEssentialRequestsRules), asyncHandler(getRequests));
router.get('/:id', validate(requestIdParamRules), asyncHandler(getRequestById));

router.use(authenticate);

router.post(
  '/',
  authorize('organization'),
  uploadImage.array('images', 5),
  normalizeEssentialRequestPayload,
  validate(createEssentialRequestRules),
  asyncHandler(createRequest),
);

router.put(
  '/:id',
  authorize('organization', 'admin'),
  uploadImage.array('images', 5),
  normalizeEssentialRequestPayload,
  validate(updateEssentialRequestRules),
  asyncHandler(updateRequest),
);

router.delete(
  '/:id',
  authorize('organization', 'admin'),
  validate(requestIdParamRules),
  asyncHandler(deleteRequest),
);

export default router;
