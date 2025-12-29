// controllers/event.controller.js
import { Event, VolunteerEnrollment } from '../models/index.js';
import {
  uploadToCloudinary,
  deleteFromCloudinary,
} from '../services/cloudinary.service.js';
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
} from '../errors/index.js';
import User from '../models/user.model.js';
import Organization from '../models/organization.model.js';
export const createEvent = async (req, res, next) => {
  try {
    const {
      title,
      description,
      category,
      eventType,
      address,
      city,
      state,
      coordinates,
      startDate,
      endDate,
      maxVolunteers,
      requiredSkills = [],
      eligibility = 'Anyone',
    } = req.body;

    // Validate required fields
    if (!title || !description || !category || !startDate) {
      throw new BadRequestError('Please provide all required fields');
    }

    const organizerType =
      req.user.role === 'organization' ? 'Organization' : 'User';
    const organizerId =
      req.user.role === 'organization' ? req.user.organization : req.user._id;

    // Handle file uploads
    let images = [];
    if (req.files && req.files.length > 0) {
      try {
        // Upload each file to Cloudinary
        for (const file of req.files) {
          const result = await uploadToCloudinary(file, 'events');

          images.push({
            url: result.url,
            publicId: result.public_id,
            isPrimary: images.length === 0, // First image is primary
          });
        }
      } catch (uploadError) {
        throw new BadRequestError('Failed to upload one or more images');
      }
    }

    // Create the event
    const event = new Event({
      title,
      description,
      category,
      eventType: eventType || 'one-day',
      location: {
        address,
        city,
        state,
        coordinates: coordinates
          ? {
              type: 'Point',
              coordinates: coordinates.split(',').map(Number),
            }
          : undefined,
      },
      startDate,
      endDate: endDate || startDate,
      maxVolunteers: maxVolunteers ? Number(maxVolunteers) : undefined,
      requiredSkills: Array.isArray(requiredSkills)
        ? requiredSkills
        : [requiredSkills].filter(Boolean),
      eligibility,
      organizerType,
      organizer: organizerId,
      images,
      status: 'published',
    });

    await event.save();

    // Populate the organizer info for the response
    const populatedEvent = await Event.findById(event._id)
      // .populate({
      //   path: 'organizer',
      //   model: organizerType === 'organization' ? 'Organization' : 'User',
      //   select: 'name email logo'
      // })
      .lean();

    // Format the response
    const response = {
      ...populatedEvent,
      creatorInfo: {
        id: populatedEvent.organizer._id.toString(),
        name: populatedEvent.organizer.name,
        type: organizerType,
        ...(populatedEvent.organizer.logo && {
          logo: populatedEvent.organizer.logo,
        }),
      },
    };

    // Remove the populated organizer field
    delete response.organizer;

    res.status(201).json({
      success: true,
      data: response,
    });
  } catch (error) {
    next(error);
  }
};

// Add other event controller methods (getEvents, getEventById, etc.) here
// ...

