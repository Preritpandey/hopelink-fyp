import mongoose from 'mongoose';

const applicantSnapshotSchema = new mongoose.Schema(
  {
    fullName: { type: String, trim: true },
    email: { type: String, trim: true },
    profileImage: { type: String, trim: true },
    bio: { type: String, trim: true },
    skills: [{ type: String, trim: true }],
    certifications: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'VolunteerCertification',
      },
    ],
    totalVolunteerHours: { type: Number, default: 0 },
    rating: { type: Number, default: 0 },
  },
  { _id: false },
);

const volunteerApplicationSchema = new mongoose.Schema(
  {
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'VolunteerJob',
      required: true,
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    rejectionReason: {
      type: String,
      trim: true,
    },
    resumePath: {
      type: String,
      required: true,
    },
    resumeOriginalName: {
      type: String,
      trim: true,
    },
    whyHire: {
      type: String,
      required: true,
      trim: true,
    },
    skills: [
      {
        type: String,
        trim: true,
      },
    ],
    experience: {
      type: String,
      trim: true,
    },
    applicantSnapshot: {
      type: applicantSnapshotSchema,
      required: true,
    },
    approvedAt: Date,
    rejectedAt: Date,
    creditHoursGranted: {
      type: Number,
      default: 0,
    },
    creditGrantedAt: Date,
  },
  { timestamps: true },
);

volunteerApplicationSchema.index({ job: 1, user: 1 }, { unique: true });
volunteerApplicationSchema.index({ job: 1, status: 1 });
volunteerApplicationSchema.index({ organization: 1, status: 1 });
volunteerApplicationSchema.index({ user: 1, status: 1 });

const VolunteerApplication =
  mongoose.models.VolunteerApplication ||
  mongoose.model('VolunteerApplication', volunteerApplicationSchema);

export default VolunteerApplication;
