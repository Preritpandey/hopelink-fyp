import express from 'express';
import {
  grantCreditsFromApplication,
  grantCreditsFromEnrollment,
  getUserCreditsAndPoints,
  getMyCreditsAndPoints,
  getLeaderboard,
  getLeaderboardByCategory,
  getCreditHistory,
  getMyCreditHistory,
} from '../controllers/volunteerCredits.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/volunteer-credits/grant/application/{applicationId}:
 *   post:
 *     summary: Grant credit hours from a volunteer application
 *     tags: [Volunteer Credits]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: applicationId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - creditHours
 *             properties:
 *               creditHours:
 *                 type: number
 *                 example: 8
 *               description:
 *                 type: string
 *                 example: "Volunteer work at community center"
 *     responses:
 *       201:
 *         description: Credit hours granted successfully
 */
router.post(
  '/grant/application/:applicationId',
  authenticate,
  grantCreditsFromApplication
);

/**
 * @swagger
 * /api/v1/volunteer-credits/grant/enrollment/{enrollmentId}:
 *   post:
 *     summary: Grant credit hours from a volunteer enrollment
 *     tags: [Volunteer Credits]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: enrollmentId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - creditHours
 *             properties:
 *               creditHours:
 *                 type: number
 *                 example: 4
 *               description:
 *                 type: string
 *                 example: "Event participation"
 *     responses:
 *       201:
 *         description: Credit hours granted successfully
 */
router.post(
  '/grant/enrollment/:enrollmentId',
  authenticate,
  grantCreditsFromEnrollment
);

/**
 * @swagger
 * /api/v1/volunteer-credits/me:
 *   get:
 *     summary: Get my credit hours and points
 *     tags: [Volunteer Credits]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's credit hours and points
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                     userName:
 *                       type: string
 *                     userEmail:
 *                       type: string
 *                     totalCreditHours:
 *                       type: number
 *                     totalPoints:
 *                       type: number
 *                     pointsPerHour:
 *                       type: number
 */
router.get('/me', authenticate, getMyCreditsAndPoints);

/**
 * @swagger
 * /api/v1/volunteer-credits/user/{userId}:
 *   get:
 *     summary: Get user's credit hours and points
 *     tags: [Volunteer Credits]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: User's credit hours and points
 */
router.get('/user/:userId', getUserCreditsAndPoints);

/**
 * @swagger
 * /api/v1/volunteer-credits/leaderboard:
 *   get:
 *     summary: Get leaderboard of top users by points
 *     tags: [Volunteer Credits]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Top users leaderboard
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     leaderboard:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           rank:
 *                             type: number
 *                           name:
 *                             type: string
 *                           email:
 *                             type: string
 *                           totalPoints:
 *                             type: number
 *                           totalCreditHours:
 *                             type: number
 *                           profileImage:
 *                             type: string
 */
router.get('/leaderboard', getLeaderboard);

/**
 * @swagger
 * /api/v1/volunteer-credits/leaderboard/category/{category}:
 *   get:
 *     summary: Get leaderboard for a specific category
 *     tags: [Volunteer Credits]
 *     parameters:
 *       - in: path
 *         name: category
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Category leaderboard
 */
router.get('/leaderboard/category/:category', getLeaderboardByCategory);

/**
 * @swagger
 * /api/v1/volunteer-credits/my-history:
 *   get:
 *     summary: Get my credit history
 *     tags: [Volunteer Credits]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: User's credit history
 */
router.get('/my-history', authenticate, getMyCreditHistory);

/**
 * @swagger
 * /api/v1/volunteer-credits/history/{userId}:
 *   get:
 *     summary: Get user's credit history
 *     tags: [Volunteer Credits]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: User's credit history
 */
router.get('/history/:userId', getCreditHistory);

export default router;
