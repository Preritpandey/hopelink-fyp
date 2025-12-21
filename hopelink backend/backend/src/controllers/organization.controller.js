import mongoose from 'mongoose';
import { StatusCodes } from 'http-status-codes';
// import Organization from '../models/organization.model.js';
// import User from '../models/user.model.js';

import Organization from '../models/organization.model.js';
import User from '../models/user.model.js';

import {
  BadRequestError,
  NotFoundError,
  UnauthorizedError,
} from '../errors/index.js';
import {
  uploadToCloudinary,
  deleteFromCloudinary,
  deleteMultipleFromCloudinary
} from '../config/cloudinary.config.js';
import { sendEmail } from '../services/email.service.js';

// ================================
// Helper: Upload file to Cloudinary
// ================================
const handleFileUpload = async (file, folder = 'organization-documents') => {
  if (!file) return null;

  try {
    console.log(`Uploading file: ${file.originalname} (${file.size} bytes)`);
    
    const result = await uploadToCloudinary(file.path, folder);
    
    const fileData = {
      url: result.secure_url,
      publicId: result.public_id,
      originalName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
      uploadedAt: new Date(),
    };
    
    console.log(`Successfully uploaded: ${file.originalname} (${result.bytes} bytes)`);
    return fileData;
  } catch (error) {
    console.error(`Error uploading file ${file.originalname}:`, error.message);
    throw new Error(`Failed to upload ${file.originalname}: ${error.message}`);
  }
};

