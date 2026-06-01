import { StatusCodes } from 'http-status-codes';
import Donation from '../models/donation.model.js';
import PlatformSupportTransaction from '../models/platformSupportTransaction.model.js';
import Campaign from '../models/campaign.model.js';
import User from '../models/user.model.js';
import Organization from '../models/organization.model.js';
import { logUserActivity } from '../services/activity.service.js';
import {
  BadRequestError,
  NotFoundError,
  UnauthorizedError,
} from '../errors/index.js';
import { sendEmail } from '../services/email.service.js';
import {
  normalizeKhaltiAmount,
  getKhaltiPaymentId,
  lookupKhaltiEpayment,
  isKhaltiEpaymentCompleted,
  retrieveStripePaymentIntent,
  isStripePaymentSuccessful,
  stripeAmountToMajorUnit,
  convertToNPR,
} from '../services/payment.service.js';
import mongoose from 'mongoose';
import path from 'path';

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const toAmount = (value, fallback = 0) => {
  const number = Number(value ?? fallback);
  return Number.isFinite(number) ? number : fallback;
};

const resolveDonationAmounts = ({
  amount,
  campaignAmount,
  supportPlatform,
  platformSupportAmount,
  totalAmount,
  amountIncludesSupport = false,
}) => {
  const supportAmount = supportPlatform
    ? toAmount(platformSupportAmount, 0)
    : 0;
  const rawAmount = toAmount(amount, 0);
  const resolvedCampaignAmount =
    campaignAmount != null
      ? toAmount(campaignAmount, 0)
      : amountIncludesSupport
        ? rawAmount - supportAmount
        : rawAmount;
  const resolvedTotalAmount =
    totalAmount != null
      ? toAmount(totalAmount, 0)
      : resolvedCampaignAmount + supportAmount;

  if (resolvedCampaignAmount < 1) {
    throw new BadRequestError('Campaign donation amount must be at least 1');
  }

  if (supportAmount < 0) {
    throw new BadRequestError('Platform support amount cannot be negative');
  }

  if (resolvedTotalAmount !== resolvedCampaignAmount + supportAmount) {
    throw new BadRequestError(
      'Total amount must equal campaign amount plus platform support amount',
    );
  }

  return {
    campaignAmount: resolvedCampaignAmount,
    platformSupportAmount: supportAmount,
    totalAmount: resolvedTotalAmount,
    supportPlatform: supportAmount > 0,
  };
};

const campaignDonationNprExpression = {
  $ifNull: ['$convertedAmountNpr', { $ifNull: ['$campaignAmount', '$amount'] }],
};

const totalDonationNprExpression = {
  $ifNull: [
    '$convertedTotalAmountNpr',
    {
      $ifNull: [
        '$totalAmount',
        { $add: [campaignDonationNprExpression, 0] },
      ],
    },
  ],
};

const roundNpr = (value) => Number(Number(value || 0).toFixed(2));

const buildNprConversionSnapshot = ({
  campaignAmount,
  platformSupportAmount = 0,
  totalAmount,
  currency = 'NPR',
  exchangeRate = 1,
}) => {
  const originalCampaignAmount = toAmount(campaignAmount, 0);
  const originalPlatformSupportAmount = toAmount(platformSupportAmount, 0);
  const originalTotalAmount = toAmount(
    totalAmount,
    originalCampaignAmount + originalPlatformSupportAmount,
  );
  const rate = toAmount(exchangeRate, 1);

  return {
    originalAmount: originalCampaignAmount,
    originalCampaignAmount,
    originalPlatformSupportAmount,
    originalTotalAmount,
    originalCurrency: String(currency || 'NPR').toUpperCase(),
    exchangeRate: rate,
    convertedAmountNpr: roundNpr(originalCampaignAmount * rate),
    convertedPlatformSupportAmountNpr: roundNpr(
      originalPlatformSupportAmount * rate,
    ),
    convertedTotalAmountNpr: roundNpr(originalTotalAmount * rate),
  };
};

