import express from 'express';
import {
  uploadCampaignReport,
  getApprovedCampaignReport,
  downloadApprovedCampaignReport,
  getOrganizationReports,
  getPendingReports,
  approveReport,
  rejectReport,
} from '../controllers/campaignReport.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { handleFileUpload } from '../config/multer.config.js';

const router = express.Router();

// Public route
router.get('/campaign/:campaignId', getApprovedCampaignReport);
router.get('/campaign/:campaignId/download', downloadApprovedCampaignReport);

// Protected routes
router.use(authenticate);

// Organization routes
router.post(
  '/:campaignId',
  authorize('organization'),
  handleFileUpload([{ name: 'report', maxCount: 1 }]),
  uploadCampaignReport
);
router.get('/organization', authorize('organization'), getOrganizationReports);

// Admin routes
router.get('/pending', authorize('admin'), getPendingReports);
router.put('/:reportId/approve', authorize('admin'), approveReport);
router.put('/:reportId/reject', authorize('admin'), rejectReport);

export default router;
