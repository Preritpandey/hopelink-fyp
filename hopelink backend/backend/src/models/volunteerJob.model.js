import mongoose from 'mongoose';

const volunteerJobSchema = new mongoose.Schema(
  {
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
    },
    organizationName: {
      type: String,
      required: true,
      trim: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      required: true,
      trim: true,
    },
    requiredSkills: [
      {
        type: String,
        trim: true,
      },
    ],
    location: {
      address: { type: String, trim: true },
      city: { type: String, trim: true },
      state: { type: String, trim: true },
      coordinates: {
        type: { type: String, default: 'Point' },
        coordinates: {
          type: [Number],
          default: [0, 0],
        },
      },
    },
    positionsAvailable: {
      type: Number,
      required: true,
      min: 1,
    },
    positionsFilled: {
      type: Number,
      default: 0,
      min: 0,
    },
    applicationDeadline: {
      type: Date,
      required: true,
    },
    jobType: {
      type: String,
      enum: ['onsite', 'remote', 'hybrid'],
      default: 'onsite',
    },
    certificateProvided: {
      type: Boolean,
      default: false,
    },
    creditHours: {
      type: Number,
      default: 0,
      min: 0,
    },
    status: {
      type: String,
      enum: ['open', 'closed'],
      default: 'open',
    },
  },
  { timestamps: true },
);

volunteerJobSchema.index({ organization: 1 });
volunteerJobSchema.index({ status: 1, applicationDeadline: 1 });
volunteerJobSchema.index({ category: 1, 'location.city': 1, jobType: 1 });
volunteerJobSchema.index({ title: 'text', description: 'text', category: 'text' });

const VolunteerJob =
  mongoose.models.VolunteerJob ||
  mongoose.model('VolunteerJob', volunteerJobSchema);

export default VolunteerJob;