// @desc    Create a new donation
// @route   POST /api/v1/donations
// @access  Private
export const createDonation = async (req, res) => {
  console.log('Request body:', req.body); // Debug log
  
  const {
    campaign: campaignId,
    amount,
    campaignAmount,
    platformSupportAmount,
    totalAmount,
    supportPlatform,
    paymentMethod,
    paymentId,
    isAnonymous,
    message,
  } = req.body;
  
  console.log('Extracted campaignId:', campaignId); // Debug log
  console.log('User object:', req.user); // Debug log
  
  const userId = req.user._id || req.user.id;

  // Check if campaign exists and is active
  const campaign = await Campaign.findById(campaignId);
  if (!campaign) {
    throw new NotFoundError(`No campaign with id ${campaignId}`);
  }

  if (campaign.status !== 'active') {
    throw new BadRequestError('Cannot donate to an inactive campaign');
  }

  // Check if campaign end date has passed
  if (new Date(campaign.endDate) < new Date()) {
    throw new BadRequestError('This campaign has ended');
  }

  const amounts = resolveDonationAmounts({
    amount,
    campaignAmount,
    platformSupportAmount,
    totalAmount,
    supportPlatform,
  });
  const conversion = buildNprConversionSnapshot({
    campaignAmount: amounts.campaignAmount,
    platformSupportAmount: amounts.platformSupportAmount,
    totalAmount: amounts.totalAmount,
    currency: 'NPR',
  });

  // Create donation
  const donation = await Donation.create({
    donor: userId,
    campaign: campaignId,
    organization: campaign.organization,
    amount: amounts.campaignAmount,
    campaignAmount: amounts.campaignAmount,
    platformSupportAmount: amounts.platformSupportAmount,
    totalAmount: amounts.totalAmount,
    ...conversion,
    supportPlatform: amounts.supportPlatform,
    paymentMethod,
    paymentId:
      paymentId ||
      `payment_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`, // Fallback unique payment ID if not provided
    isAnonymous: isAnonymous || false,
    message: message || '',
  });

  // Update campaign's current amount
  campaign.currentAmount += amounts.campaignAmount;
  campaign.donationsCount += 1;
  await campaign.save();

  await logUserActivity({
    user: userId,
    activityType: 'donation',
    resourceType: 'Donation',
    resourceId: donation._id,
    metadata: {
      amount,
      campaignAmount: amounts.campaignAmount,
      platformSupportAmount: amounts.platformSupportAmount,
      totalAmount: amounts.totalAmount,
      supportPlatform: amounts.supportPlatform,
      campaignId: campaign._id,
      campaignTitle: campaign.title,
      organizationId: campaign.organization,
      paymentMethod,
      isAnonymous: isAnonymous || false,
    },
  });

  // Get organization details for receipt
  const organization = await Organization.findById(campaign.organization);
  const user = await User.findById(userId);

  // Send receipt email
  try {
    await sendDonationReceipt({
      to: user.email,
      userName: user.name,
      amount: amounts.campaignAmount,
      platformSupportAmount: amounts.platformSupportAmount,
      totalAmount: amounts.totalAmount,
      campaignTitle: campaign.title,
      organizationName: organization
        ? organization.organizationName
        : 'Unknown Organization',
      donationId: donation._id,
      date: new Date(),
      isAnonymous,
    });
  } catch (error) {
    console.error('Error sending donation receipt:', error);
    // Don't fail the request if email sending fails
  }

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: donation,
  });
};

// @desc    Get donation summary for current organization
// @route   GET /api/v1/donations/summary/org
// @access  Private (Organization, Admin)
export const getOrgDonationSummary = async (req, res) => {
  const orgId = req.user.organization;

  if (!orgId) {
    throw new BadRequestError('Organization not found on user');
  }

  const [summary] = await Donation.aggregate([
    {
      $match: {
        organization: new mongoose.Types.ObjectId(orgId),
        status: 'completed',
      },
    },
    {
      $group: {
        _id: '$organization',
        totalAmount: { $sum: campaignDonationNprExpression },
        totalAmountNpr: { $sum: campaignDonationNprExpression },
        donationCount: { $sum: 1 },
      },
    },
  ]);

  res.status(StatusCodes.OK).json({
    success: true,
    data:
      summary || {
        _id: orgId,
        totalAmount: 0,
        totalAmountNpr: 0,
        donationCount: 0,
      },
  });
};

// @desc    Get donation summary grouped by organization (admin)
// @route   GET /api/v1/donations/summary/all
// @access  Private (Admin)
export const getDonationsSummaryByOrg = async (req, res) => {
  const summary = await Donation.aggregate([
    {
      $match: {
        status: 'completed',
      },
    },
    {
      $group: {
        _id: '$organization',
        totalAmount: { $sum: campaignDonationNprExpression },
        totalAmountNpr: { $sum: campaignDonationNprExpression },
        donationCount: { $sum: 1 },
      },
    },
  ]);

  res.status(StatusCodes.OK).json({
    success: true,
    data: summary,
  });
};

// @desc    Get donation summary for a specific organization (admin)
// @route   GET /api/v1/donations/summary/org/:orgId
// @access  Private (Admin)
export const getOrgDonationSummaryById = async (req, res) => {
  const { orgId } = req.params;

  if (!orgId) {
    throw new BadRequestError('Organization id is required');
  }

  const [summary] = await Donation.aggregate([
    {
      $match: {
        organization: new mongoose.Types.ObjectId(orgId),
        status: 'completed',
      },
    },
    {
      $group: {
        _id: '$organization',
        totalAmount: { $sum: campaignDonationNprExpression },
        totalAmountNpr: { $sum: campaignDonationNprExpression },
        donationCount: { $sum: 1 },
      },
    },
  ]);

  res.status(StatusCodes.OK).json({
    success: true,
    data:
      summary || {
        _id: orgId,
        totalAmount: 0,
        totalAmountNpr: 0,
        donationCount: 0,
      },
  });
};

// @desc    Get all donations
// @route   GET /api/v1/donations
// @access  Private (Admin)
export const getDonations = async (req, res) => {
  // Copy req.query
  const reqQuery = { ...req.query };

  // Fields to exclude
  const removeFields = ['select', 'sort', 'page', 'limit'];

  // Loop over removeFields and delete them from reqQuery
  removeFields.forEach((param) => delete reqQuery[param]);

  // Create query string
  let queryStr = JSON.stringify(reqQuery);

  // Create operators ($gt, $gte, etc)
  queryStr = queryStr.replace(
    /\b(gt|gte|lt|lte|in)\b/g,
    (match) => `$${match}`,
  );

  // Finding resource
  let query = Donation.find(JSON.parse(queryStr))
    .populate('donor', 'name email')
    .populate('campaign', 'title')
    .populate('organization', 'organizationName');

  // Select Fields
  if (req.query.select) {
    const fields = req.query.select.split(',').join(' ');
    query = query.select(fields);
  }

  // Sort
  if (req.query.sort) {
    const sortBy = req.query.sort.split(',').join(' ');
    query = query.sort(sortBy);
  } else {
    query = query.sort('-createdAt');
  }

  // Pagination
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;
  const startIndex = (page - 1) * limit;
  const endIndex = page * limit;
  const total = await Donation.countDocuments(JSON.parse(queryStr));

  query = query.skip(startIndex).limit(limit);

  // Executing query
  const donations = await query;

  // Pagination result
  const pagination = {};

  if (endIndex < total) {
    pagination.next = {
      page: page + 1,
      limit,
    };
  }

  if (startIndex > 0) {
    pagination.prev = {
      page: page - 1,
      limit,
    };
  }

  res.status(StatusCodes.OK).json({
    success: true,
    count: donations.length,
    pagination,
    data: donations,
  });
};

