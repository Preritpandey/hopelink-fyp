import { StatusCodes } from 'http-status-codes';
import User from '../models/user.model.js';
import VolunteerCreditHours from '../models/volunteerCreditHours.model.js';
import VolunteerApplication from '../models/volunteerApplication.model.js';
import VolunteerEnrollment from '../models/volunteerEnrollment.model.js';
import { BadRequestError, NotFoundError } from '../errors/index.js';

const CREDIT_HOURS_TO_POINTS_RATIO = 4; // 4 credit hours = 1 point

/**
 * Calculate points based on credit hours
 * @param {number} creditHours - Total credit hours
 * @returns {number} Calculated points
 */
const calculatePointsFromHours = (creditHours) => {
  return Math.floor(creditHours / CREDIT_HOURS_TO_POINTS_RATIO);
};

/**
 * Aggregate all credit hours for a user from different sources
 * @param {string} userId - User ID
 * @returns {Promise<number>} Total credit hours
 */
export const aggregateUserCreditHours = async (userId) => {
  try {
    // Get all credit hour entries for the user
    const creditEntries = await VolunteerCreditHours.find({
      user: userId,
      isApplied: true,
    });

    const totalHours = creditEntries.reduce(
      (sum, entry) => sum + entry.creditHours,
      0
    );

    return totalHours;
  } catch (error) {
    console.error('Error aggregating credit hours:', error);
    throw error;
  }
};

/**
 * Update user's total points based on credit hours
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Updated user object with new totals
 */
export const updateUserPoints = async (userId) => {
  try {
    const totalCreditHours = await aggregateUserCreditHours(userId);
    const totalPoints = calculatePointsFromHours(totalCreditHours);

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        totalVolunteerHours: totalCreditHours,
        totalPoints: totalPoints,
      },
      { new: true, runValidators: true }
    );

    return updatedUser;
  } catch (error) {
    console.error('Error updating user points:', error);
    throw error;
  }
};

/**
 * Grant credit hours to a user from a volunteer application
 * @route POST /api/v1/volunteer-credits/grant/application/:applicationId
 * @access Private (Admin/Organization)
 */
export const grantCreditsFromApplication = async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { creditHours, description } = req.body;

    if (!creditHours || creditHours < 0) {
      throw new BadRequestError('Valid credit hours are required');
    }

    const application = await VolunteerApplication.findById(applicationId);
    if (!application) {
      throw new NotFoundError('Application not found');
    }

    // Check if credits have already been granted
    const existingCredit = await VolunteerCreditHours.findOne({
      user: application.user,
      source: 'volunteer_application',
      sourceId: applicationId,
      isApplied: true,
    });

    if (existingCredit) {
      throw new BadRequestError(
        'Credits have already been granted for this application'
      );
    }

    // Create credit hours entry
    const creditEntry = await VolunteerCreditHours.create({
      user: application.user,
      creditHours,
      source: 'volunteer_application',
      sourceId: applicationId,
      sourceModel: 'VolunteerApplication',
      description:
        description || `Credits from volunteer application for job`,
      isApplied: true,
      appliedAt: new Date(),
    });

    // Update application
    application.creditHoursGranted = creditHours;
    application.creditGrantedAt = new Date();
    await application.save();

    // Update user points
    await updateUserPoints(application.user);

    res.status(StatusCodes.CREATED).json({
      success: true,
      message: 'Credit hours granted successfully',
      creditEntry,
    });
  } catch (error) {
    console.error('Error granting credits from application:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error granting credit hours',
    });
  }
};

/**
 * Grant credit hours to a user from event enrollment
 * @route POST /api/v1/volunteer-credits/grant/enrollment/:enrollmentId
 * @access Private (Admin/Organization)
 */
