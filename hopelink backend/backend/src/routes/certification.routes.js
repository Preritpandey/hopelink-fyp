import express from 'express';
import { issueVolunteerCertification } from '../controllers/volunteerCertification.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', authenticate, authorize('organization'), issueVolunteerCertification);

export default router;
