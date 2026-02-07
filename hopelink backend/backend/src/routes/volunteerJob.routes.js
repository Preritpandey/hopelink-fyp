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
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { uploadResume } from '../middleware/multer.js';

const router = express.Router();

// Public routes
router.get('/', getVolunteerJobs);

// User apply
router.post(
  '/:jobId/apply',
  authenticate,
  authorize('user'),
  uploadResume.single('resume'),
  applyToVolunteerJob,
);

// Organization routes
router.get(
  '/org/my',
  authenticate,
  authorize('organization'),
  getMyOrganizationJobs,
);
router.post('/', authenticate, authorize('organization'), createVolunteerJob);
router.patch('/:jobId', authenticate, authorize('organization'), updateVolunteerJob);
router.patch(
  '/:jobId/close',
  authenticate,
  authorize('organization'),
  closeVolunteerJob,
);

// Public job detail (keep after /org/my to avoid conflict)
router.get('/:jobId', getVolunteerJobById);

export default router;
