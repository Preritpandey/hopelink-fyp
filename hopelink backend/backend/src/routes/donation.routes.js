import express from 'express';
import asyncHandler from '../utils/asyncHandler.js';
import {
  createDonation,
  getDonations,
  getDonation,
  getDonationsForCampaign,
  getUserDonations,
  updateDonationStatus,
  getOrgDonationSummary,
  getDonationsSummaryByOrg,
} from '../controllers/donation.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';

const router = express.Router();

// Public routes (if any)
// router.get('/', getDonations);

// Protected routes (require authentication)
router.use(authenticate);

router.get('/', asyncHandler(getDonations));

// User routes
router.post('/', asyncHandler(createDonation));
router.get('/user', asyncHandler(getUserDonations)); // Get current user's donations
router.get('/:id', asyncHandler(getDonation));

// Organization routes (organization admins)
router.get('/campaign/:campaignId', authorize('organization', 'admin'), asyncHandler(getDonationsForCampaign));
router.get(
  '/summary/org',
  authorize('organization', 'admin'),
  asyncHandler(getOrgDonationSummary),
);

// Donation summaries (admin)
router.get(
  '/summary/all',
  authorize('admin'),
  asyncHandler(getDonationsSummaryByOrg),
);

// Admin routes
router.put('/:id/status', authorize('admin', 'organization'), asyncHandler(updateDonationStatus));

// Get donations for a specific user (admin or the user themselves)
router.get('/user/:userId', asyncHandler(async (req, res, next) => {
  // If user is admin or requesting their own donations
  if (req.user.role === 'admin' || req.params.userId === req.user._id.toString()) {
    return getUserDonations(req, res, next);
  }
  return res.status(403).json({
    success: false,
    error: 'Not authorized to access this resource',
  });
}));

export default router;