export const grantCreditsFromEnrollment = async (req, res) => {
  try {
    const { enrollmentId } = req.params;
    const { creditHours, description } = req.body;

    if (!creditHours || creditHours < 0) {
      throw new BadRequestError('Valid credit hours are required');
    }

    const enrollment = await VolunteerEnrollment.findById(enrollmentId);
    if (!enrollment) {
      throw new NotFoundError('Enrollment not found');
    }

    // Check if credits have already been granted
    const existingCredit = await VolunteerCreditHours.findOne({
      user: enrollment.user,
      source: 'volunteer_enrollment',
      sourceId: enrollmentId,
      isApplied: true,
    });

    if (existingCredit) {
      throw new BadRequestError(
        'Credits have already been granted for this enrollment'
      );
    }

    // Create credit hours entry
    const creditEntry = await VolunteerCreditHours.create({
      user: enrollment.user,
      creditHours,
      source: 'volunteer_enrollment',
      sourceId: enrollmentId,
      sourceModel: 'VolunteerEnrollment',
      description: description || `Credits from event participation`,
      isApplied: true,
      appliedAt: new Date(),
    });

    // Update enrollment
    enrollment.creditHoursGranted = creditHours;
    enrollment.creditGrantedAt = new Date();
    await enrollment.save();

    // Update user points
    await updateUserPoints(enrollment.user);

    res.status(StatusCodes.CREATED).json({
      success: true,
      message: 'Credit hours granted successfully',
      creditEntry,
    });
  } catch (error) {
    console.error('Error granting credits from enrollment:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error granting credit hours',
    });
  }
};

/**
 * Get user's total credit hours and points
 * @route GET /api/v1/volunteer-credits/user/:userId
 * @access Public
 */
export const getUserCreditsAndPoints = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    // Get all applied credit entries
    const creditEntries = await VolunteerCreditHours.find({
      user: userId,
      isApplied: true,
    })
      .sort({ appliedAt: -1 })
      .lean();

    const totalCreditHours = creditEntries.reduce(
      (sum, entry) => sum + entry.creditHours,
      0
    );
    const totalPoints = calculatePointsFromHours(totalCreditHours);

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        userId,
        userName: user.name,
        userEmail: user.email,
        totalCreditHours,
        totalPoints,
        creditBreakdown: creditEntries,
        pointsPerHour: CREDIT_HOURS_TO_POINTS_RATIO,
      },
    });
  } catch (error) {
    console.error('Error fetching user credits and points:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching user credits and points',
    });
  }
};

/**
 * Get my credit hours and points (authenticated user)
 * @route GET /api/v1/volunteer-credits/me
 * @access Private
 */
export const getMyCreditsAndPoints = async (req, res) => {
  try {
    const userId = req.user._id;

    // Get user details
    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    // Get all applied credit entries
    const creditEntries = await VolunteerCreditHours.find({
      user: userId,
      isApplied: true,
    })
      .sort({ appliedAt: -1 })
      .lean();

    const totalCreditHours = creditEntries.reduce(
      (sum, entry) => sum + entry.creditHours,
      0
    );
    const totalPoints = calculatePointsFromHours(totalCreditHours);

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        userId,
        userName: user.name,
        userEmail: user.email,
        totalCreditHours,
        totalPoints,
        creditBreakdown: creditEntries,
        pointsPerHour: CREDIT_HOURS_TO_POINTS_RATIO,
      },
    });
  } catch (error) {
    console.error('Error fetching my credits and points:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching credits and points',
    });
  }
};

/**
 * Get leaderboard of top users by points
 * @route GET /api/v1/volunteer-credits/leaderboard
 * @query {number} limit - Number of top users to return (default: 20)
 * @query {number} skip - Number of records to skip (default: 0)
 * @access Public
 */
