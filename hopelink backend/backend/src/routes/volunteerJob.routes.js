import express from 'express';
import {
  createVolunteerJob,
  updateVolunteerJob,
  closeVolunteerJob,
  getVolunteerJobs,
  getVolunteerJobById,
  getMyOrganizationJobs,
} from '../controllers/volunteerJob.controller.js';
import { applyToVolunteerJob } from '../controllers/volunteerApplication.controller.js';
import {
  authenticate,
  authenticateIfPresent,
  authorize,
} from '../middleware/auth.middleware.js';
import asyncHandler from '../utils/asyncHandler.js';
import { uploadResume } from '../middleware/multer.js';

const router = express.Router();

// Public routes
router.get('/', authenticateIfPresent, asyncHandler(getVolunteerJobs));

// User apply
router.post(
  '/:jobId/apply',
  authenticate,
  authorize('user'),
  uploadResume.single('resume'),
  asyncHandler(applyToVolunteerJob),
);

// Organization routes
router.get(
  '/org/my',
  authenticate,
  authorize('organization'),
  asyncHandler(getMyOrganizationJobs),
);
router.post('/', authenticate, authorize('organization'), asyncHandler(createVolunteerJob));
router.patch('/:jobId', authenticate, authorize('organization'), asyncHandler(updateVolunteerJob));
router.patch(
  '/:jobId/close',
  authenticate,
  authorize('organization'),
  asyncHandler(closeVolunteerJob),
);

// Public job detail (keep after /org/my to avoid conflict)
router.get('/:jobId', authenticateIfPresent, asyncHandler(getVolunteerJobById));

export default router;
