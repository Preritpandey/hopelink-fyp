import express from 'express';
import asyncHandler from '../utils/asyncHandler.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import {
  initiateFundTransfer,
  getFundTransfers,
  getFundTransfer,
  getFundTransfersForOrg,
  updateFundTransferStatus,
  cancelFundTransfer,
  getFundTransferStats,
  getOrgFundTransferSummary,
  generateFundTransferReceipt,
} from '../controllers/fundTransfer.controller.js';

const router = express.Router();

// Protect all routes with authentication and admin authorization
router.use(authenticate);
router.use(authorize('admin'));

// Fund transfer management routes
router.post('/', asyncHandler(initiateFundTransfer));
router.get('/', asyncHandler(getFundTransfers));
router.get('/stats/summary', asyncHandler(getFundTransferStats));
router.get('/:transferId', asyncHandler(getFundTransfer));
router.put('/:transferId/status', asyncHandler(updateFundTransferStatus));
router.put('/:transferId/cancel', asyncHandler(cancelFundTransfer));
router.get('/:transferId/receipt', asyncHandler(generateFundTransferReceipt));

// Organization-specific fund transfer routes
router.get('/org/:organizationId/history', asyncHandler(getFundTransfersForOrg));
router.get('/org/:organizationId/summary', asyncHandler(getOrgFundTransferSummary));

export default router;