// ================================
// @desc Register new organization
// @route POST /api/v1/organizations/register
// @access Public
// ================================
export const registerOrganization = async (req, res) => {
  console.log('Starting organization registration...');
  console.log('Request body keys:', Object.keys(req.body));
  console.log('Request files:', req.files ? Object.keys(req.files) : 'No files');
  
  // Check for existing organizations with same email or registration number
  const existingOrgs = await Organization.find({
    $or: [
      { officialEmail: req.body.officialEmail },
      { registrationNumber: req.body.registrationNumber }
    ]
  });

  console.log('Found existing orgs:', existingOrgs.length);

  // Check for duplicate email
  const existingEmail = existingOrgs.find(org => 
    org.officialEmail === req.body.officialEmail
  );
  
  if (existingEmail) {
    const statusMessage = existingEmail.status === 'pending' 
      ? 'A registration with this email is already pending review.' 
      : existingEmail.status === 'rejected'
        ? 'A registration with this email was previously rejected.'
        : 'An organization with this email is already registered.';
    
    throw new BadRequestError(`Email already in use. ${statusMessage}`);
  }

  // Check for duplicate registration number
  const existingRegNum = existingOrgs.find(org => 
    org.registrationNumber === req.body.registrationNumber
  );
  
  if (existingRegNum) {
    const statusMessage = existingRegNum.status === 'pending'
      ? 'A registration with this number is pending review.'
      : existingRegNum.status === 'rejected'
        ? 'A registration with this number was previously rejected.'
        : 'This registration number is already in use.';
    
    throw new BadRequestError(`Registration number already in use. ${statusMessage}`);
  }

  // Validate required fields
  const requiredFields = [
    'organizationName',
    'organizationType',
    'registrationNumber',
    'dateOfRegistration',
    'officialEmail',
    'officialPhone',
    'country',
    'city',
    'registeredAddress',
    'representativeName',
    'designation',
    'primaryCause',
    'missionStatement',
    'activeMembers',
    'bankName',
    'accountHolderName',
    'accountNumber',
    'bankBranch',
  ];
  const missingFields = requiredFields.filter((f) => !req.body[f]);
  if (missingFields.length)
    throw new BadRequestError(
      `Missing required fields: ${missingFields.join(', ')}`
    );

  // Validate required files
  const requiredFiles = [
    'registrationCertificate',
    'taxCertificate',
    'constitutionFile',
    'proofOfAddress',
    'voidCheque',
  ];
  const missingFiles = requiredFiles.filter((f) => !req.files?.[f]?.[0]);
  if (missingFiles.length)
    throw new BadRequestError(
      `Missing required files: ${missingFiles.join(', ')}`
    );

  // Validate email format
  if (!/^\S+@\S+\.\S+$/.test(req.body.officialEmail)) {
    throw new BadRequestError('Please provide a valid email address');
  }

  // Validate numeric members
  const activeMembers = parseInt(req.body.activeMembers, 10);
  if (isNaN(activeMembers) || activeMembers < 1)
    throw new BadRequestError('Active members must be at least 1');

  if (req.body.missionStatement?.length > 1000)
    throw new BadRequestError('Mission statement cannot exceed 1000 characters');

  // Upload all files
  let logo = null;
  let registrationCertificate = null;
  let taxCertificate = null;
  let constitutionFile = null;
  let proofOfAddress = null;
  let voidCheque = null;

  // Upload files sequentially to avoid overwhelming the server
  logo = await handleFileUpload(req.files?.logo?.[0], 'organization-logos');
  registrationCertificate = await handleFileUpload(req.files?.registrationCertificate?.[0]);
  taxCertificate = await handleFileUpload(req.files?.taxCertificate?.[0]);
  constitutionFile = await handleFileUpload(req.files?.constitutionFile?.[0]);
  proofOfAddress = await handleFileUpload(req.files?.proofOfAddress?.[0]);
  voidCheque = await handleFileUpload(req.files?.voidCheque?.[0]);

  // Parse recent campaigns
  let recentCampaigns = [];
  if (req.body.recentCampaigns) {
    try {
      // If it's a string, try to parse it as JSON array
      if (typeof req.body.recentCampaigns === 'string') {
        recentCampaigns = JSON.parse(req.body.recentCampaigns);
      } else if (Array.isArray(req.body.recentCampaigns)) {
        recentCampaigns = req.body.recentCampaigns;
      }
      // Ensure it's an array of strings
      recentCampaigns = recentCampaigns.map(String).filter(Boolean);
    } catch (err) {
      console.warn('Failed to parse recentCampaigns, using empty array');
      recentCampaigns = [];
    }
  }

    // Create organization record
    console.log('Creating organization with data...');
    console.log('Organization name:', req.body.organizationName);
    console.log('Registration number:', req.body.registrationNumber);
    
    const organization = await Organization.create({
      organizationName: req.body.organizationName,
      organizationType: req.body.organizationType,
      registrationNumber: req.body.registrationNumber,
      dateOfRegistration: req.body.dateOfRegistration,
      officialEmail: req.body.officialEmail,
      officialPhone: req.body.officialPhone,
      website: req.body.website,
      country: req.body.country,
      city: req.body.city,
      registeredAddress: req.body.registeredAddress,
      representativeName: req.body.representativeName,
      designation: req.body.designation,
      primaryCause: req.body.primaryCause,
      missionStatement: req.body.missionStatement,
      activeMembers,
      recentCampaigns,
      logo,
      registrationCertificate,
      taxCertificate,
      constitutionFile,
      proofOfAddress,
      bankDetails: {
        bankName: req.body.bankName,
        accountHolderName: req.body.accountHolderName,
        accountNumber: req.body.accountNumber,
        bankBranch: req.body.bankBranch,
        voidCheque,
      },
      socialMedia: {
        facebook: req.body.facebook,
        instagram: req.body.instagram,
        linkedin: req.body.linkedin,
      },
      status: 'pending',
      isVerified: false,
    });

    console.log('Organization created successfully:', organization._id);
    console.log('Organization status:', organization.status);

    return res.status(StatusCodes.CREATED).json({
      success: true,
      message:
        'Organization registration received. Please wait for admin approval.',
      data: {
        id: organization._id,
        name: organization.organizationName,
        status: organization.status,
      },
    });
};