/**
 * Get all events with filters
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const getEvents = async (req, res, next) => {
  try {
    const {
      category,
      location,
      startDate,
      endDate,
      organizerType,
      status = 'upcoming',
      page = 1,
      limit = 10,
    } = req.query;

    const query = {};

    if (category) query.category = category;
    if (location) query['location.city'] = new RegExp(location, 'i');
    if (organizerType) query.organizerType = organizerType;

    // Handle date filtering
    const now = new Date();
    if (status === 'upcoming') {
      query.startDate = { $gte: now };
    } else if (status === 'ongoing') {
      query.startDate = { $lte: now };
      query.endDate = { $gte: now };
    } else if (status === 'past') {
      query.endDate = { $lt: now };
    }

    if (startDate && endDate) {
      query.startDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    let events = await Event.find(query)
      .sort({ startDate: 1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();

    // Manually populate organizer based on organizerType (dynamic reference)
    for (let event of events) {
      if (event.organizerType === 'organization') {
        const organizer = await Organization.findById(event.organizer)
          .select('organizationName officialEmail logo')
          .lean();
        event.organizer = organizer;
      } else if (event.organizerType === 'user') {
        const organizer = await User.findById(event.organizer)
          .select('name email logo')
          .lean();
        event.organizer = organizer;
      }
    }

    // Transform the response to include creator info consistently
    // events.forEach(event => {
    //   event.creatorInfo = {
    //     id: event.organizer._id,
    //     name: event.organizer.name,
    //     type: event.organizerType,
    //     ...(event.organizer.logo && { logo: event.organizer.logo })
    //   };
    //   // Remove the populated organizer field to avoid confusion
    //   delete event.organizer;
    // });

    const total = await Event.countDocuments(query);

    res.json({
      success: true,
      count: events.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      data: events,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get event by ID
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const getEventById = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id).populate({
      path: 'volunteers',
      select: 'name email phone profileImage',
      options: { limit: 10 },
    });

    // Manually populate organizer based on organizerType (dynamic reference)
    if (event && event.organizerType === 'Organization') {
      await event.populate({
        path: 'organizer',
        model: 'Organization',
        select: 'name email phone logo description',
      });
    } else if (event && event.organizerType === 'User') {
      await event.populate({
        path: 'organizer',
        model: 'User',
        select: 'name email phone logo description',
      });
    }

    if (!event) {
      throw new NotFoundError('Event not found');
    }

    // Check if current user is enrolled
    let userEnrollment = null;
    if (req.user) {
      userEnrollment = await VolunteerEnrollment.findOne({
        event: event._id,
        user: req.user._id,
      });
    }

    res.json({
      success: true,
      data: {
        ...event.toObject(),
        userEnrollment,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update an event
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const updateEvent = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      throw new NotFoundError('Event not found');
    }

    // Check if user is the organizer or admin
    const isOrganizer =
      event.organizerType === 'user'
        ? event.organizer.toString() === req.user._id.toString()
        : event.organizer.toString() === req.user.organization?.toString();

    if (!isOrganizer && req.user.role !== 'admin') {
      throw new ForbiddenError('Not authorized to update this event');
    }

    const updates = Object.keys(req.body);
    const allowedUpdates = [
      'title',
      'description',
      'category',
      'eventType',
      'location',
      'startDate',
      'endDate',
      'maxVolunteers',
      'requiredSkills',
      'eligibility',
      'status',
      'images',
    ];

    updates.forEach((update) => {
      if (allowedUpdates.includes(update)) {
        event[update] = req.body[update];
      }
    });

    await event.save();

    res.json({
      success: true,
      data: event,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete an event
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const deleteEvent = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      throw new NotFoundError('Event not found');
    }

    // Check if user is the organizer or admin
    const isOrganizer =
      event.organizerType === 'User'
        ? event.organizer.toString() === req.user._id.toString()
        : event.organizer.toString() === req.user.organization?.toString();

    if (!isOrganizer && req.user.role !== 'admin') {
      throw new ForbiddenError('Not authorized to delete this event');
    }

    await event.remove();

    // Also remove all enrollments for this event
    await VolunteerEnrollment.deleteMany({ event: event._id });

    res.json({
      success: true,
      data: {},
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Enroll in an event
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const enrollInEvent = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      throw new NotFoundError('Event not found');
    }

    // Check if event is open for enrollment
    if (event.status !== 'published') {
      throw new BadRequestError('This event is not open for enrollment');
    }

    // Check if user is already enrolled
    const existingEnrollment = await VolunteerEnrollment.findOne({
      event: event._id,
      user: req.user._id,
    });

    if (existingEnrollment) {
      if (existingEnrollment.status === 'withdrawn') {
        existingEnrollment.status = 'pending';
        await existingEnrollment.save();
        return res.json({
          success: true,
          data: existingEnrollment,
        });
      }
      throw new BadRequestError('You are already enrolled in this event');
    }

    // Check if there's space available
    if (event.maxVolunteers) {
      const enrolledCount = await VolunteerEnrollment.countDocuments({
        event: event._id,
        status: { $in: ['pending', 'approved'] },
      });

      if (enrolledCount >= event.maxVolunteers) {
        throw new BadRequestError('This event has reached maximum capacity');
      }
    }

    const enrollment = new VolunteerEnrollment({
      event: event._id,
      user: req.user._id,
      status: 'pending',
    });

    await enrollment.save();

    // Add to event's volunteers array
    await Event.findByIdAndUpdate(event._id, {
      $addToSet: { volunteers: req.user._id },
    });

    res.status(201).json({
      success: true,
      data: enrollment,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Withdraw from an event
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const withdrawEnrollment = async (req, res, next) => {
  try {
    const enrollment = await VolunteerEnrollment.findOne({
      _id: req.params.enrollmentId,
      user: req.user._id,
    });

    if (!enrollment) {
      throw new NotFoundError('Enrollment not found');
    }

    // Only allow withdrawal if event hasn't started
    const event = await Event.findById(enrollment.event);
    if (new Date() > event.startDate) {
      throw new BadRequestError('Cannot withdraw after event has started');
    }

    enrollment.status = 'withdrawn';
    await enrollment.save();

    // Remove from event's volunteers array
    await Event.findByIdAndUpdate(enrollment.event, {
      $pull: { volunteers: req.user._id },
    });

    res.json({
      success: true,
      data: {},
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get event volunteers (for event organizers)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const getEventVolunteers = async (req, res, next) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      throw new NotFoundError('Event not found');
    }

    // Check if user is the organizer or admin
    const isOrganizer =
      event.organizerType === 'User'
        ? event.organizer.toString() === req.user._id.toString()
        : event.organizer.toString() === req.user.organization?.toString();

    if (!isOrganizer && req.user.role !== 'admin') {
      throw new ForbiddenError(
        'Not authorized to view volunteers for this event',
      );
    }

    const { status, page = 1, limit = 20 } = req.query;
    const query = { event: event._id };

    if (status) {
      query.status = status;
    }

    const enrollments = await VolunteerEnrollment.find(query)
      .populate({
        path: 'user',
        select: 'name email phone profileImage skills',
      })
      .sort({ enrollmentDate: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    const total = await VolunteerEnrollment.countDocuments(query);

    res.json({
      success: true,
      count: enrollments.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      data: enrollments,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update volunteer status (for event organizers)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const updateVolunteerStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (!['approved', 'rejected', 'attended'].includes(status)) {
      throw new BadRequestError('Invalid status');
    }

    const enrollment = await VolunteerEnrollment.findById(
      req.params.enrollmentId,
    )
      .populate('event')
      .populate('user', 'name email');

    if (!enrollment) {
      throw new NotFoundError('Enrollment not found');
    }

    // Check if user is the event organizer or admin
    const event = enrollment.event;
    const isOrganizer =
      event.organizerType === 'User'
        ? event.organizer.toString() === req.user._id.toString()
        : event.organizer.toString() === req.user.organization?.toString();

    if (!isOrganizer && req.user.role !== 'admin') {
      throw new ForbiddenError('Not authorized to update this enrollment');
    }

    enrollment.status = status;
    await enrollment.save();

    // If approved, add to event's volunteers array if not already there
    if (status === 'approved') {
      await Event.findByIdAndUpdate(event._id, {
        $addToSet: { volunteers: enrollment.user._id },
      });
    }

    res.json({
      success: true,
      data: enrollment,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user's enrolled events
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
export const getMyEnrollments = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const query = { user: req.user._id };

    if (status) {
      query.status = status;
    }

    const enrollments = await VolunteerEnrollment.find(query)
      .populate({
        path: 'event',
        select: 'title description startDate endDate location images',
        populate: {
          path: 'organizer',
          select: 'name logo',
        },
      })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    const total = await VolunteerEnrollment.countDocuments(query);

    res.json({
      success: true,
      count: enrollments.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      data: enrollments,
    });
  } catch (error) {
    next(error);
  }
};
// Export all controller methods
export default {
  createEvent,
  // export other methods
};
