import express from 'express';
import { getMyCertifications } from '../controllers/volunteerCertification.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.get('/me/certifications', getMyCertifications);

export default router;
