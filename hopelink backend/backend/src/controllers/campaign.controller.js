import { StatusCodes } from 'http-status-codes';
import Campaign from '../models/campaign.model.js';
import Organization from '../models/organization.model.js';
import Donation from '../models/donation.model.js';
import Event from '../models/event.model.js';

// Utility function to transform campaign data
const transformCampaign = (campaign) => {
  const campaignObj = campaign.toObject ? campaign.toObject() : campaign;
  
  return {
    ...campaignObj,
    images: campaignObj.images.map(img => img.url),
    updates: campaignObj.updates.map(({ title, description, date }) => ({
      title,
      description,
      date
    })),
    faqs: campaignObj.faqs.map(({ question, answer }) => ({
      question,
      answer
    }))
  };
};
import { BadRequestError, NotFoundError, UnauthorizedError } from '../errors/index.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';
import { model } from 'mongoose';

// @desc    Create a new campaign
// @route   POST /api/v1/campaigns
// @access  Private (Organization)
export const createCampaign = async (req, res) => {
  // Add user to req.body
  req.body.organization = req.user.organization;
  
  // Check if organization exists and is approved
  const organization = await Organization.findById(req.user.organization);
  
  if (!organization) {
    throw new BadRequestError('No organization found');
  }
  
  if (organization.status !== 'approved') {
    throw new UnauthorizedError('Your organization is not approved to create campaigns');
  }

  // Handle file uploads
  if (req.files && req.files.images) {
    req.body.images = await Promise.all(
      req.files.images.map(async (file) => {
        const result = await uploadToCloudinary(file.path, 'campaigns');
        return {
          url: result.secure_url,
          publicId: result.public_id,
          isPrimary: false,
        };
      })
    );
    
    // Set first image as primary if no primary is set
    if (req.body.images.length > 0) {
      req.body.images[0].isPrimary = true;
    }
  }

  const campaign = await Campaign.create(req.body);

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: transformCampaign(campaign),
  });
};

// @desc    Get all campaigns
// @route   GET /api/v1/campaigns
// @access  Public
export const getCampaigns = async (req, res) => {
  // Copy req.query
  const reqQuery = { ...req.query };

  // Fields to exclude
  const removeFields = ['select', 'sort', 'page', 'limit'];

  // Loop over removeFields and delete them from reqQuery
  removeFields.forEach((param) => delete reqQuery[param]);

  // Create query string
  let queryStr = JSON.stringify(reqQuery);

  // Create operators ($gt, $gte, etc)
  queryStr = queryStr.replace(/(gt|gte|lt|lte|in)\b/g, (match) => `$${match}`);

  // Finding resource
  let query = Campaign.find(JSON.parse(queryStr)).populate({

    path: 'organization',
    select: 'organizationName',
    model: Organization,
  })
  


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
  const total = await Campaign.countDocuments(JSON.parse(queryStr));

  query = query.skip(startIndex).limit(limit);

  // Executing query
  const campaigns = await query;

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

  const transformedCampaigns = campaigns.map(campaign => transformCampaign(campaign));
  
  res.status(StatusCodes.OK).json({
    success: true,
    count: transformedCampaigns.length,
    pagination,
    data: transformedCampaigns,
  });
};

// @desc    Get single campaign
// @route   GET /api/v1/campaigns/:id
// @access  Public
export const getCampaign = async (req, res) => {
  const campaign = await Campaign.findById(req.params.id)
    .populate({

      path : 'organization',
      select: 'organizationName',
      model :Organization
    })

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  res.status(StatusCodes.OK).json({
    success: true,
    data: campaign,
  });
};

// @desc    Update campaign
// @route   PUT /api/v1/campaigns/:id
// @access  Private (Organization owner or admin)
export const updateCampaign = async (req, res) => {
  let campaign = await Campaign.findById(req.params.id);

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  // Make sure user is campaign owner or admin
  if (
    campaign.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError(
      `User ${req.user.id} is not authorized to update this campaign`
    );
  }

  // Handle file uploads if any
  if (req.files && req.files.images) {
    // Delete old images from cloudinary
    if (campaign.images && campaign.images.length > 0) {
      await Promise.all(
        campaign.images.map(async (image) => {
          if (image.publicId) {
            await deleteFromCloudinary(image.publicId);
          }
        })
      );
    }

    // Upload new images
    req.body.images = await Promise.all(
      req.files.images.map(async (file) => {
        const result = await uploadToCloudinary(file.path, 'campaigns');
        return {
          url: result.secure_url,
          publicId: result.public_id,
          isPrimary: false,
        };
      })
    );
  }

  // Update campaign
  campaign = await Campaign.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: campaign,
  });
};

