import mongoose from 'mongoose';

const reportFileSchema = new mongoose.Schema(
  {
    localPath: {
      type: String,
      required: [true, 'Report file path is required'],
    },
    originalName: {
      type: String,
    },
    mimeType: {
      type: String,
      default: 'application/pdf',
    },
    size: {
      type: Number,
    },
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const campaignReportSchema = new mongoose.Schema(
  {
    campaign: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
      required: [true, 'Campaign is required'],
      unique: true,
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: [true, 'Organization is required'],
    },
    reportFile: {
      type: reportFileSchema,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    submittedAt: {
      type: Date,
      default: Date.now,
    },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewedAt: {
      type: Date,
      default: null,
    },
    rejectionReason: {
      type: String,
      trim: true,
      maxlength: [500, 'Rejection reason cannot exceed 500 characters'],
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

campaignReportSchema.index({ campaign: 1 });
campaignReportSchema.index({ organization: 1 });
campaignReportSchema.index({ status: 1 });

const CampaignReport = mongoose.model('CampaignReport', campaignReportSchema);

export default CampaignReport;