// ================================
// @desc Get all organizations
// @route GET /api/v1/organizations
// @access Public
// ================================
export const getOrganizations = async (req, res) => {
  const { status, ...otherQueryParams } = req.query;
  
  // Build the query object
  const queryObj = { ...otherQueryParams };
  
  // Add status filter if provided
  if (status) {
    queryObj.status = status;
  }
  
  // Remove special query parameters
  ['page', 'sort', 'limit', 'fields'].forEach((k) => delete queryObj[k]);
  
  let queryStr = JSON.stringify(queryObj).replace(
    /\b(gte|gt|lte|lt)\b/g,
    (m) => `$${m}`
  );

  let query = Organization.find(JSON.parse(queryStr)).populate(
    'user',
    'name email'
  );

  if (req.query.sort) {
    query = query.sort(req.query.sort.split(',').join(' '));
  } else query = query.sort('-createdAt');

  if (req.query.fields) {
    query = query.select(req.query.fields.split(',').join(' '));
  } else query = query.select('-__v');

  const page = +req.query.page || 1;
  const limit = +req.query.limit || 10;
  const skip = (page - 1) * limit;

  query = query.skip(skip).limit(limit);
  const total = await Organization.countDocuments(JSON.parse(queryStr));
  const organizations = await query;

  const pagination = {};
  if (skip + limit < total) pagination.next = { page: page + 1, limit };
  if (skip > 0) pagination.prev = { page: page - 1, limit };

  res.status(StatusCodes.OK).json({
    success: true,
    count: organizations.length,
    total,
    pagination,
    data: organizations,
  });
};

// ================================
// @desc Get organization by ID
// @route GET /api/v1/organizations/:id
// @access Public
// ================================
export const getOrganization = async (req, res) => {
  const org = await Organization.findById(req.params.id).populate(
    'user',
    'name email'
  );
  if (!org)
    throw new NotFoundError(`No organization found with id ${req.params.id}`);

  res.status(StatusCodes.OK).json({ success: true, data: org });
};

// ================================
// @desc Get logged-in organization profile
// @route GET /api/v1/organizations/profile/me
// @access Private
// ================================
export const getOrganizationProfile = async (req, res) => {
  const org = await Organization.findOne({ user: req.user.userId }).populate(
    'user',
    'name email role'
  );
  if (!org) throw new NotFoundError('No organization found for this user');

  res.status(StatusCodes.OK).json({ success: true, data: org });
};

// ================================
// @desc Update organization profile
// @route PUT /api/v1/organizations/profile/me
// @access Private
// ================================
export const updateOrganizationProfile = async (req, res) => {
  const allowed = [
    'organizationName',
    'website',
    'officialPhone',
    'city',
    'registeredAddress',
    'primaryCause',
    'missionStatement',
    'activeMembers',
    'recentCampaigns',
  ];

  const updates = {};
  for (const key of allowed) if (req.body[key]) updates[key] = req.body[key];

  if (req.body.facebook || req.body.instagram || req.body.linkedin) {
    updates.socialMedia = {
      facebook: req.body.facebook,
      instagram: req.body.instagram,
      linkedin: req.body.linkedin,
    };
  }

  // Handle file updates
  if (req.files) {
    for (const field of Object.keys(req.files)) {
      const folder =
        field === 'logo' ? 'organization-logos' : 'organization-documents';
      updates[field] = await handleFileUpload(req.files[field][0], folder);
    }
  }

  const org = await Organization.findOneAndUpdate(
    { user: req.user.userId },
    updates,
    { new: true, runValidators: true }
  ).populate('user', 'name email role');

  if (!org) throw new NotFoundError('No organization found for this user');
  res.status(StatusCodes.OK).json({ success: true, data: org });
};

