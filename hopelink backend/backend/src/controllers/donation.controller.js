import { StatusCodes } from 'http-status-codes';
import Donation from '../models/donation.model.js';
import Campaign from '../models/campaign.model.js';
import User from '../models/user.model.js';
import Organization from '../models/organization.model.js';
import {
  BadRequestError,
  NotFoundError,
  UnauthorizedError,
} from '../errors/index.js';
import { sendEmail } from '../services/email.service.js';
import mongoose from 'mongoose';

// @desc    Create a new donation
// @route   POST /api/v1/donations
// @access  Private
export const createDonation = async (req, res) => {
  console.log('Request body:', req.body); // Debug log
  
  const {
    campaign: campaignId,
    amount,
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

  // Create donation
  const donation = await Donation.create({
    donor: userId,
    campaign: campaignId,
    organization: campaign.organization,
    amount,
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
  campaign.currentAmount += amount;
  campaign.donationsCount += 1;
  await campaign.save();

  // Get organization details for receipt
  const organization = await Organization.findById(campaign.organization);
  const user = await User.findById(userId);

  // Send receipt email
  try {
    await sendDonationReceipt({
      to: user.email,
      userName: user.name,
      amount,
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
        totalAmount: { $sum: '$amount' },
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
        totalAmount: { $sum: '$amount' },
        donationCount: { $sum: 1 },
      },
    },
  ]);

  res.status(StatusCodes.OK).json({
    success: true,
    data: summary,
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

  // Make sure user is the donor, organization owner, or admin
  if (
    donation.donor._id.toString() !== req.user._id.toString() &&
    donation.organization._id.toString() !== req.user.organization &&
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

  // Check if user is campaign owner or admin
  if (
    campaign.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
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

  // Check if user is authorized (admin or organization owner)
  if (
    donation.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
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
  campaignTitle,
  organizationName,
  donationId,
  date,
  isAnonymous,
}) => {
  const subject = 'Thank you for your donation';
  const text = `
    Dear ${userName},
    
    Thank you for your generous donation of $${amount.toFixed(2)} to "${campaignTitle}" by ${organizationName}.
    
    Donation ID: ${donationId}
    Date: ${date.toLocaleDateString()}
    Amount: $${amount.toFixed(2)}
    ${isAnonymous ? 'This donation was made anonymously.' : ''}
    
    Your support is greatly appreciated!
    
    Best regards,
    ${organizationName} Team
  `;

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2>Thank you for your donation!</h2>
      <p>Dear ${userName},</p>
      <p>Thank you for your generous donation of <strong>$${amount.toFixed(2)}</strong> to "${campaignTitle}" by ${organizationName}.</p>
      
      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p><strong>Donation Details:</strong></p>
        <p>Donation ID: ${donationId}</p>
        <p>Date: ${date.toLocaleDateString()}</p>
        <p>Amount: $${amount.toFixed(2)}</p>
        ${isAnonymous ? '<p>This donation was made anonymously.</p>' : ''}
      </div>
      
      <p>Your support is greatly appreciated and will help us make a difference.</p>
      
      <p>Best regards,<br>${organizationName} Team</p>
    </div>
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
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2>Donation Update</h2>
      <p>Dear ${userName},</p>
      <p>We would like to inform you that your donation for <strong>"${campaignTitle}"</strong> ${statusMessage}.</p>
      
      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
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
      
      <p>If you have any questions, please don't hesitate to contact us.</p>
      
      <p>Best regards,<br>The Team</p>
    </div>
  `;

  await sendEmail({
    to,
    subject,
    text,
    html,
  });
};