// @desc    Get single donation
// @route   GET /api/v1/donations/:id
// @access  Private
export const getDonation = async (req, res) => {
  const donation = await Donation.findById(req.params.id)
    .populate('donor', 'name email')
    .populate('campaign', 'title')
    .populate('organization', 'organizationName');

  if (!donation) {
    throw new NotFoundError(`No donation with id ${req.params.id}`);
  }

  const requestUserId = req.user?._id?.toString?.() || req.user?.id?.toString?.();
  const requestOrgId = req.user?.organization?.toString?.();
  const donationOrgId = donation.organization?._id?.toString?.() || donation.organization?.toString?.();
  const donorUserId = donation.donor?._id?.toString?.() || donation.donor?.toString?.();

  // Make sure user is the donor, organization owner, or admin
  if (
    donorUserId !== requestUserId &&
    donationOrgId !== requestOrgId &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError('Not authorized to access this donation');
  }

  res.status(StatusCodes.OK).json({
    success: true,
    data: donation,
  });
};

// @desc    Get donations for a specific campaign
// @route   GET /api/v1/campaigns/:campaignId/donations
// @access  Private
export const getDonationsForCampaign = async (req, res) => {
  // Check if campaign exists and user has access
  const campaign = await Campaign.findById(req.params.campaignId);
  if (!campaign) {
    throw new NotFoundError(`No campaign with id ${req.params.campaignId}`);
  }

  const campaignOrgId = campaign.organization?.toString?.();
  const requestOrgId = req.user?.organization?.toString?.();

  // Check if user is campaign owner or admin
  if (req.user.role !== 'admin' && campaignOrgId !== requestOrgId) {
    throw new UnauthorizedError('Not authorized to view these donations');
  }

  const donations = await Donation.find({ campaign: req.params.campaignId })
    .populate('donor', 'name email')
    .sort('-createdAt');

  res.status(StatusCodes.OK).json({
    success: true,
    count: donations.length,
    data: donations,
  });
};

// @desc    Get donations by a specific user
// @route   GET /api/v1/users/donations
// @route   GET /api/v1/users/:userId/donations
// @access  Private
export const getUserDonations = async (req, res) => {
  let userId = req.params.userId || req.user._id;

  // Check if user is authorized
  if (
    req.params.userId &&
    req.params.userId !== req.user._id.toString() &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError('Not authorized to view these donations');
  }

  const donations = await Donation.find({ donor: userId })
    .populate('campaign', 'title image')
    .populate('organization', 'organizationName')
    .sort('-createdAt');

  res.status(StatusCodes.OK).json({
    success: true,
    count: donations.length,
    data: donations,
  });
};

// @desc    Update donation status
// @route   PUT /api/v1/donations/:id/status
// @access  Private (Admin or Organization)
export const updateDonationStatus = async (req, res) => {
  const { status } = req.body;

  if (!status) {
    throw new BadRequestError('Please provide a status');
  }

  const donation = await Donation.findById(req.params.id);

  if (!donation) {
    throw new NotFoundError(`No donation with id ${req.params.id}`);
  }

  const donationOrgId = donation.organization?.toString?.();
  const requestOrgId = req.user?.organization?.toString?.();

  // Check if user is authorized (admin or organization owner)
  if (req.user.role !== 'admin' && donationOrgId !== requestOrgId) {
    throw new UnauthorizedError('Not authorized to update this donation');
  }

  // Update status
  donation.status = status;
  await donation.save();

  // Send status update email to donor if not anonymous
  if (!donation.isAnonymous) {
    const user = await User.findById(donation.donor);
    if (user) {
      try {
        await sendDonationStatusUpdate({
          to: user.email,
          userName: user.name,
          donationId: donation._id,
          amount: donation.amount,
          status,
          campaignTitle: donation.campaign.title,
        });
      } catch (error) {
        console.error('Error sending status update email:', error);
      }
    }
  }

  res.status(StatusCodes.OK).json({
    success: true,
    data: donation,
  });
};

