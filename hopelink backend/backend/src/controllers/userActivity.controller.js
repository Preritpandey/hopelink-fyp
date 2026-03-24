import { StatusCodes } from 'http-status-codes';
import mongoose from 'mongoose';
import UserActivity from '../models/userActivity.model.js';
import { BadRequestError, UnauthorizedError } from '../errors/index.js';

export const getUserActivities = async (req, res) => {
  const { userId } = req.params;
  const { type, page = 1, limit = 20 } = req.query;

  if (!mongoose.Types.ObjectId.isValid(userId)) {
    throw new BadRequestError('Invalid user id');
  }

  if (req.user.role !== 'admin' && req.user._id.toString() !== userId) {
    throw new UnauthorizedError('Not authorized to view this activity');
  }

  const query = { user: userId };
  if (type) {
    query.activityType = type;
  }

  const activities = await UserActivity.find(query)
    .sort({ createdAt: -1 })
    .skip((Number(page) - 1) * Number(limit))
    .limit(Number(limit));

  const total = await UserActivity.countDocuments(query);

  return res.status(StatusCodes.OK).json({
    success: true,
    count: activities.length,
    total,
    page: Number(page),
    pages: Math.ceil(total / Number(limit)),
    data: activities,
  });
};

export const getMyActivities = async (req, res) => {
  req.params.userId = req.user._id.toString();
  return getUserActivities(req, res);
};

export default {
  getUserActivities,
  getMyActivities,
};
