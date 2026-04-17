// INTEGRATION GUIDE: Volunteer Credits System
// This file shows how to integrate the volunteer credits system with existing controllers

// ============================================================================
// 1. INTEGRATING WITH VOLUNTEER APPLICATION APPROVAL
// ============================================================================
// File: src/controllers/volunteerApplication.controller.js

import { updateUserPoints } from './volunteerCredits.controller.js';
import VolunteerCreditHours from '../models/volunteerCreditHours.model.js';

/*
 * Example: Update your existing approveApplication controller
 * to grant credits when an application is approved
 */
export const approveApplicationWithCredits = async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { creditHours } = req.body; // Organization specifies credits to award

    // Existing approval logic...
    const application = await VolunteerApplication.findByIdAndUpdate(
      applicationId,
      {
        status: 'approved',
        approvedAt: new Date(),
      },
      { new: true }
    );

    // NEW: Grant credits if specified
    if (creditHours && creditHours > 0) {
      const creditEntry = await VolunteerCreditHours.create({
        user: application.user,
        creditHours,
        source: 'volunteer_application',
        sourceId: applicationId,
        sourceModel: 'VolunteerApplication',
        description: `Approved volunteer application for job position`,
        isApplied: true,
        appliedAt: new Date(),
      });

      // Update user's total points
      const updatedUser = await updateUserPoints(application.user);

      // Optionally notify user of point increase
      // await notifyUserOfNewPoints(application.user, updatedUser.totalPoints);
    }

    res.status(StatusCodes.OK).json({
      success: true,
      application,
      creditsGranted: creditHours || 0,
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// 2. INTEGRATING WITH EVENT ENROLLMENT - MARK ATTENDANCE
// ============================================================================
// File: src/controllers/volunteerEnrollment.controller.js

import { updateUserPoints } from './volunteerCredits.controller.js';
import VolunteerCreditHours from '../models/volunteerCreditHours.model.js';
import Event from '../models/event.model.js';

/*
 * Example: Mark user attendance at event and award credits
 */
export const markAttendanceAndGrantCredits = async (req, res) => {
  try {
    const { enrollmentId } = req.params;

    // Get enrollment and event details
    const enrollment = await VolunteerEnrollment.findById(enrollmentId);
    const event = await Event.findById(enrollment.event);

    if (!enrollment) {
      throw new NotFoundError('Enrollment not found');
    }

    // Update enrollment status to attended
    enrollment.status = 'attended';
    enrollment.attendance = true;
    await enrollment.save();

    // NEW: Grant credits equal to event's creditHours
    const creditHours = event.creditHours || 4; // Default 4 hours if not specified

    const creditEntry = await VolunteerCreditHours.create({
      user: enrollment.user,
      creditHours,
      source: 'volunteer_enrollment',
      sourceId: enrollmentId,
      sourceModel: 'VolunteerEnrollment',
      description: `Attended event: "${event.title}"`,
      isApplied: true,
      appliedAt: new Date(),
    });

    // Update user's total points
    const updatedUser = await updateUserPoints(enrollment.user);

    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Attendance marked and credits granted',
      enrollment,
      creditsGranted: creditHours,
      userNewPoints: updatedUser.totalPoints,
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// 3. INTEGRATING WITH USER PROFILE API
// ============================================================================
// File: src/controllers/profile.controller.js

import {
  aggregateUserCreditHours,
  calculatePointsFromHours,
} from './volunteerCredits.controller.js';

/*
 * Example: Enhanced getUserProfile to include volunteer stats
 */
export const getUserProfileWithVolunteerStats = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select(
      'name email profileImage location totalVolunteerHours totalPoints rating bio skills'
    );

    if (!user) {
      throw new NotFoundError('User not found');
    }

    // NEW: Get real-time credit aggregation
    const totalCreditHours = await aggregateUserCreditHours(userId);
    const totalPoints = calculatePointsFromHours(totalCreditHours);

    res.status(StatusCodes.OK).json({
      success: true,
      user: {
        ...user.toObject(),
        volunteerStats: {
          totalCreditHours,
          totalPoints,
          pointsPerHour: 4,
          contributionLevel: getContributionLevel(totalPoints), // Helper function
        },
      },
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message,
    });
  }
};

// Helper function to determine contribution level based on points
const getContributionLevel = (points) => {
  if (points >= 100) return 'Platinum';
  if (points >= 75) return 'Gold';
  if (points >= 50) return 'Silver';
  if (points >= 25) return 'Bronze';
  if (points >= 10) return 'Active';
  return 'Beginner';
};

// ============================================================================
// 4. INTEGRATING WITH ORGANIZATION DASHBOARD
// ============================================================================
// File: src/controllers/organization.controller.js

import { aggregateUserCreditHours } from './volunteerCredits.controller.js';
import VolunteerCreditHours from '../models/volunteerCreditHours.model.js';

/*
 * Example: Dashboard to show organization's volunteer impact
 */
export const getOrganizationVolunteerImpact = async (req, res) => {
  try {
    const { organizationId } = req.params;

    // Get all applications approved by this organization
    const approvedApplications = await VolunteerApplication.find({
      organization: organizationId,
      status: 'approved',
    }).populate('user', 'name email');

    // Get all credit hours granted through this organization
    const creditsBatch = await VolunteerCreditHours.aggregate([
      {
        $match: {
          source: 'volunteer_application',
        },
      },
      {
        $lookup: {
          from: 'volunteerapplications',
          localField: 'sourceId',
          foreignField: '_id',
          as: 'application',
        },
      },
      {
        $match: {
          'application.organization': organizationId,
        },
      },
      {
        $group: {
          _id: '$user',
          totalCredits: { $sum: '$creditHours' },
          count: { $sum: 1 },
        },
      },
    ]);

    const totalCreditsGranted = creditsBatch.reduce(
      (sum, batch) => sum + batch.totalCredits,
      0
    );
    const totalVolunteerCount = approvedApplications.length;

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        organizationId,
        volunteerImpact: {
          totalVolunteers: totalVolunteerCount,
          totalCreditsGranted,
          averageCreditsPerVolunteer:
            totalVolunteerCount > 0 ? totalCreditsGranted / totalVolunteerCount : 0,
          uniqueVolunteersImpacted: creditsBatch.length,
          creditsByVolunteer: creditsBatch,
        },
      },
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// 5. BATCH IMPORT HISTORICAL CREDITS
// ============================================================================
// File: src/utils/credits.utils.js

import VolunteerCreditHours from '../models/volunteerCreditHours.model.js';
import { updateUserPoints } from '../controllers/volunteerCredits.controller.js';

/**
 * Bulk import credits for past volunteer activities
 * Useful when migrating data or importing historical records
 *
 * @param {Array} creditsData - Array of credit objects
 * @returns {Promise<Object>} Import results
 *
 * Example creditsData format:
 * [
 *   {
 *     userId: "user_id",
 *     creditHours: 8,
 *     source: "volunteer_application",
 *     sourceId: "app_id",
 *     sourceModel: "VolunteerApplication",
 *     description: "Past volunteer work",
 *     appliedAt: "2024-01-15T10:00:00Z"
 *   },
 *   ...
 * ]
 */
export const bulkImportCredits = async (creditsData) => {
  const results = {
    imported: 0,
    failed: 0,
    duplicates: 0,
    errors: [],
  };

  try {
    for (const credit of creditsData) {
      try {
        // Check for duplicate
        const existing = await VolunteerCreditHours.findOne({
          user: credit.userId,
          source: credit.source,
          sourceId: credit.sourceId,
        });

        if (existing) {
          results.duplicates++;
          continue;
        }

        // Create credit entry
        const creditEntry = await VolunteerCreditHours.create({
          user: credit.userId,
          creditHours: credit.creditHours,
          source: credit.source,
          sourceId: credit.sourceId,
          sourceModel: credit.sourceModel,
          description: credit.description,
          isApplied: true,
          appliedAt: credit.appliedAt || new Date(),
        });

        results.imported++;

        // Update user points
        await updateUserPoints(credit.userId);
      } catch (error) {
        results.failed++;
        results.errors.push({
          credit: credit.sourceId,
          error: error.message,
        });
      }
    }
  } catch (error) {
    console.error('Bulk import error:', error);
    throw error;
  }

  return results;
};

// ============================================================================
// 6. ROUTE INTEGRATION EXAMPLE
// ============================================================================
// File: src/routes/volunteerApplication.routes.js

import express from 'express';
import { approveApplicationWithCredits } from '../controllers/volunteerApplication.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Enhanced approve endpoint that grants credits
 * Request body should include creditHours
 */
router.put(
  '/:applicationId/approve',
  authenticate,
  approveApplicationWithCredits
);

export default router;

// ============================================================================
// 7. CRON JOB FOR AUTOMATIC CREDIT UPDATES (Optional)
// ============================================================================
// File: src/services/cron.service.js

import cron from 'node-cron';
import User from '../models/user.model.js';
import { aggregateUserCreditHours, calculatePointsFromHours } from '../controllers/volunteerCredits.controller.js';

/**
 * Daily job to ensure all user points are up-to-date
 * Runs at 2 AM daily
 */
export const startCreditUpdateCron = () => {
  cron.schedule('0 2 * * *', async () => {
    try {
      console.log('Starting daily credit update job...');

      const users = await User.find({ role: 'user' });

      let updated = 0;
      let errors = 0;

      for (const user of users) {
        try {
          const totalHours = await aggregateUserCreditHours(user._id);
          const totalPoints = calculatePointsFromHours(totalHours);

          const changed =
            user.totalVolunteerHours !== totalHours || user.totalPoints !== totalPoints;

          if (changed) {
            await User.updateOne(
              { _id: user._id },
              {
                totalVolunteerHours: totalHours,
                totalPoints: totalPoints,
              }
            );
            updated++;
          }
        } catch (error) {
          console.error(`Error updating user ${user._id}:`, error);
          errors++;
        }
      }

      console.log(
        `Credit update completed: ${updated} updated, ${errors} errors`
      );
    } catch (error) {
      console.error('Cron job error:', error);
    }
  });
};

// ============================================================================
// 8. NOTIFICATION SERVICE (Optional)
// ============================================================================
// File: src/services/notification.service.js

/**
 * Notify user when they reach point milestones
 */
export const notifyPointMilestone = async (userId, newPoints) => {
  const milestones = [10, 25, 50, 75, 100, 150, 200];

  for (const milestone of milestones) {
    if (newPoints >= milestone && (newPoints - Math.floor(newPoints / 5) * 5) === 0) {
      // User just reached this milestone
      await sendNotification(userId, {
        title: '🎉 Milestone Reached!',
        message: `You've earned ${milestone} volunteer points! Great work!`,
        type: 'milestone',
        points: milestone,
      });
    }
  }
};

export const sendNotification = async (userId, notification) => {
  // Implement your notification logic here
  // Could be email, push notification, in-app notification, etc.
  console.log(`Notification for user ${userId}:`, notification);
};

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
 * EXAMPLE 1: Grant credits when approving application
 * ───────────────────────────────────────────────────
 * POST /api/v1/volunteer-applications/APP_ID/approve
 * Body: {
 *   "creditHours": 8
 * }
 *
 * EXAMPLE 2: Mark attendance and award credits
 * ──────────────────────────────────────────
 * POST /api/v1/volunteer-enrollments/ENROLL_ID/mark-attendance
 * No body needed - credits are awarded automatically based on event duration
 *
 * EXAMPLE 3: View user volunteer stats
 * ──────────────────────────────────
 * GET /api/v1/users/USER_ID/volunteer-profile
 * Returns: totalCredits, totalPoints, contributionLevel
 *
 * EXAMPLE 4: View global leaderboard
 * ──────────────────────────────────
 * GET /api/v1/volunteer-credits/leaderboard?limit=20
 * Returns: Top 20 volunteers by points
 *
 * EXAMPLE 5: Bulk import historical credits
 * ──────────────────────────────────────────
 * Import data from spreadsheet/database:
 * await bulkImportCredits([
 *   { userId, creditHours, source, sourceId, sourceModel }
 * ]);
 */