// ===== approve organizations
export const approveOrganization = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Get models directly from mongoose (they should be already registered during app startup)
    const Organization = mongoose.model('Organization');
    const User = mongoose.model('User');

    const org = await Organization.findById(req.params.id).session(session);
    if (!org) {
      await session.abortTransaction();
      session.endSession();
      throw new NotFoundError('Organization not found');
    }
    
    if (org.status === 'approved') {
      await session.abortTransaction();
      session.endSession();
      throw new BadRequestError('Organization is already approved');
    }

    // Find the user associated with this organization
    const user = await User.findById(org.user).session(session);
    
    if (!user) {
      await session.abortTransaction();
      session.endSession();
      throw new NotFoundError('Associated user account not found');
    }

    if (!user) {
      // If user doesn't exist, create a new one
      const password = generateRandomPassword(12);
      user = new User({
        name: org.representativeName,
        email: org.officialEmail,
        password,
        role: 'organization',
        phoneNumber: org.officialPhone,
        isVerified: true,
      });
      await user.save({ session });
      
      // Send approval email with the new password
      await sendApprovalEmail(org, password);
    } else if (user.role !== 'organization') {
      // If user exists but is not an organization, throw an error
      throw new BadRequestError('A user with this email already has a different role');
    }

    // Update organization
    org.user = user._id;
    org.status = 'approved';
    org.isVerified = true;
    org.approvedBy = req.user.userId;
    org.approvedAt = new Date();
    await org.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Organization approved successfully.',
      data: { 
        id: org._id, 
        name: org.organizationName, 
        status: org.status,
        userId: user._id
      },
    });
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error in approveOrganization:', err);
    
    // Handle specific error cases
    if (err.name === 'ValidationError') {
      throw new BadRequestError(err.message);
    } else if (err.name === 'MongoError' && err.code === 11000) {
      throw new BadRequestError('A user with this email already exists');
    }
    
    throw new Error(`Error approving organization: ${err.message}`);
  }
};


// ================================
// @desc Reject organization
// @route PUT /api/v1/organizations/:id/reject
// @access Private (Admin)
// ================================
export const rejectOrganization = async (req, res) => {
  const org = await Organization.findByIdAndUpdate(
    req.params.id,
    {
      status: 'rejected',
      rejectionReason: req.body.reason || 'Not specified',
    },
    { new: true, runValidators: true }
  );

  if (!org)
    throw new NotFoundError(`No organization found with id ${req.params.id}`);

  try {
    await sendEmail({
      to: org.officialEmail,
      subject: 'Organization Registration Rejected',
      html: `
        <h2>Registration Rejected</h2>
        <p>Dear ${org.representativeName},</p>
        <p>Your organization "${org.organizationName}" registration has been rejected.</p>
        <p><strong>Reason:</strong> ${req.body.reason || 'Not specified'}</p>
      `,
    });
  } catch (err) {
    console.error('Email send failed:', err);
  }

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Organization rejected successfully',
    data: org,
  });
};

// ================================
// @desc Delete organization (Admin)
// @route DELETE /api/v1/organizations/:id
// ================================
export const deleteOrganization = async (req, res) => {
  const org = await Organization.findById(req.params.id);
  if (!org)
    throw new NotFoundError(`No organization found with id ${req.params.id}`);

  const fields = [
    'registrationCertificate',
    'taxCertificate',
    'constitutionFile',
    'proofOfAddress',
    'logo',
  ];

  for (const field of fields) {
    if (org[field]?.publicId) await deleteFromCloudinary(org[field].publicId);
  }

  if (org.bankDetails?.voidCheque?.publicId)
    await deleteFromCloudinary(org.bankDetails.voidCheque.publicId);

  await org.deleteOne();
  if (org.user) {
    await User.findByIdAndUpdate(org.user, { role: 'user' });
  }

  res.status(StatusCodes.OK).json({ success: true, data: {} });
};

// ================================
// Helpers
// ================================
const generateRandomPassword = (length = 12) => {
  const chars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  return Array.from({ length }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
};

const sendApprovalEmail = async (org, password) => {
  try {
    await sendEmail({
      to: org.officialEmail,
      subject: 'Your Organization Has Been Approved! 🎉',
      html: `
        <div style="font-family: Arial, sans-serif;">
          <h2 style="color:#4CAF50;">Congratulations, ${org.representativeName}!</h2>
          <p>Your organization <strong>${org.organizationName}</strong> has been approved.</p>
          <div style="background:#f9f9f9;padding:15px;border-radius:5px;">
            <p><strong>Email:</strong> ${org.officialEmail}</p>
            <p><strong>Password:</strong> ${password}</p>
          </div>
          <p>Please change your password after your first login.</p>
          <a href="${process.env.FRONTEND_URL}/login" style="background:#4CAF50;color:white;padding:10px 20px;border-radius:5px;text-decoration:none;">Login Now</a>
        </div>
      `,
    });
  } catch (err) {
    console.error('Failed to send approval email:', err);
  }
};
