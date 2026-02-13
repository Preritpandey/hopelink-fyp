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

const router = express.Router();

// User routes
router.get(
  '/my',
  authenticate,
  authorize('user'),
  getMyVolunteerApplications,
);

// Organization routes
router.get(
  '/job/:jobId',
  authenticate,
  authorize('organization'),
  getApplicationsByJob,
);
router.get(
  '/job/:jobId/approved',
  authenticate,
  authorize('organization'),
  getApprovedApplicationsByJob,
);
router.get(
  '/job/:jobId/rejected',
  authenticate,
  authorize('organization'),
  getRejectedApplicationsByJob,
);
router.get(
  '/:id/resume',
  authenticate,
  authorize('organization'),
  downloadApplicationResume,
);
router.patch(
  '/:id/approve',
  authenticate,
  authorize('organization'),
  approveVolunteerApplication,
);
router.patch(
  '/:id/reject',
  authenticate,
  authorize('organization'),
  rejectVolunteerApplication,
);
router.patch(
  '/:id/credit-hours',
  authenticate,
  authorize('organization'),
  grantVolunteerCreditHours,
);

export default router;
