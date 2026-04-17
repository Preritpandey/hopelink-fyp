import mongoose from 'mongoose';

const volunteerCreditHoursSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    creditHours: {
      type: Number,
      required: [true, 'Credit hours are required'],
      min: [0, 'Credit hours cannot be negative'],
    },
    source: {
      type: String,
      enum: [
        'volunteer_application',
        'volunteer_enrollment',
        'event_participation',
        'manual_grant'
      ],
      required: [true, 'Source is required'],
    },
    sourceId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Source ID is required'],
    },
    sourceModel: {
      type: String,
      enum: ['VolunteerApplication', 'VolunteerEnrollment', 'Event', 'Organization'],
      required: [true, 'Source model is required'],
    },
    description: {
      type: String,
      trim: true,
    },
    isApplied: {
      type: Boolean,
      default: false,
      index: true,
    },
    appliedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    indexes: [
      { user: 1, createdAt: -1 },
      { user: 1, isApplied: 1 },
      { source: 1, sourceId: 1 },
    ],
  }
);

// Compound index to ensure uniqueness per source
volunteerCreditHoursSchema.index(
  { user: 1, source: 1, sourceId: 1 },
  { unique: true }
);

let VolunteerCreditHours;
if (mongoose.models.VolunteerCreditHours) {
  VolunteerCreditHours = mongoose.model('VolunteerCreditHours');
} else {
  VolunteerCreditHours = mongoose.model(
    'VolunteerCreditHours',
    volunteerCreditHoursSchema
  );
}

export default VolunteerCreditHours;
