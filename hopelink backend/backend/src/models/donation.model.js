import mongoose from 'mongoose';

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
    paymentMethod: {
      type: String,
      required: [true, 'Please provide a payment method'],
      enum: ['credit_card', 'debit_card', 'paypal', 'bank_transfer', 'crypto', 'other'],
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
        totalAmount: { $sum: '$amount' },
        count: { $sum: 1 }
      }
    }
  ]);

  try {
    await this.model('Campaign').findByIdAndUpdate(campaignId, {
      currentAmount: result[0]?.totalAmount || 0,
      $inc: { donationCount: result[0]?.count || 0 }
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
