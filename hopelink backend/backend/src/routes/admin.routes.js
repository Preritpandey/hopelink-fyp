import express from 'express';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import {
  getAllOrganizations,
  getPendingOrganizations,
  approveOrganization,
  rejectOrganization,
} from '../controllers/admin.controller.js';
import {
  getAdminDonations,
  getAdminDonationById,
  getAdminPlatformSupportDonations,
  getAdminUserDonations,
  getPlatformFeeSummary,
  getMonthlyPlatformFees,
  getYearlyPlatformFees,
  getPlatformFeesByCampaign,
  getAdminDonationDashboardStats,
} from '../controllers/donation.controller.js';
import asyncHandler from '../utils/asyncHandler.js';

const router = express.Router();

// Protect all routes with authentication and admin authorization
router.use(authenticate);
router.use(authorize('admin'));

// Organization management routes
router.get('/orgs', getAllOrganizations);
router.get('/orgs/pending', getPendingOrganizations);
router.put('/orgs/approve/:id', approveOrganization);
router.put('/orgs/reject/:id', rejectOrganization);

// Donation management and platform fee analytics
router.get('/donations', asyncHandler(getAdminDonations));
router.get('/donations/dashboard', asyncHandler(getAdminDonationDashboardStats));
router.get(
  '/platform-support-donations',
  asyncHandler(getAdminPlatformSupportDonations),
);
router.get('/users/:userId/donations', asyncHandler(getAdminUserDonations));
router.get('/platform-fees/summary', asyncHandler(getPlatformFeeSummary));
router.get('/platform-fees/monthly', asyncHandler(getMonthlyPlatformFees));
router.get('/platform-fees/yearly', asyncHandler(getYearlyPlatformFees));
router.get('/platform-fees/campaigns', asyncHandler(getPlatformFeesByCampaign));
router.get('/donations/:id', asyncHandler(getAdminDonationById));

export default router;
