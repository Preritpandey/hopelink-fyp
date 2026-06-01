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
router.get('/', authenticateIfPresent, asyncHandler(getCampaigns));
router.get('/closed', authenticateIfPresent, asyncHandler(getClosedCampaigns));
router.get('/upcoming', authenticateIfPresent, asyncHandler(getUpcomingCampaigns));
router.get(
  '/with-details/all',
  authenticateIfPresent,
  asyncHandler(getCampaignsWithDonationsAndEvents),
);
router.get('/:id/summary', asyncHandler(getApprovedCampaignReportSummary));
// Organization campaigns (protected)
router.get(
  '/organization',
  authenticate,
  authorize('organization'),
  asyncHandler(getOrganizationCampaigns),
);
// Fund tracking routes (public)
router.get('/:id/fund-status', authenticateIfPresent, asyncHandler(getCampaignFundStatus));
router.get('/:id', authenticateIfPresent, asyncHandler(getCampaign));

// Protected routes (require authentication)
router.use(authenticate);

// Organization routes
router.post(
  '/',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  asyncHandler(createCampaign)
);

router.put(
  '/:id',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  asyncHandler(updateCampaign)
);

router.delete('/:id', authorize('organization'), asyncHandler(deleteCampaign));

// Image upload routes
router.put(
  '/:id/images',
  authorize('organization'),
  handleFileUpload([{ name: 'images', maxCount: 10 }]),
  asyncHandler(uploadCampaignImages)
);

router.put(
  '/:id/evidence',
  authorize('organization'),
  uploadImage.array('evidencePhotos', 10),
  asyncHandler(uploadCampaignEvidencePhotos)
);

router.delete(
  '/:id/images/:imageId',
  authorize('organization'),
  asyncHandler(deleteCampaignImage)
);

router.delete(
  '/:id/evidence/:imageId',
  authorize('organization'),
  asyncHandler(deleteCampaignEvidencePhoto)
);

router.put(
  '/:id/images/:imageId/set-primary',
  authorize('organization'),
  asyncHandler(setPrimaryCampaignImage)
);

// Campaign updates and FAQs
router.post('/:id/updates', authorize('organization'), asyncHandler(addCampaignUpdate));
router.post('/:id/faqs', authorize('organization'), asyncHandler(addCampaignFaq));

// Campaign donations (organization/admin)
router.get(
  '/:campaignId/donations',
  authorize('organization', 'admin'),
  asyncHandler(getDonationsForCampaign),
);

export default router;
