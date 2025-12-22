import express from 'express';
import {
  createDonation,
  getDonations,
  getDonation,
  getDonationsForCampaign,
  getUserDonations,
  updateDonationStatus,
} from '../controllers/donation.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';

const router = express.Router();

// Public routes (if any)
// router.get('/', getDonations);

// Protected routes (require authentication)
router.get('/', getDonations);
router.use(authenticate);

// User routes
router.post('/', createDonation);
router.get('/user', getUserDonations); // Get current user's donations
router.get('/:id', getDonation);

// Organization routes (organization admins)
router.get('/campaign/:campaignId', authorize('organization', 'admin'), getDonationsForCampaign);

// Admin routes
router.put('/:id/status', authorize('admin', 'organization'), updateDonationStatus);

// Get donations for a specific user (admin or the user themselves)
router.get('/user/:userId', async (req, res, next) => {
  // If user is admin or requesting their own donations
  if (req.user.role === 'admin' || req.params.userId === req.user.id) {
    return getUserDonations(req, res, next);
  }
  return res.status(403).json({
    success: false,
    error: 'Not authorized to access this resource',
  });
});

export default router;