// @desc    Delete campaign
// @route   DELETE /api/v1/campaigns/:id
// @access  Private (Organization owner or admin)
export const deleteCampaign = async (req, res) => {
  const campaign = await Campaign.findById(req.params.id);

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  // Make sure user is campaign owner or admin
  if (
    campaign.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError(
      `User ${req.user.id} is not authorized to delete this campaign`
    );
  }

  // Delete images from cloudinary
  if (campaign.images && campaign.images.length > 0) {
    await Promise.all(
      campaign.images.map(async (image) => {
        if (image.publicId) {
          await deleteFromCloudinary(image.publicId);
        }
      })
    );
  }

  await campaign.remove();

  res.status(StatusCodes.OK).json({
    success: true,
    data: {},
  });
};

// @desc    Upload campaign images
// @route   PUT /api/v1/campaigns/:id/images
// @access  Private (Organization owner or admin)
export const uploadCampaignImages = async (req, res) => {
  if (!req.files || !req.files.images) {
    throw new BadRequestError('Please upload files');
  }

  const campaign = await Campaign.findById(req.params.id);

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  // Make sure user is campaign owner or admin
  // if (
  //   campaign.organization.toString() !== req.user.organization &&
  //   req.user.role !== 'admin'
  // ) {
  //   throw new UnauthorizedError(
  //     `User ${req.user.id} is not authorized to update this campaign`
  //   );
  // }
if (
  campaign.organization.toString() !== req.user.organization?.toString() &&
  req.user.role !== 'admin'
) {
  throw new UnauthorizedError(
    `User ${req.user.id} is not authorized to update this campaign`
  );
}

  // Upload new images
const uploadedImages = await Promise.all(
  req.files.images.map(async (file) => {
    try {
      console.log('Processing file:', file.originalname);
      const result = await uploadToCloudinary(file, 'campaigns');
      console.log('Upload result:', result);
      return {
        url: result.url,  // Changed from result.secure_url to result.url
        publicId: result.public_id,
        isPrimary: false,
      };
    } catch (error) {
      console.error('Error uploading file:', error);
      throw error; // Rethrow to be caught by the outer try-catch
    }
  })
);

  // Add new images to the campaign
  campaign.images = [...campaign.images, ...uploadedImages];
  await campaign.save();

  res.status(StatusCodes.OK).json({
    success: true,
    data: campaign.images,
  });
};

// @desc    Delete campaign image
// @route   DELETE /api/v1/campaigns/:id/images/:imageId
// @access  Private (Organization owner or admin)
export const deleteCampaignImage = async (req, res) => {
  const campaign = await Campaign.findById(req.params.id);

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  // Make sure user is campaign owner or admin
  if (
    campaign.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError(
      `User ${req.user.id} is not authorized to update this campaign`
    );
  }

  // Find the image to delete
  const imageIndex = campaign.images.findIndex(
    (img) => img._id.toString() === req.params.imageId
  );

  if (imageIndex === -1) {
    throw new NotFoundError(`No image with the id of ${req.params.imageId}`);
  }

  const imageToDelete = campaign.images[imageIndex];

  // Delete image from cloudinary if it has a publicId
  if (imageToDelete.publicId) {
    await deleteFromCloudinary(imageToDelete.publicId);
  }

  // Remove image from array
  campaign.images.splice(imageIndex, 1);
  await campaign.save();

  res.status(StatusCodes.OK).json({
    success: true,
    data: {},
  });
};

// @desc    Set primary campaign image
// @route   PUT /api/v1/campaigns/:id/images/:imageId/set-primary
// @access  Private (Organization owner or admin)
export const setPrimaryCampaignImage = async (req, res) => {
  const campaign = await Campaign.findById(req.params.id);

  if (!campaign) {
    throw new NotFoundError(`No campaign with the id of ${req.params.id}`);
  }

  // Make sure user is campaign owner or admin
  if (
    campaign.organization.toString() !== req.user.organization &&
    req.user.role !== 'admin'
  ) {
    throw new UnauthorizedError(
      `User ${req.user.id} is not authorized to update this campaign`
    );
  }

  // Find the image to set as primary
  const imageIndex = campaign.images.findIndex(
    (img) => img._id.toString() === req.params.imageId
  );

  if (imageIndex === -1) {
    throw new NotFoundError(`No image with the id of ${req.params.imageId}`);
  }

  // Set all images to not primary
  campaign.images = campaign.images.map((img) => ({
    ...img.toObject(),
    isPrimary: false,
  }));

  // Set selected image as primary
  campaign.images[imageIndex].isPrimary = true;
  await campaign.save();

  res.status(StatusCodes.OK).json({
    success: true,
    data: campaign.images,
  });
};

