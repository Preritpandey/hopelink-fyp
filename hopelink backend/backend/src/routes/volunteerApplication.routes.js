import express from 'express';
import {
  getMyVolunteerApplications,
  getApplicationsByJob,
  getApprovedApplicationsByJob,
  getRejectedApplicationsByJob,
  approveVolunteerApplication,
  rejectVolunteerApplication,
  downloadApplicationResume,
  grantVolunteerCreditHours,
} from '../controllers/volunteerApplication.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import asyncHandler from '../utils/asyncHandler.js';

const router = express.Router();

// User routes
router.get(
  '/my',
  authenticate,
  authorize('user'),
  asyncHandler(getMyVolunteerApplications),
);

// Organization routes
router.get(
  '/job/:jobId',
  authenticate,
  authorize('organization'),
  asyncHandler(getApplicationsByJob),
);
router.get(
  '/job/:jobId/approved',
  authenticate,
  authorize('organization'),
  asyncHandler(getApprovedApplicationsByJob),
);
router.get(
  '/job/:jobId/rejected',
  authenticate,
  authorize('organization'),
  asyncHandler(getRejectedApplicationsByJob),
);
router.get(
  '/:id/resume',
  authenticate,
  authorize('organization'),
  asyncHandler(downloadApplicationResume),
);
router.patch(
  '/:id/approve',
  authenticate,
  authorize('organization'),
  asyncHandler(approveVolunteerApplication),
);
router.patch(
  '/:id/reject',
  authenticate,
  authorize('organization'),
  asyncHandler(rejectVolunteerApplication),
);
router.patch(
  '/:id/credit-hours',
  authenticate,
  authorize('organization'),
  asyncHandler(grantVolunteerCreditHours),
);

export default router;
