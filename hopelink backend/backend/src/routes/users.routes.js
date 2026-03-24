import express from 'express';
import { getMyCertifications } from '../controllers/volunteerCertification.controller.js';
import {
  getMyActivities,
  getUserActivities,
} from '../controllers/userActivity.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/me/certifications', getMyCertifications);
router.get('/me/activities', getMyActivities);
router.get('/:userId/activities', getUserActivities);

export default router;
