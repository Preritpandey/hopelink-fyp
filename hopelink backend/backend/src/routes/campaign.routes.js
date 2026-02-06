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
  deleteCampaignImage,
  setPrimaryCampaignImage,
  getCampaignsWithDonationsAndEvents,
  addCampaignUpdate,
  addCampaignFaq,
  getCampaignFundStatus,
  getOrganizationFundStatus,
} from '../controllers/campaign.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { handleFileUpload } from '../config/multer.config.js';

const router = express.Router();

// Public routes
router.get('/', getCampaigns);
router.get('/:id', getCampaign);
router.get('/with-details/all', getCampaignsWithDonationsAndEvents);
// Fund tracking routes (public)
router.get('/:id/fund-status', getCampaignFundStatus);

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

router.delete(
  '/:id/images/:imageId',
  authorize('organization'),
  deleteCampaignImage
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
