import mongoose from 'mongoose';
import Campaign from './campaign.model.js';

const donationSchema = new mongoose.Schema(
  {
    donor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Please provide a donor'],
    },
    campaign: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
      required: [true, 'Please provide a campaign'],
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: [true, 'Please provide an organization'],
    },
    amount: {
      type: Number,
      required: [true, 'Please provide an amount'],
      min: [1, 'Amount must be at least 1'],
    },
    campaignAmount: {
      type: Number,
      min: [1, 'Campaign amount must be at least 1'],
    },
    platformSupportAmount: {
      type: Number,
      default: 0,
      min: [0, 'Platform support amount cannot be negative'],
    },
    totalAmount: {
      type: Number,
      min: [1, 'Total amount must be at least 1'],
    },
    originalAmount: {
      type: Number,
      min: [0, 'Original amount cannot be negative'],
    },
    originalCampaignAmount: {
      type: Number,
      min: [0, 'Original campaign amount cannot be negative'],
    },
    originalPlatformSupportAmount: {
      type: Number,
      default: 0,
      min: [0, 'Original platform support amount cannot be negative'],
    },
    originalTotalAmount: {
      type: Number,
      min: [0, 'Original total amount cannot be negative'],
    },
    originalCurrency: {
      type: String,
      default: 'NPR',
      uppercase: true,
      trim: true,
    },
    exchangeRate: {
      type: Number,
      default: 1,
      min: [0, 'Exchange rate cannot be negative'],
    },
    convertedAmountNpr: {
      type: Number,
      min: [0, 'Converted NPR amount cannot be negative'],
    },
    convertedPlatformSupportAmountNpr: {
      type: Number,
      default: 0,
      min: [0, 'Converted platform support amount cannot be negative'],
    },
    convertedTotalAmountNpr: {
      type: Number,
      min: [0, 'Converted total amount cannot be negative'],
    },
    supportPlatform: {
      type: Boolean,
      default: false,
    },
    paymentMethod: {
      type: String,
      required: [true, 'Please provide a payment method'],
      enum: [
        'credit_card',
        'debit_card',
        'paypal',
        'bank_transfer',
        'crypto',
        'stripe',
        'khalti',
        'other',
      ],
    },
    paymentId: {
      type: String,
      required: [true, 'Please provide a payment ID'],
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed', 'refunded', 'cancelled'],
      default: 'pending',
    },
    isAnonymous: {
      type: Boolean,
      default: false,
    },
    message: {
      type: String,
      maxlength: [500, 'Message cannot be more than 500 characters'],
    },
    receiptSent: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
donationSchema.index({ donor: 1, createdAt: -1 });
donationSchema.index({ campaign: 1, createdAt: -1 });
donationSchema.index({ organization: 1, createdAt: -1 });
donationSchema.index({ supportPlatform: 1, createdAt: -1 });
donationSchema.index(
  { paymentMethod: 1, paymentId: 1 },
  { unique: true }
);

donationSchema.pre('validate', function(next) {
  const campaignAmount = this.campaignAmount ?? this.amount;
  const supportAmount = this.supportPlatform
    ? this.platformSupportAmount || 0
    : 0;

  this.campaignAmount = campaignAmount;
  this.platformSupportAmount = supportAmount;
  this.totalAmount = this.totalAmount ?? campaignAmount + supportAmount;
  this.amount = campaignAmount;
  this.supportPlatform = supportAmount > 0;
  this.originalCurrency = this.originalCurrency || 'NPR';
  this.exchangeRate = this.exchangeRate ?? 1;
  this.originalCampaignAmount = this.originalCampaignAmount ?? campaignAmount;
  this.originalPlatformSupportAmount =
    this.originalPlatformSupportAmount ?? supportAmount;
  this.originalTotalAmount =
    this.originalTotalAmount ?? this.originalCampaignAmount + this.originalPlatformSupportAmount;
  this.originalAmount = this.originalAmount ?? this.originalCampaignAmount;
  this.convertedAmountNpr = this.convertedAmountNpr ?? campaignAmount;
  this.convertedPlatformSupportAmountNpr =
    this.convertedPlatformSupportAmountNpr ?? supportAmount;
  this.convertedTotalAmountNpr =
    this.convertedTotalAmountNpr ?? this.convertedAmountNpr + this.convertedPlatformSupportAmountNpr;

  next();
});

// Static method to get total donations for a campaign
donationSchema.statics.getTotalDonations = async function (campaignId) {
  const result = await this.aggregate([
    {
      $match: { 
        campaign: campaignId,
        status: 'completed' 
      }
    },
    {
      $group: {
        _id: '$campaign',
        totalAmount: {
          $sum: {
            $ifNull: [
              '$convertedAmountNpr',
              { $ifNull: ['$campaignAmount', '$amount'] },
            ],
          },
        },
        count: { $sum: 1 }
      }
    }
  ]);

  try {
    await Campaign.findByIdAndUpdate(campaignId, {
      currentAmount: result[0]?.totalAmount || 0,
      donationsCount: result[0]?.count || 0,
    });
  } catch (error) {
    console.error('Error updating campaign donation stats:', error);
  }
};

// Update campaign stats after save
donationSchema.post('save', function() {
  this.constructor.getTotalDonations(this.campaign);
});

// Update campaign stats after remove
donationSchema.post('remove', function() {
  this.constructor.getTotalDonations(this.campaign);
});

const Donation = mongoose.model('Donation', donationSchema);

export default Donation;