// Helper function to send donation receipt email
const sendDonationReceipt = async ({
  to,
  userName,
  amount,
  platformSupportAmount = 0,
  totalAmount,
  campaignTitle,
  organizationName,
  donationId,
  date,
  isAnonymous,
}) => {
  const payableAmount = totalAmount ?? amount + platformSupportAmount;
  const subject = 'Thank you for your donation';
  const text = `
    Dear ${userName},
    
    Thank you for your generous donation of NPR ${amount.toFixed(2)} to "${campaignTitle}" by ${organizationName}.
    
    Donation ID: ${donationId}
    Date: ${date.toLocaleDateString()}
    Campaign Amount: NPR ${amount.toFixed(2)}
    Platform Support: NPR ${platformSupportAmount.toFixed(2)}
    Total Paid: NPR ${payableAmount.toFixed(2)}
    ${isAnonymous ? 'This donation was made anonymously.' : ''}
    
    Your support is greatly appreciated!
    
    Best regards,
    ${organizationName} Team
  `;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Donation Receipt</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          line-height: 1.6; 
          color: #333; 
          margin: 0;
          padding: 0;
        }
        .container { 
          max-width: 600px; 
          margin: 0 auto; 
          padding: 20px; 
          background-color: #f9f9f9;
        }
        .header { 
          background-color: #4CAF50; 
          padding: 20px; 
          color: white; 
          text-align: center; 
          border-radius: 5px 5px 0 0;
        }
        .header h2 {
          margin: 0;
        }
        .content { 
          padding: 25px; 
          background-color: #ffffff;
          border-radius: 0 0 5px 5px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .details-box {
          background-color: #f9f9f9;
          padding: 15px;
          border-radius: 5px;
          margin: 20px 0;
          border-left: 4px solid #4CAF50;
        }
        .footer {
          margin-top: 20px;
          padding-top: 20px;
          border-top: 1px solid #eee;
          color: #777;
          font-size: 14px;
        }
        a {
          color: #4CAF50;
          text-decoration: none;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>Thank You for Your Donation!</h2>
        </div>
        
        <div class="content">
          <p>Dear ${userName},</p>
          <p>Thank you for your generous donation of <strong>NPR ${amount.toFixed(2)}</strong> to "<strong>${campaignTitle}</strong>" by <strong>${organizationName}</strong>.</p>
          
          <div class="details-box">
            <p><strong>Donation Details:</strong></p>
            <p>Donation ID: ${donationId}</p>
            <p>Date: ${date.toLocaleDateString()}</p>
            <p>Campaign Amount: NPR ${amount.toFixed(2)}</p>
            <p>Platform Support: NPR ${platformSupportAmount.toFixed(2)}</p>
            <p>Total Paid: NPR ${payableAmount.toFixed(2)}</p>
            ${isAnonymous ? '<p>This donation was made anonymously.</p>' : ''}
          </div>
          
          <p>Your support is greatly appreciated and will help us make a difference.</p>
          
          <div class="footer">
            <p>Best regards,<br><strong>${organizationName} Team</strong></p>
            <p>If you have any questions, please contact us at <a href="mailto:support@hopelink.org">support@hopelink.org</a>.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  await sendEmail({
    to,
    subject,
    text,
    html,
  });
};

// Helper function to send donation status update email
const sendDonationStatusUpdate = async ({
  to,
  userName,
  donationId,
  amount,
  status,
  campaignTitle,
}) => {
  const statusMessages = {
    completed: 'has been successfully processed',
    failed: 'could not be processed',
    refunded: 'has been refunded',
    cancelled: 'has been cancelled',
  };

  const statusMessage =
    statusMessages[status] || `has been updated to ${status}`;

  const subject = `Your Donation ${statusMessage.split(' ')[0]} ${statusMessage.split(' ')[1] === 'has' ? statusMessage : ''}`;

  const text = `
    Dear ${userName},
    
    We would like to inform you that your donation for "${campaignTitle}" ${statusMessage}.
    
    Donation ID: ${donationId}
    Amount: $${amount.toFixed(2)}
    Status: ${status.charAt(0).toUpperCase() + status.slice(1)}
    
    If you have any questions, please don't hesitate to contact us.
    
    Best regards,
    The Team
  `;

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Donation Update</title>
      <style>
        body { 
          font-family: Arial, sans-serif; 
          line-height: 1.6; 
          color: #333; 
          margin: 0;
          padding: 0;
        }
        .container { 
          max-width: 600px; 
          margin: 0 auto; 
          padding: 20px; 
          background-color: #f9f9f9;
        }
        .header { 
          background-color: #4CAF50; 
          padding: 20px; 
          color: white; 
          text-align: center; 
          border-radius: 5px 5px 0 0;
        }
        .header h2 {
          margin: 0;
        }
        .content { 
          padding: 25px; 
          background-color: #ffffff;
          border-radius: 0 0 5px 5px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .details-box {
          background-color: #f9f9f9;
          padding: 15px;
          border-radius: 5px;
          margin: 20px 0;
          border-left: 4px solid #4CAF50;
        }
        .footer {
          margin-top: 20px;
          padding-top: 20px;
          border-top: 1px solid #eee;
          color: #777;
          font-size: 14px;
        }
        a {
          color: #4CAF50;
          text-decoration: none;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>Donation Update</h2>
        </div>
        
        <div class="content">
          <p>Dear ${userName},</p>
          <p>We would like to inform you that your donation for <strong>"${campaignTitle}"</strong> ${statusMessage}.</p>
          
          <div class="details-box">
            <p><strong>Donation Details:</strong></p>
            <p>Donation ID: ${donationId}</p>
            <p>Amount: $${amount.toFixed(2)}</p>
            <p>Status: <span style="color: ${
              status === 'completed'
                ? '#28a745'
                : status === 'failed'
                  ? '#dc3545'
                  : status === 'refunded'
                    ? '#ffc107'
                    : status === 'cancelled'
                      ? '#6c757d'
                      : '#007bff'
            };">${status.charAt(0).toUpperCase() + status.slice(1)}</span></p>
          </div>
          
          <div class="footer">
            <p>If you have any questions, please contact us at <a href="mailto:support@hopelink.org">support@hopelink.org</a>.</p>
            <p>Best regards,<br><strong>The HopeLink Team</strong></p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  await sendEmail({
    to,
    subject,
    text,
    html,
  });
};

const validateCampaignForDonation = async (campaignId) => {
  const campaign = await Campaign.findById(campaignId);
  if (!campaign) {
    return {
      error: {
        status: StatusCodes.NOT_FOUND,
        body: {
          success: false,
          message: `No campaign with id ${campaignId}`,
        },
      },
    };
  }

  if (campaign.status !== 'active') {
    return {
      error: {
        status: StatusCodes.BAD_REQUEST,
        body: {
          success: false,
          message: 'Cannot donate to an inactive campaign',
        },
      },
    };
  }

  if (new Date(campaign.endDate) < new Date()) {
    return {
      error: {
        status: StatusCodes.BAD_REQUEST,
        body: {
          success: false,
          message: 'This campaign has ended',
        },
      },
    };
  }

  return { campaign };
};

const finalizeDonation = async ({
  userId,
  campaign,
  amount,
  campaignAmount,
  platformSupportAmount,
  totalAmount,
  supportPlatform,
  paymentMethod,
  paymentId,
  isAnonymous,
  message,
  paymentMeta = {},
  conversion = null,
}) => {
  const amounts = resolveDonationAmounts({
    amount,
    campaignAmount,
    platformSupportAmount,
    totalAmount,
    supportPlatform,
    amountIncludesSupport: true,
  });
  const conversionSnapshot =
    conversion ||
    buildNprConversionSnapshot({
      campaignAmount: amounts.campaignAmount,
      platformSupportAmount: amounts.platformSupportAmount,
      totalAmount: amounts.totalAmount,
      currency: 'NPR',
    });
  const nprAmounts = {
    campaignAmount: conversionSnapshot.convertedAmountNpr,
    platformSupportAmount:
      conversionSnapshot.convertedPlatformSupportAmountNpr || 0,
    totalAmount: conversionSnapshot.convertedTotalAmountNpr,
    supportPlatform:
      (conversionSnapshot.convertedPlatformSupportAmountNpr || 0) > 0,
  };

  let donation = await Donation.findOne({ paymentMethod, paymentId });
  let isNewDonation = !donation;

  if (!donation) {
    try {
      donation = await Donation.create({
        donor: userId,
        campaign: campaign._id,
        organization: campaign.organization,
        amount: nprAmounts.campaignAmount,
        campaignAmount: nprAmounts.campaignAmount,
        platformSupportAmount: nprAmounts.platformSupportAmount,
        totalAmount: nprAmounts.totalAmount,
        ...conversionSnapshot,
        supportPlatform: nprAmounts.supportPlatform,
        paymentMethod,
        paymentId,
        isAnonymous: isAnonymous || false,
        message: message || '',
        status: 'completed',
      });
    } catch (error) {
      if (error?.code !== 11000) {
        throw error;
      }

      donation = await Donation.findOne({ paymentMethod, paymentId });
      isNewDonation = false;
      if (!donation) {
        throw error;
      }
    }
  }

  if (isNewDonation) {
    campaign.currentAmount =
      (campaign.currentAmount || 0) + nprAmounts.campaignAmount;
    campaign.donationsCount = (campaign.donationsCount || 0) + 1;
    await campaign.save();

    await logUserActivity({
      user: userId,
      activityType: 'donation',
      resourceType: 'Donation',
      resourceId: donation._id,
      metadata: {
        amount: nprAmounts.campaignAmount,
        campaignAmount: nprAmounts.campaignAmount,
        platformSupportAmount: nprAmounts.platformSupportAmount,
        totalAmount: nprAmounts.totalAmount,
        supportPlatform: nprAmounts.supportPlatform,
        originalAmount: conversionSnapshot.originalAmount,
        originalCurrency: conversionSnapshot.originalCurrency,
        exchangeRate: conversionSnapshot.exchangeRate,
        convertedAmountNpr: conversionSnapshot.convertedAmountNpr,
        campaignId: campaign._id,
        campaignTitle: campaign.title,
        organizationId: campaign.organization,
        paymentMethod,
        isAnonymous: isAnonymous || false,
        ...paymentMeta,
      },
    });
  }

  let organization = null;
  try {
    if (isNewDonation) {
      organization = await Organization.findByIdAndUpdate(
        campaign.organization,
        {
          $inc: {
            totalDonationsReceived: nprAmounts.campaignAmount,
            totalDonationCount: 1,
          },
        },
        { new: true },
      );
    } else {
      organization = await Organization.findById(campaign.organization);
    }
  } catch (err) {
    console.error('[Backend] Error updating organization funds:', err);
  }

  if (nprAmounts.supportPlatform) {
    try {
      await PlatformSupportTransaction.findOneAndUpdate(
        { donation: donation._id },
        {
          donation: donation._id,
          donor: userId,
          campaign: campaign._id,
          organization: campaign.organization,
          amount: nprAmounts.platformSupportAmount,
          paymentMethod,
          paymentId,
          status: 'completed',
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
    } catch (err) {
      console.error('[Backend] Error recording platform support:', err);
    }
  }

  let user = null;
  try {
    user = await User.findById(userId);
  } catch (err) {
    console.error('[Backend] Error fetching user for donation receipt:', err);
  }

  if (isNewDonation && !donation.receiptSent && user?.email) {
    try {
      await sendDonationReceipt({
        to: user.email,
        userName: user?.name || 'Donor',
        amount: nprAmounts.campaignAmount,
        platformSupportAmount: nprAmounts.platformSupportAmount,
        totalAmount: nprAmounts.totalAmount,
        campaignTitle: campaign.title,
        organizationName: organization
          ? organization.organizationName
          : 'Unknown Organization',
        donationId: donation._id,
        date: new Date(donation.createdAt || Date.now()),
        isAnonymous,
      });
      donation.receiptSent = true;
      await donation.save();
    } catch (error) {
      console.error('Error sending donation receipt:', error);
    }
  }

  return {
    donation,
    campaignUpdated: {
      currentAmount: campaign.currentAmount,
      donationsCount: campaign.donationsCount,
      progress: (campaign.currentAmount / campaign.targetAmount) * 100,
    },
    organizationUpdated: organization
      ? {
          totalDonationsReceived: organization.totalDonationsReceived,
          totalDonationCount: organization.totalDonationCount,
        }
      : {
          totalDonationsReceived: null,
          totalDonationCount: null,
        },
    wasAlreadyRecorded: !isNewDonation,
  };
};

const lookupCompletedKhaltiPayment = async (
  pidx,
  { attempts = 8, delayMs = 1500 } = {},
) => {
  let lastResult = null;

  for (let attempt = 0; attempt < attempts; attempt += 1) {
    lastResult = await lookupKhaltiEpayment({ pidx });
    console.log(
      `[Backend][Khalti Lookup] attempt=${attempt + 1}/${attempts} pidx=${pidx} status=${
        lastResult?.status || lastResult?.state?.name || lastResult?.state?.code
      }`,
    );
    if (isKhaltiEpaymentCompleted(lastResult)) {
      return lastResult;
    }

    if (attempt < attempts - 1) {
      await wait(delayMs);
    }
  }

  return lastResult;
};
// @desc    Complete a Stripe payment and create donation record
// @route   POST /api/v1/donations/complete-payment
// @access  Private
// Called by Flutter app after Stripe payment succeeds
export const completeStripePayment = async (req, res, next) => {
  try {
    // Debug logs to help trace incoming requests from the Flutter app
    console.log('[Backend][completeStripePayment] headers:', req.headers);
    console.log('[Backend][completeStripePayment] body:', req.body);

    const {
      paymentIntentId,
      amount,
      campaignAmount,
      platformSupportAmount,
      totalAmount,
      supportPlatform,
      campaignId,
      isAnonymous,
      message,
    } = req.body;

    const userId = req.user._id || req.user.id;

    // Validate required fields
    if (!paymentIntentId || !amount || !campaignId) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'paymentIntentId, amount, and campaignId are required',
      });
    }

    const { campaign, error: campaignError } =
      await validateCampaignForDonation(campaignId);
    if (campaignError) {
      return res.status(campaignError.status).json(campaignError.body);
    }

    const intent = await retrieveStripePaymentIntent(paymentIntentId);
    if (!isStripePaymentSuccessful(intent)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Stripe payment is not completed',
        data: {
          id: intent.id,
          status: intent.status,
        },
      });
    }

    const originalCurrency = String(intent.currency || 'NPR').toUpperCase();
    const originalTotalAmount = stripeAmountToMajorUnit({
      amount: intent.amount,
      currency: intent.currency,
    });
    const originalPlatformSupportAmount = toAmount(
      platformSupportAmount ?? intent.metadata?.platformSupportAmount,
      0,
    );
    const originalCampaignAmount = toAmount(
      campaignAmount ?? intent.metadata?.campaignAmount,
      Math.max(originalTotalAmount - originalPlatformSupportAmount, 0),
    );
    const conversionRate = await convertToNPR(1, originalCurrency);
    const conversion = buildNprConversionSnapshot({
      campaignAmount: originalCampaignAmount,
      platformSupportAmount: originalPlatformSupportAmount,
      totalAmount: originalTotalAmount,
      currency: originalCurrency,
      exchangeRate: conversionRate.exchangeRate,
    });
    const resolvedSupportPlatform =
      supportPlatform == null
        ? originalPlatformSupportAmount > 0
        : supportPlatform === true || String(supportPlatform) === 'true';

    const finalized = await finalizeDonation({
      userId,
      campaign,
      amount: originalTotalAmount,
      campaignAmount: originalCampaignAmount,
      platformSupportAmount: originalPlatformSupportAmount,
      totalAmount: originalTotalAmount,
      supportPlatform: resolvedSupportPlatform,
      paymentMethod: 'stripe',
      paymentId: paymentIntentId,
      isAnonymous,
      message,
      conversion,
      paymentMeta: {
        stripePaymentIntentId: intent.id,
        stripeAmount: intent.amount,
        stripeCurrency: originalCurrency,
        originalAmount: originalCampaignAmount,
        originalCurrency,
        exchangeRate: conversion.exchangeRate,
        convertedAmountNpr: conversion.convertedAmountNpr,
      },
    });

    return res.status(StatusCodes.CREATED).json({
      success: true,
      message: finalized.wasAlreadyRecorded
        ? 'Donation was already completed'
        : 'Donation completed successfully',
      data: {
        donation: finalized.donation,
        campaignUpdated: finalized.campaignUpdated,
        organizationUpdated: finalized.organizationUpdated,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Complete a Khalti payment and create donation record
// @route   POST /api/v1/donations/complete-khalti-payment
// @access  Private
export const completeKhaltiPayment = async (req, res, next) => {
  try {
    console.log('[Backend][completeKhaltiPayment] headers:', req.headers);
    console.log('[Backend][completeKhaltiPayment] body:', req.body);

    const {
      pidx,
      amount,
      amountInPaisa,
      campaignAmount,
      platformSupportAmount,
      totalAmount,
      supportPlatform,
      campaignId,
      isAnonymous,
      message,
    } = req.body;

    if (!pidx || !campaignId || (amount == null && amountInPaisa == null)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'pidx, amount (in paisa), and campaignId are required',
      });
    }

    const { amountInPaisa: normalizedPaisa, amountInRupees } =
      normalizeKhaltiAmount({ amount, amountInPaisa });

    const result = await lookupCompletedKhaltiPayment(pidx);
    console.log('[Backend][completeKhaltiPayment] lookup result:', result);

    if (!isKhaltiEpaymentCompleted(result)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Khalti payment is not completed',
        data: result,
      });
    }

    const paidAmount = result?.total_amount ?? result?.amount;
    if (paidAmount != null && Number(paidAmount) !== Number(normalizedPaisa)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Khalti payment amount mismatch',
        data: result,
      });
    }

    const { campaign, error: campaignError } =
      await validateCampaignForDonation(campaignId);
    if (campaignError) {
      return res.status(campaignError.status).json(campaignError.body);
    }

    const userId = req.user._id || req.user.id;
    const paymentId = getKhaltiPaymentId(result, pidx);
    console.log(
      `[Backend][completeKhaltiPayment] finalizing donation pidx=${pidx} paymentId=${paymentId} userId=${userId} campaignId=${campaignId} amount=${amountInRupees}`,
    );

    const finalized = await finalizeDonation({
      userId,
      campaign,
      amount: amountInRupees,
      campaignAmount,
      platformSupportAmount,
      totalAmount,
      supportPlatform,
      paymentMethod: 'khalti',
      paymentId,
      isAnonymous,
      message,
      paymentMeta: {
        amountInPaisa: normalizedPaisa,
        campaignAmount,
        platformSupportAmount,
        totalAmount: totalAmount ?? amountInRupees,
        supportPlatform,
        khaltiPidx: pidx,
      },
    });

    console.log('[Backend][completeKhaltiPayment] finalized donation:', {
      donationId: finalized.donation?._id,
      wasAlreadyRecorded: finalized.wasAlreadyRecorded,
      campaignUpdated: finalized.campaignUpdated,
      organizationUpdated: finalized.organizationUpdated,
    });

    return res.status(StatusCodes.CREATED).json({
      success: true,
      message: finalized.wasAlreadyRecorded
        ? 'Donation was already completed'
        : 'Donation completed successfully',
      data: {
        donation: finalized.donation,
        campaignUpdated: finalized.campaignUpdated,
        organizationUpdated: finalized.organizationUpdated,
        khalti: {
          paymentId,
          amountInPaisa: normalizedPaisa,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

const buildAdminDonationFilter = (query) => {
  const filter = {};
  const {
    status,
    paymentMethod,
    campaign,
    campaignId,
    donor,
    userId,
    organization,
    organizationId,
    supportPlatform,
    from,
    to,
  } = query;

  if (status) filter.status = status;
  if (paymentMethod) filter.paymentMethod = paymentMethod;
  if (campaign || campaignId) filter.campaign = campaign || campaignId;
  if (donor || userId) filter.donor = donor || userId;
  if (organization || organizationId) {
    filter.organization = organization || organizationId;
  }
  if (supportPlatform != null) {
    filter.supportPlatform = String(supportPlatform) === 'true';
  }
  if (from || to) {
    filter.createdAt = {};
    if (from) filter.createdAt.$gte = new Date(from);
    if (to) filter.createdAt.$lte = new Date(to);
  }

  return filter;
};

const getPaginatedDonations = async (req, extraFilter = {}) => {
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
  const skip = (page - 1) * limit;
  const sort = req.query.sort
    ? req.query.sort.split(',').join(' ')
    : '-createdAt';
  const filter = {
    ...buildAdminDonationFilter(req.query),
    ...extraFilter,
  };

  const [donations, total] = await Promise.all([
    Donation.find(filter)
      .populate('donor', 'name email')
      .populate('campaign', 'title')
      .populate('organization', 'organizationName')
      .sort(sort)
      .skip(skip)
      .limit(limit),
    Donation.countDocuments(filter),
  ]);

  return {
    donations,
    total,
    page,
    pages: Math.ceil(total / limit) || 1,
    limit,
  };
};

// @desc    Admin: retrieve all donation records
// @route   GET /api/v1/admin/donations
// @access  Private (Admin)
export const getAdminDonations = async (req, res) => {
  const result = await getPaginatedDonations(req);

  res.status(StatusCodes.OK).json({
    success: true,
    count: result.donations.length,
    total: result.total,
    page: result.page,
    pages: result.pages,
    data: result.donations,
  });
};

// @desc    Admin: retrieve one donation record
// @route   GET /api/v1/admin/donations/:id
// @access  Private (Admin)
export const getAdminDonationById = async (req, res) => {
  const donation = await Donation.findById(req.params.id)
    .populate('donor', 'name email phone')
    .populate('campaign', 'title targetAmount currentAmount')
    .populate('organization', 'organizationName email phone');

  if (!donation) {
    throw new NotFoundError(`No donation with id ${req.params.id}`);
  }

  const platformSupportTransaction =
    await PlatformSupportTransaction.findOne({ donation: donation._id });

  res.status(StatusCodes.OK).json({
    success: true,
    data: {
      donation,
      platformSupportTransaction,
    },
  });
};

// @desc    Admin: retrieve donations with platform support
// @route   GET /api/v1/admin/platform-support-donations
// @access  Private (Admin)
export const getAdminPlatformSupportDonations = async (req, res) => {
  const result = await getPaginatedDonations(req, {
    supportPlatform: true,
    platformSupportAmount: { $gt: 0 },
  });

  res.status(StatusCodes.OK).json({
    success: true,
    count: result.donations.length,
    total: result.total,
    page: result.page,
    pages: result.pages,
    data: result.donations,
  });
};

// @desc    Admin: retrieve donation history for a specific user
// @route   GET /api/v1/admin/users/:userId/donations
// @access  Private (Admin)
export const getAdminUserDonations = async (req, res) => {
  const result = await getPaginatedDonations(req, {
    donor: req.params.userId,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    count: result.donations.length,
    total: result.total,
    page: result.page,
    pages: result.pages,
    data: result.donations,
  });
};

export const getPlatformFeeSummary = async (req, res) => {
  const [summary] = await PlatformSupportTransaction.aggregate([
    { $match: { status: 'completed' } },
    {
      $group: {
        _id: null,
        totalPlatformFeesCollected: { $sum: '$amount' },
        totalSupportContributions: { $sum: 1 },
        averageSupportContributionAmount: { $avg: '$amount' },
        highestSupportContribution: { $max: '$amount' },
      },
    },
  ]);

  res.status(StatusCodes.OK).json({
    success: true,
    data: summary || {
      totalPlatformFeesCollected: 0,
      totalSupportContributions: 0,
      averageSupportContributionAmount: 0,
      highestSupportContribution: 0,
    },
  });
};

export const getMonthlyPlatformFees = async (req, res) => {
  const data = await PlatformSupportTransaction.aggregate([
    { $match: { status: 'completed' } },
    {
      $group: {
        _id: {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
        },
        totalPlatformFees: { $sum: '$amount' },
        contributions: { $sum: 1 },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } },
  ]);

  res.status(StatusCodes.OK).json({ success: true, data });
};

export const getYearlyPlatformFees = async (req, res) => {
  const data = await PlatformSupportTransaction.aggregate([
    { $match: { status: 'completed' } },
    {
      $group: {
        _id: { year: { $year: '$createdAt' } },
        totalPlatformFees: { $sum: '$amount' },
        contributions: { $sum: 1 },
      },
    },
    { $sort: { '_id.year': 1 } },
  ]);

  res.status(StatusCodes.OK).json({ success: true, data });
};

export const getPlatformFeesByCampaign = async (req, res) => {
  const data = await PlatformSupportTransaction.aggregate([
    { $match: { status: 'completed' } },
    {
      $group: {
        _id: '$campaign',
        totalPlatformFees: { $sum: '$amount' },
        contributions: { $sum: 1 },
        donors: { $addToSet: '$donor' },
      },
    },
    {
      $lookup: {
        from: 'campaigns',
        localField: '_id',
        foreignField: '_id',
        as: 'campaign',
      },
    },
    { $unwind: { path: '$campaign', preserveNullAndEmptyArrays: true } },
    {
      $project: {
        campaignId: '$_id',
        campaignTitle: '$campaign.title',
        totalPlatformFees: 1,
        contributions: 1,
        uniqueDonors: { $size: '$donors' },
      },
    },
    { $sort: { totalPlatformFees: -1 } },
  ]);

  res.status(StatusCodes.OK).json({ success: true, data });
};

export const getAdminDonationDashboardStats = async (req, res) => {
  const [
    donationTotals,
    supportSummary,
    monthlyPlatformFees,
    recentDonations,
    recentPlatformSupportContributions,
  ] = await Promise.all([
    Donation.aggregate([
      { $match: { status: 'completed' } },
      {
        $group: {
          _id: null,
          totalCampaignDonations: { $sum: campaignDonationNprExpression },
          totalCampaignDonationsNpr: { $sum: campaignDonationNprExpression },
          totalAmountProcessed: { $sum: totalDonationNprExpression },
          totalAmountProcessedNpr: { $sum: totalDonationNprExpression },
          donors: { $addToSet: '$donor' },
          donationsProcessed: { $sum: 1 },
        },
      },
    ]),
    PlatformSupportTransaction.aggregate([
      { $match: { status: 'completed' } },
      {
        $group: {
          _id: null,
          totalPlatformFeesGenerated: { $sum: '$amount' },
          supportContributors: { $addToSet: '$donor' },
          supportContributionCount: { $sum: 1 },
        },
      },
    ]),
    PlatformSupportTransaction.aggregate([
      { $match: { status: 'completed' } },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
          },
          totalPlatformFees: { $sum: '$amount' },
          contributions: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]),
    Donation.find({ status: 'completed' })
      .populate('donor', 'name email')
      .populate('campaign', 'title')
      .sort('-createdAt')
      .limit(10),
    PlatformSupportTransaction.find({ status: 'completed' })
      .populate('donor', 'name email')
      .populate('campaign', 'title')
      .sort('-createdAt')
      .limit(10),
  ]);

  const totals = donationTotals[0] || {};
  const support = supportSummary[0] || {};

  res.status(StatusCodes.OK).json({
    success: true,
    data: {
      totalPlatformFeesGenerated: support.totalPlatformFeesGenerated || 0,
      totalCampaignDonations: totals.totalCampaignDonations || 0,
      totalCampaignDonationsNpr: totals.totalCampaignDonationsNpr || 0,
      totalAmountProcessed: totals.totalAmountProcessed || 0,
      totalAmountProcessedNpr: totals.totalAmountProcessedNpr || 0,
      numberOfDonors: totals.donors?.length || 0,
      numberOfSupportContributors: support.supportContributors?.length || 0,
      supportContributionCount: support.supportContributionCount || 0,
      donationsProcessed: totals.donationsProcessed || 0,
      monthlyPlatformFeeRevenue: monthlyPlatformFees,
      recentDonations,
      recentPlatformSupportContributions,
    },
  });
};
