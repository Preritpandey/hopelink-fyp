import mongoose from 'mongoose';

const campaignSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Please provide a title for the campaign'],
      trim: true,
      maxlength: [100, 'Title cannot be more than 100 characters'],
    },
    description: {
      type: String,
      required: [true, 'Please provide a description'],
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: [true, 'Please provide an organization'],
    },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Please select a category'],
    },
    targetAmount: {
      type: Number,
      required: [true, 'Please provide a target amount'],
      min: [1, 'Target amount must be at least 1'],
    },
    currentAmount: {
      type: Number,
      default: 0,
    },
    startDate: {
      type: Date,
      required: [true, 'Please provide a start date'],
    },
    endDate: {
      type: Date,
      required: [true, 'Please provide an end date'],
      validate: {
        validator: function (value) {
          return value > this.startDate;
        },
        message: 'End date must be after start date',
      },
    },
    images: [{
      url: String,
      isPrimary: {
        type: Boolean,
        default: false,
      },
    }],
    status: {
      type: String,
      enum: ['draft', 'active', 'completed', 'cancelled'],
      default: 'draft',
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    tags: [{
      type: String,
      trim: true,
    }],
    updates: [{
      title: String,
      description: String,
      date: {
        type: Date,
        default: Date.now,
      },
    }],
    faqs: [{
      question: String,
      answer: String,
    }],
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual for donations
campaignSchema.virtual('donations', {
  ref: 'Donation',
  localField: '_id',
  foreignField: 'campaign',
});

// Calculate progress percentage
campaignSchema.virtual('progress').get(function() {
  return (this.currentAmount / this.targetAmount) * 100;
});

// Check if campaign is active
campaignSchema.virtual('isActive').get(function() {
  const now = new Date();
  return this.status === 'active' && this.startDate <= now && this.endDate >= now;
});

// Indexes
campaignSchema.index({ title: 'text', description: 'text' });

const Campaign = mongoose.model('Campaign', campaignSchema);

export default Campaign;
