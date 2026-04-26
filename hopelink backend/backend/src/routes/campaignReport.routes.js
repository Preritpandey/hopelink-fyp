import express from 'express';
import {
  uploadCampaignReport,
  getApprovedCampaignReport,
  downloadApprovedCampaignReport,
  downloadReportById,
  getOrganizationReports,
  getOrganizationCampaignReport,
  getPendingReports,
  approveReport,
  rejectReport,
} from '../controllers/campaignReport.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { uploadPdf } from '../middleware/multer.js';

const router = express.Router();

// Public route
router.get('/campaign/:campaignId', getApprovedCampaignReport);
router.get('/campaign/:campaignId/download', downloadApprovedCampaignReport);

// Protected routes
router.use(authenticate);

// Organization routes
router.get(
  '/campaign/:campaignId/organization',
  authorize('organization'),
  getOrganizationCampaignReport
);
router.post(
  '/:campaignId',
  authorize('organization'),
  uploadPdf.single('report'),
  uploadCampaignReport
);
router.get('/organization', authorize('organization'), getOrganizationReports);

// Admin routes
router.get('/pending', authorize('admin'), getPendingReports);
router.get('/:reportId/download', authorize('admin'), downloadReportById);
router.put('/:reportId/approve', authorize('admin'), approveReport);
router.put('/:reportId/reject', authorize('admin'), rejectReport);

export default router;
