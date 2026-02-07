import mongoose from 'mongoose';

const volunteerCertificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
    },
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'VolunteerJob',
      required: true,
    },
    jobTitle: {
      type: String,
      required: true,
      trim: true,
    },
    organizationName: {
      type: String,
      required: true,
      trim: true,
    },
    issueDate: {
      type: Date,
      default: Date.now,
    },
    certificateUrl: {
      type: String,
      required: true,
      trim: true,
    },
    verificationCode: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    skillsGained: [
      {
        type: String,
        trim: true,
      },
    ],
    duration: {
      type: String,
      trim: true,
    },
  },
  { timestamps: true },
);

volunteerCertificationSchema.index({ user: 1 });
volunteerCertificationSchema.index({ organization: 1 });
volunteerCertificationSchema.index({ job: 1 });

const VolunteerCertification =
  mongoose.models.VolunteerCertification ||
  mongoose.model('VolunteerCertification', volunteerCertificationSchema);

export default VolunteerCertification;
