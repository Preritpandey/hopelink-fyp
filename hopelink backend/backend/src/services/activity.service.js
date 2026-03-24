import UserActivity from '../models/userActivity.model.js';

export const logUserActivity = async ({
  user,
  activityType,
  resourceType,
  resourceId,
  metadata = {},
}) => {
  try {
    if (!user) return null;

    return await UserActivity.create({
      user,
      activityType,
      resourceType,
      resourceId,
      metadata,
    });
  } catch (error) {
    console.error('[Activity] Failed to log user activity:', error);
    return null;
  }
};

export default {
  logUserActivity,
};
