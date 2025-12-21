import express from 'express';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import asyncHandler from '../utils/asyncHandler.js';
import {
  registerOrganization,
  getOrganizationProfile,
  updateOrganizationProfile,
  getOrganizations,
  getOrganization,
  deleteOrganization,
  approveOrganization,
  rejectOrganization,
} from '../controllers/organization.controller.js';
import { handleFileUpload } from '../config/multer.config.js';

const router = express.Router();

// Public routes
router.post(
  '/register',
  handleFileUpload([
    { name: 'logo', maxCount: 1 },
    { name: 'registrationCertificate', maxCount: 1 },
    { name: 'taxCertificate', maxCount: 1 },
    { name: 'constitutionFile', maxCount: 1 },
    { name: 'proofOfAddress', maxCount: 1 },
    { name: 'voidCheque', maxCount: 1 },
  ]),
  asyncHandler(registerOrganization)
);

router.get('/', asyncHandler(getOrganizations));
router.get('/:id', asyncHandler(getOrganization));

// Protected routes (require authentication)
router.use(authenticate);

// Organization profile routes
router.get('/profile/me', asyncHandler(getOrganizationProfile));
router.put(
  '/profile/me',
  handleFileUpload([
    { name: 'logo', maxCount: 1 },
    { name: 'registrationCertificate', maxCount: 1 },
    { name: 'taxCertificate', maxCount: 1 },
    { name: 'constitutionFile', maxCount: 1 },
    { name: 'proofOfAddress', maxCount: 1 },
  ]),
  asyncHandler(updateOrganizationProfile)
);

// Organization CRUD routes (organization owner or admin)
router.put(
  '/:id',
  handleFileUpload([
    { name: 'logo', maxCount: 1 },
    { name: 'registrationCertificate', maxCount: 1 },
    { name: 'taxCertificate', maxCount: 1 },
    { name: 'constitutionFile', maxCount: 1 },
    { name: 'proofOfAddress', maxCount: 1 },
  ]),
  updateOrganizationProfile
);

// Admin only routes
router.use(authorize('admin'));

// The getOrganizations function handles status filtering via query parameters
// You can use /organizations?status=pending or /organizations?status=approved, etc.
router.get('/status/:status', asyncHandler((req, res, next) => {
  // Map the route parameter to a query parameter
  req.query.status = req.params.status;
  return getOrganizations(req, res, next);
}));

router.put('/:id/approve', asyncHandler(approveOrganization));
router.put('/:id/reject', asyncHandler(rejectOrganization));
router.delete('/:id', asyncHandler(deleteOrganization));

export default router;