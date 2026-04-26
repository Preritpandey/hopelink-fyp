import express from 'express';
import asyncHandler from '../utils/asyncHandler.js';
import {
  createCommitment,
  getCurrentUserCommitments,
  getOrganizationRequestCommitments,
  updateCommitmentStatus,
} from '../controllers/donationCommitment.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import validate from '../middleware/validate.middleware.js';
import {
  commitmentIdParamRules,
  createCommitmentRules,
  orgRequestCommitmentsRules,
  updateCommitmentStatusRules,
} from '../utils/essentialDonation.validators.js';

const router = express.Router();

router.post(
  '/commit-donation',
  authenticate,
  authorize('user'),
  validate(createCommitmentRules),
  asyncHandler(createCommitment),
);

router.get(
  '/user/commitments',
  authenticate,
  authorize('user', 'admin'),
  asyncHandler(getCurrentUserCommitments),
);

router.get(
  '/org/requests/:id/commitments',
  authenticate,
  authorize('organization', 'admin'),
  validate(orgRequestCommitmentsRules),
  asyncHandler(getOrganizationRequestCommitments),
);

router.put(
  '/commit-donation/:id/status',
  authenticate,
  validate(updateCommitmentStatusRules),
  asyncHandler(updateCommitmentStatus),
);

export default router;
