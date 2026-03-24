import mongoose from 'mongoose';

const userActivitySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    activityType: {
      type: String,
      enum: ['donation', 'volunteer_job_enrollment', 'event_registration'],
      required: [true, 'Activity type is required'],
    },
    resourceType: {
      type: String,
      enum: [
        'Donation',
        'VolunteerApplication',
        'VolunteerEnrollment',
        'Event',
        'VolunteerJob',
        'Campaign',
      ],
      required: [true, 'Resource type is required'],
    },
    resourceId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Resource id is required'],
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

userActivitySchema.index({ user: 1, createdAt: -1 });
userActivitySchema.index({ activityType: 1, createdAt: -1 });
userActivitySchema.index({ resourceType: 1, resourceId: 1 });

let UserActivity;
if (mongoose.models.UserActivity) {
  UserActivity = mongoose.model('UserActivity');
} else {
  UserActivity = mongoose.model('UserActivity', userActivitySchema);
}

export default UserActivity;