// @desc    Get all campaigns with donations and events
// @route   GET /api/v1/campaigns/with-details/all
// @access  Public
export const getCampaignsWithDonationsAndEvents = async (req, res) => {
  try {
    // Get all campaigns with organization details
    const campaigns = await Campaign.find({})
      .populate('organization', 'organizationName logo')
      .populate('category', 'name')
      .lean();

    // Get all donations for all campaigns
    const campaignIds = campaigns.map(campaign => campaign._id);
    const donations = await Donation.find({ campaign: { $in: campaignIds } })
      .populate('donor', 'name email')
      .lean();

    // Get all events for all campaigns
    const events = await Event.find({ campaign: { $in: campaignIds } })
      .sort({ date: 1 })
      .lean();

    // Group donations by campaign
    const donationsByCampaign = {};
    donations.forEach(donation => {
      if (!donationsByCampaign[donation.campaign]) {
        donationsByCampaign[donation.campaign] = [];
      }
      donationsByCampaign[donation.campaign].push(donation);
    });

    // Group events by campaign
    const eventsByCampaign = {};
    events.forEach(event => {
      if (!eventsByCampaign[event.campaign]) {
        eventsByCampaign[event.campaign] = [];
      }
      eventsByCampaign[event.campaign].push(event);
    });

    // Combine the data
    const result = campaigns.map(campaign => ({
      ...transformCampaign(campaign),
      donations: (donationsByCampaign[campaign._id] || []).map(donation => ({
        amount: donation.amount,
        donor: donation.donor,
        message: donation.message,
        isAnonymous: donation.isAnonymous,
        date: donation.createdAt
      })),
      events: (eventsByCampaign[campaign._id] || []).map(event => ({
        title: event.title,
        description: event.description,
        date: event.date,
        location: event.location,
        image: event.image
      })),
      totalDonations: (donationsByCampaign[campaign._id] || []).reduce(
        (sum, donation) => sum + donation.amount,
        0
      ),
      donationCount: (donationsByCampaign[campaign._id] || []).length,
    }));

    res.status(StatusCodes.OK).json({
      success: true,
      count: result.length,
      data: result,
    });
  } catch (error) {
    console.error('Error getting campaigns with details:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'Server error',
    });
  }
};

// @desc    Add campaign update
// @route   POST /api/v1/campaigns/:id/updates
// @access  Private (Organization owner or admin)
export const addCampaignUpdate = async (req, res) => {
  const { title, description } = req.body;
  
  try {
    const campaign = await Campaign.findById(req.params.id);
    if (!campaign) {
      return res.status(StatusCodes.NOT_FOUND).json({
        success: false,
        message: 'Campaign not found',
      });
    }

    // Check if user is the organization owner or admin
    const organization = await Organization.findById(campaign.organization);
    if (!organization) {
      return res.status(StatusCodes.NOT_FOUND).json({
        success: false,
        message: 'Organization not found',
      });
    }

    if (organization.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(StatusCodes.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this campaign',
      });
    }

    const newUpdate = {
      title,
      description,
    };

    campaign.updates.push(newUpdate);
    await campaign.save();

    res.status(StatusCodes.CREATED).json({
      success: true,
      data: campaign.updates[campaign.updates.length - 1],
    });
  } catch (error) {
    console.error('Error adding campaign update:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'Server error',
    });
  }
};

// @desc    Add campaign FAQ
// @route   POST /api/v1/campaigns/:id/faqs
// @access  Private (Organization owner or admin)
export const addCampaignFaq = async (req, res) => {
  const { question, answer } = req.body;
  
  try {
    const campaign = await Campaign.findById(req.params.id);
    if (!campaign) {
      return res.status(StatusCodes.NOT_FOUND).json({
        success: false,
        message: 'Campaign not found',
      });
    }

    // Check if user is the organization owner or admin
    const organization = await Organization.findById(campaign.organization);
    if (!organization) {
      return res.status(StatusCodes.NOT_FOUND).json({
        success: false,
        message: 'Organization not found',
      });
    }

    if (organization.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(StatusCodes.FORBIDDEN).json({
        success: false,
        message: 'Not authorized to update this campaign',
      });
    }

    const newFaq = {
      question,
      answer,
    };

    campaign.faqs.push(newFaq);
    await campaign.save();

    res.status(StatusCodes.CREATED).json({
      success: true,
      data: campaign.faqs[campaign.faqs.length - 1],
    });
  } catch (error) {
    console.error('Error adding campaign FAQ:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'Server error',
    });
  }
};
