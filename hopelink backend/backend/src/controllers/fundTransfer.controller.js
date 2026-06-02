import { StatusCodes } from 'http-status-codes';
import FundTransfer from '../models/fundTransfer.model.js';
import Organization from '../models/organization.model.js';
import User from '../models/user.model.js';
import Donation from '../models/donation.model.js';
import { BadRequestError, NotFoundError, UnauthorizedError } from '../errors/index.js';
import { sendEmail } from '../services/email.service.js';
import mongoose from 'mongoose';

// @desc    Initiate fund transfer to organization
// @route   POST /api/v1/admin/fund-transfers
// @access  Private (Admin only)
export const initiateFundTransfer = async (req, res, next) => {
  try {
    const { organizationId, amount, transferMethod, reason, reference, relatedCampaigns, notes } = req.body;

    // Validation
    if (!organizationId || !amount || !transferMethod || !reason) {
      throw new BadRequestError('organizationId, amount, transferMethod, and reason are required');
    }

    if (amount <= 0) {
      throw new BadRequestError('Amount must be greater than 0');
    }

    if (!['bank_transfer', 'stripe', 'khalti', 'cash', 'cheque'].includes(transferMethod)) {
      throw new BadRequestError('Invalid transfer method');
    }

    // Check organization exists
    const organization = await Organization.findById(organizationId);
    if (!organization) {
      throw new NotFoundError('Organization not found');
    }

    // Check organization has bank details for bank transfer
    if (transferMethod === 'bank_transfer' && !organization.bankDetails) {
      throw new BadRequestError('Organization has no bank details on file');
    }

    // Check for duplicate reference if provided
    if (reference) {
      const existing = await FundTransfer.findOne({ reference });
      if (existing) {
        throw new BadRequestError('A transfer with this reference already exists');
      }
    }

    // Get bank details snapshot
    const bankDetails = organization.bankDetails
      ? {
          bankName: organization.bankDetails.bankName,
          accountHolderName: organization.bankDetails.accountHolderName,
          accountNumber: organization.bankDetails.accountNumber,
          bankBranch: organization.bankDetails.bankBranch,
        }
      : null;

    // Calculate expected completion date (3-5 business days)
    const expectedCompletionDate = new Date();
    expectedCompletionDate.setDate(expectedCompletionDate.getDate() + 5);

    // Create fund transfer record
    const fundTransfer = new FundTransfer({
      organization: organizationId,
      amount,
      transferMethod,
      bankDetails: transferMethod === 'bank_transfer' ? bankDetails : null,
      reason,
      reference: reference || undefined,
      initiatedBy: req.user._id,
      expectedCompletionDate,
      relatedCampaigns: relatedCampaigns || [],
      notes,
    });

    await fundTransfer.save();

    // Populate for response
    await fundTransfer.populate([
      { path: 'organization', select: 'organizationName officialEmail' },
      { path: 'initiatedBy', select: 'name email' },
    ]);

    // Send notification email to organization
    try {
      const admin = req.user;
      await sendEmail({
        to: organization.officialEmail,
        subject: `Fund Transfer Initiated - ${fundTransfer.transferId}`,
        template: 'fund-transfer-initiated',
        context: {
          organizationName: organization.organizationName,
          amount,
          transferId: fundTransfer.transferId,
          reference: reference || 'N/A',
          reason,
          expectedDate: expectedCompletionDate.toLocaleDateString(),
          adminName: admin.name,
        },
      });
    } catch (emailError) {
      console.error('Error sending fund transfer email:', emailError);
      // Continue even if email fails
    }

    res.status(StatusCodes.CREATED).json({
      success: true,
      message: 'Fund transfer initiated successfully',
      data: fundTransfer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all fund transfers
// @route   GET /api/v1/admin/fund-transfers
// @access  Private (Admin only)
export const getFundTransfers = async (req, res, next) => {
  try {
    const { status, organizationId, page = 1, limit = 10 } = req.query;
    const query = {};

    if (status) {
      query.status = status;
    }

    if (organizationId) {
      query.organization = organizationId;
    }

    const startIndex = (page - 1) * limit;
    const total = await FundTransfer.countDocuments(query);

    const transfers = await FundTransfer.find(query)
      .populate('organization', 'organizationName officialEmail')
      .populate('initiatedBy', 'name email')
      .populate('completedBy', 'name email')
      .sort({ initiatedAt: -1 })
      .skip(startIndex)
      .limit(parseInt(limit, 10));

    const pagination = {};
    if (startIndex + parseInt(limit, 10) < total) {
      pagination.next = { page: parseInt(page, 10) + 1, limit: parseInt(limit, 10) };
    }
    if (startIndex > 0) {
      pagination.prev = { page: parseInt(page, 10) - 1, limit: parseInt(limit, 10) };
    }

    res.status(StatusCodes.OK).json({
      success: true,
      data: transfers,
      pagination: { ...pagination, total, page: parseInt(page, 10) },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get specific fund transfer
// @route   GET /api/v1/admin/fund-transfers/:transferId
// @access  Private (Admin only)
export const getFundTransfer = async (req, res, next) => {
  try {
    const transfer = await FundTransfer.findById(req.params.transferId).populate([
      { path: 'organization', select: 'organizationName officialEmail' },
      { path: 'initiatedBy', select: 'name email' },
      { path: 'completedBy', select: 'name email' },
      { path: 'relatedCampaigns', select: 'title' },
    ]);

    if (!transfer) {
      throw new NotFoundError('Fund transfer not found');
    }

    res.status(StatusCodes.OK).json({
      success: true,
      data: transfer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get fund transfers for organization
// @route   GET /api/v1/admin/fund-transfers/org/:organizationId
// @access  Private (Admin only)
export const getFundTransfersForOrg = async (req, res, next) => {
  try {
    const { organizationId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    // Validate organization exists
    const org = await Organization.findById(organizationId);
    if (!org) {
      throw new NotFoundError('Organization not found');
    }

    const startIndex = (page - 1) * limit;
    const total = await FundTransfer.countDocuments({ organization: organizationId });

    const transfers = await FundTransfer.find({ organization: organizationId })
      .populate('initiatedBy', 'name email')
      .populate('completedBy', 'name email')
      .sort({ initiatedAt: -1 })
      .skip(startIndex)
      .limit(parseInt(limit, 10));

    const stats = await FundTransfer.aggregate([
      { $match: { organization: new mongoose.Types.ObjectId(organizationId) } },
      {
        $group: {
          _id: '$status',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 },
        },
      },
    ]);

    const pagination = {};
    if (startIndex + parseInt(limit, 10) < total) {
      pagination.next = { page: parseInt(page, 10) + 1, limit: parseInt(limit, 10) };
    }
    if (startIndex > 0) {
      pagination.prev = { page: parseInt(page, 10) - 1, limit: parseInt(limit, 10) };
    }

    res.status(StatusCodes.OK).json({
      success: true,
      data: transfers,
      stats,
      pagination: { ...pagination, total, page: parseInt(page, 10) },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update fund transfer status
// @route   PUT /api/v1/admin/fund-transfers/:transferId/status
// @access  Private (Admin only)
export const updateFundTransferStatus = async (req, res, next) => {
  try {
    const { status, notes, transactionHash, failureReason } = req.body;

    if (!status) {
      throw new BadRequestError('Status is required');
    }

    if (!['initiated', 'processing', 'completed', 'failed', 'cancelled'].includes(status)) {
      throw new BadRequestError('Invalid status');
    }

    const transfer = await FundTransfer.findById(req.params.transferId);

    if (!transfer) {
      throw new NotFoundError('Fund transfer not found');
    }

    // Update status
    transfer.status = status;
    if (notes) transfer.notes = notes;
    if (transactionHash) transfer.transactionHash = transactionHash;
    if (failureReason && status === 'failed') transfer.failureReason = failureReason;

    // Set completion details if moving to completed or failed
    if (status === 'completed' || status === 'failed') {
      transfer.completedBy = req.user._id;
      transfer.completedAt = new Date();
    }

    await transfer.save();

    // Populate for response
    await transfer.populate([
      { path: 'organization', select: 'organizationName officialEmail' },
      { path: 'initiatedBy', select: 'name email' },
      { path: 'completedBy', select: 'name email' },
    ]);

    // Send notification based on status
    try {
      const organization = await Organization.findById(transfer.organization);
      let emailTemplate, subject;

      if (status === 'completed') {
        emailTemplate = 'fund-transfer-completed';
        subject = `Fund Transfer Completed - ${transfer.transferId}`;
      } else if (status === 'failed') {
        emailTemplate = 'fund-transfer-failed';
        subject = `Fund Transfer Failed - ${transfer.transferId}`;
      }

      if (emailTemplate) {
        await sendEmail({
          to: organization.officialEmail,
          subject,
          template: emailTemplate,
          context: {
            organizationName: organization.organizationName,
            amount: transfer.amount,
            transferId: transfer.transferId,
            status,
            completedAt: new Date().toLocaleDateString(),
            failureReason: failureReason || 'N/A',
            transactionHash: transactionHash || 'N/A',
          },
        });
      }
    } catch (emailError) {
      console.error('Error sending status update email:', emailError);
    }

    res.status(StatusCodes.OK).json({
      success: true,
      message: `Fund transfer status updated to ${status}`,
      data: transfer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Cancel fund transfer
// @route   PUT /api/v1/admin/fund-transfers/:transferId/cancel
// @access  Private (Admin only)
export const cancelFundTransfer = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const transfer = await FundTransfer.findById(req.params.transferId);

    if (!transfer) {
      throw new NotFoundError('Fund transfer not found');
    }

    if (transfer.status === 'completed') {
      throw new BadRequestError('Cannot cancel a completed transfer');
    }

    if (transfer.status === 'cancelled') {
      throw new BadRequestError('Transfer is already cancelled');
    }

    transfer.status = 'cancelled';
    transfer.failureReason = reason || 'Cancelled by admin';
    transfer.completedBy = req.user._id;
    transfer.completedAt = new Date();

    await transfer.save();

    // Populate for response
    await transfer.populate([
      { path: 'organization', select: 'organizationName officialEmail' },
      { path: 'initiatedBy', select: 'name email' },
      { path: 'completedBy', select: 'name email' },
    ]);

    // Send cancellation email
    try {
      const organization = await Organization.findById(transfer.organization);
      await sendEmail({
        to: organization.officialEmail,
        subject: `Fund Transfer Cancelled - ${transfer.transferId}`,
        template: 'fund-transfer-cancelled',
        context: {
          organizationName: organization.organizationName,
          amount: transfer.amount,
          transferId: transfer.transferId,
          reason: reason || 'Cancelled by admin',
          cancelledAt: new Date().toLocaleDateString(),
        },
      });
    } catch (emailError) {
      console.error('Error sending cancellation email:', emailError);
    }

    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Fund transfer cancelled',
      data: transfer,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get fund transfer summary statistics
// @route   GET /api/v1/admin/fund-transfers/stats/summary
// @access  Private (Admin only)
export const getFundTransferStats = async (req, res, next) => {
  try {
    const { organizationId, startDate, endDate } = req.query;
    const query = {};

    if (organizationId) {
      query.organization = new mongoose.Types.ObjectId(organizationId);
    }

    if (startDate || endDate) {
      query.initiatedAt = {};
      if (startDate) query.initiatedAt.$gte = new Date(startDate);
      if (endDate) query.initiatedAt.$lte = new Date(endDate);
    }

    // Overall statistics
    const stats = await FundTransfer.aggregate([
      { $match: query },
      {
        $facet: {
          byStatus: [
            {
              $group: {
                _id: '$status',
                totalAmount: { $sum: '$amount' },
                count: { $sum: 1 },
              },
            },
          ],
          byMethod: [
            {
              $group: {
                _id: '$transferMethod',
                totalAmount: { $sum: '$amount' },
                count: { $sum: 1 },
              },
            },
          ],
          totals: [
            {
              $group: {
                _id: null,
                totalAmount: { $sum: '$amount' },
                totalTransfers: { $sum: 1 },
                avgTransferAmount: { $avg: '$amount' },
              },
            },
          ],
        },
      },
    ]);

    res.status(StatusCodes.OK).json({
      success: true,
      data: stats[0],
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get organization fund transfer summary
// @route   GET /api/v1/admin/fund-transfers/org/:organizationId/summary
// @access  Private (Admin only)
export const getOrgFundTransferSummary = async (req, res, next) => {
  try {
    const { organizationId } = req.params;

    // Validate organization exists
    const org = await Organization.findById(organizationId);
    if (!org) {
      throw new NotFoundError('Organization not found');
    }

    // Get summary data
    const [summary] = await FundTransfer.aggregate([
      { $match: { organization: new mongoose.Types.ObjectId(organizationId) } },
      {
        $group: {
          _id: null,
          totalTransferred: {
            $sum: {
              $cond: [{ $eq: ['$status', 'completed'] }, '$amount', 0],
            },
          },
          totalPending: {
            $sum: {
              $cond: [{ $in: ['$status', ['initiated', 'processing']] }, '$amount', 0],
            },
          },
          totalFailed: {
            $sum: {
              $cond: [{ $eq: ['$status', 'failed'] }, '$amount', 0],
            },
          },
          completedTransfers: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] },
          },
          pendingTransfers: {
            $sum: { $cond: [{ $in: ['$status', ['initiated', 'processing']] }, 1, 0] },
          },
          failedTransfers: {
            $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] },
          },
          totalTransfers: { $sum: 1 },
        },
      },
    ]);

    // Also get total donations collected (in NPR)
    const [donations] = await Donation.aggregate([
      { $match: { organization: new mongoose.Types.ObjectId(organizationId), status: 'completed' } },
      {
        $group: {
          _id: null,
          totalDonations: { $sum: { $ifNull: ['$convertedAmountNpr', { $ifNull: ['$campaignAmount', '$amount'] }] } },
        },
      },
    ]);

    const response = {
      organization: org.organizationName,
      fundTransfers: summary || {
        totalTransferred: 0,
        totalPending: 0,
        totalFailed: 0,
        completedTransfers: 0,
        pendingTransfers: 0,
        failedTransfers: 0,
        totalTransfers: 0,
      },
      fundraising: {
        totalDonations: donations?.totalDonations || 0,
      },
      outstandingAmount: (donations?.totalDonations || 0) - (summary?.totalTransferred || 0),
    };

    res.status(StatusCodes.OK).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Generate fund transfer receipt
// @route   GET /api/v1/admin/fund-transfers/:transferId/receipt
// @access  Private (Admin only)
export const generateFundTransferReceipt = async (req, res, next) => {
  try {
    const transfer = await FundTransfer.findById(req.params.transferId).populate([
      { path: 'organization', select: 'organizationName officialEmail registrationNumber' },
      { path: 'initiatedBy', select: 'name email' },
      { path: 'completedBy', select: 'name email' },
    ]);

    if (!transfer) {
      throw new NotFoundError('Fund transfer not found');
    }

    const receipt = {
      receiptNumber: transfer.transferId,
      reference: transfer.reference || 'N/A',
      transactionHash: transfer.transactionHash || 'N/A',
      organization: {
        name: transfer.organization.organizationName,
        registrationNumber: transfer.organization.registrationNumber,
        email: transfer.organization.officialEmail,
      },
      transfer: {
        amount: transfer.amount,
        method: transfer.transferMethod,
        reason: transfer.reason,
        status: transfer.status,
      },
      bankDetails: transfer.bankDetails,
      dates: {
        initiated: transfer.initiatedAt,
        completed: transfer.completedAt,
        expected: transfer.expectedCompletionDate,
      },
      admin: {
        initiatedBy: transfer.initiatedBy.name,
        completedBy: transfer.completedBy?.name || 'Pending',
      },
      notes: transfer.notes,
    };

    res.status(StatusCodes.OK).json({
      success: true,
      data: receipt,
    });
  } catch (error) {
    next(error);
  }
};
