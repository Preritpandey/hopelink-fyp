import express from 'express';
import asyncHandler from '../utils/asyncHandler.js';
import { getDonationsForCampaign } from '../controllers/donation.controller.js';
import {
  getCampaigns,
  getCampaign,
  createCampaign,
  updateCampaign,
  deleteCampaign,
  uploadCampaignImages,
  uploadCampaignEvidencePhotos,
  deleteCampaignImage,
  deleteCampaignEvidencePhoto,
  setPrimaryCampaignImage,
  getCampaignsWithDonationsAndEvents,
  getClosedCampaigns,
  getUpcomingCampaigns,
  getOrganizationCampaigns,
  addCampaignUpdate,
  addCampaignFaq,
  getCampaignFundStatus,
  getOrganizationFundStatus,
} from '../controllers/campaign.controller.js';
import { getApprovedCampaignReportSummary } from '../controllers/campaignReport.controller.js';
import {
  authenticate,
  authenticateIfPresent,
  authorize,
} from '../middleware/auth.middleware.js';
import { handleFileUpload } from '../config/multer.config.js';
import { uploadImage } from '../middleware/multer.js';

const router = express.Router();

// Public routes
router.get('/', authenticateIfPresent, getCampaigns);
router.get('/closed', authenticateIfPresent, getClosedCampaigns);
router.get('/upcoming', authenticateIfPresent, getUpcomingCampaigns);
router.get(
  '/with-details/all',
  authenticateIfPresent,
  getCampaignsWithDonationsAndEvents,
);
router.get('/:id/summary', asyncHandler(getApprovedCampaignReportSummary));
// Organization campaigns (protected)
router.get(
  '/organization',
  authenticate,
  authorize('organization'),
  getOrganizationCampaigns,
);
// Fund tracking routes (public)
router.get('/:id/fund-status', authenticateIfPresent, getCampaignFundStatus);
router.get('/:id', authenticateIfPresent, getCampaign);

// Protected routes (require authentication)
router.use(authenticate);

// Organization routes
router.post(
  '/',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  createCampaign
);

router.put(
  '/:id',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  updateCampaign
);

router.delete('/:id', authorize('organization'), deleteCampaign);

// Image upload routes
router.put(
  '/:id/images',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  uploadCampaignImages
);

router.put(
  '/:id/evidence',
  authorize('organization'),
  uploadImage.array('evidencePhotos', 10),
  uploadCampaignEvidencePhotos
);

router.delete(
  '/:id/images/:imageId',
  authorize('organization'),
  deleteCampaignImage
);

router.delete(
  '/:id/evidence/:imageId',
  authorize('organization'),
  deleteCampaignEvidencePhoto
);

router.put(
  '/:id/images/:imageId/set-primary',
  authorize('organization'),
  setPrimaryCampaignImage
);

// Campaign updates and FAQs
router.post('/:id/updates', authorize('organization'), addCampaignUpdate);
router.post('/:id/faqs', authorize('organization'), addCampaignFaq);

// Campaign donations (organization/admin)
router.get(
  '/:campaignId/donations',
  authorize('organization', 'admin'),
  asyncHandler(getDonationsForCampaign),
);

export default router;