export const getLeaderboard = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 100); // Max 100
    const skip = parseInt(req.query.skip) || 0;

    // Aggregate pipeline to get user credits and sort by points
    const leaderboard = await User.aggregate([
      {
        $match: { role: 'user' }, // Only regular users
      },
      {
        $sort: { totalPoints: -1, totalVolunteerHours: -1 },
      },
      {
        $skip: skip,
      },
      {
        $limit: limit,
      },
      {
        $project: {
          _id: 1,
          name: 1,
          email: 1,
          profileImage: 1,
          location: 1,
          totalCreditHours: '$totalVolunteerHours',
          totalPoints: 1,
          rating: 1,
        },
      },
      {
        $addFields: {
          rank: { $add: [skip + 1] }, // This will be updated in post-processing
        },
      },
    ]);

    // Add rank numbers
    const leaderboardWithRank = leaderboard.map((user, index) => ({
      ...user,
      rank: skip + index + 1,
    }));

    // Get total count for pagination
    const totalUsers = await User.countDocuments({ role: 'user' });

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        leaderboard: leaderboardWithRank,
        pagination: {
          currentPage: Math.floor(skip / limit) + 1,
          pageSize: limit,
          totalUsers,
          totalPages: Math.ceil(totalUsers / limit),
          hasMore: skip + limit < totalUsers,
        },
      },
    });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching leaderboard',
    });
  }
};

/**
 * Get leaderboard for a specific category or region
 * @route GET /api/v1/volunteer-credits/leaderboard/category/:category
 * @access Public
 */
export const getLeaderboardByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const skip = parseInt(req.query.skip) || 0;

    // Get leaderboard for specific category/region
    const leaderboard = await User.aggregate([
      {
        $match: {
          role: 'user',
          'location.country': category, // Can be customized based on your needs
        },
      },
      {
        $sort: { totalPoints: -1, totalVolunteerHours: -1 },
      },
      {
        $skip: skip,
      },
      {
        $limit: limit,
      },
      {
        $project: {
          _id: 1,
          name: 1,
          email: 1,
          profileImage: 1,
          location: 1,
          totalCreditHours: '$totalVolunteerHours',
          totalPoints: 1,
          rating: 1,
        },
      },
    ]);

    // Add rank numbers
    const leaderboardWithRank = leaderboard.map((user, index) => ({
      ...user,
      rank: skip + index + 1,
    }));

    // Get total count
    const totalUsers = await User.countDocuments({
      role: 'user',
      'location.country': category,
    });

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        category,
        leaderboard: leaderboardWithRank,
        pagination: {
          currentPage: Math.floor(skip / limit) + 1,
          pageSize: limit,
          totalUsers,
          totalPages: Math.ceil(totalUsers / limit),
          hasMore: skip + limit < totalUsers,
        },
      },
    });
  } catch (error) {
    console.error('Error fetching category leaderboard:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching leaderboard',
    });
  }
};

/**
 * Get user's credit history
 * @route GET /api/v1/volunteer-credits/history/:userId
 * @access Public
 */
export const getCreditHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    const limit = parseInt(req.query.limit) || 50;
    const skip = parseInt(req.query.skip) || 0;

    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const history = await VolunteerCreditHours.find({ user: userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await VolunteerCreditHours.countDocuments({ user: userId });

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        userId,
        userName: user.name,
        history,
        pagination: {
          currentPage: Math.floor(skip / limit) + 1,
          pageSize: limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    console.error('Error fetching credit history:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching credit history',
    });
  }
};

/**
 * Get my credit history (authenticated user)
 * @route GET /api/v1/volunteer-credits/my-history
 * @access Private
 */
export const getMyCreditHistory = async (req, res) => {
  try {
    const userId = req.user._id;
    const limit = parseInt(req.query.limit) || 50;
    const skip = parseInt(req.query.skip) || 0;

    const history = await VolunteerCreditHours.find({ user: userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await VolunteerCreditHours.countDocuments({
      user: userId,
    });

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        userId,
        userName: req.user.name,
        history,
        pagination: {
          currentPage: Math.floor(skip / limit) + 1,
          pageSize: limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    console.error('Error fetching my credit history:', error);
    res.status(error.statusCode || StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message || 'Error fetching credit history',
    });
  }
};
