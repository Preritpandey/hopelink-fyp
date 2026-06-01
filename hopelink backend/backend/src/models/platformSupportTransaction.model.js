import mongoose from 'mongoose';

const platformSupportTransactionSchema = new mongoose.Schema(
  {
    donation: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Donation',
      required: true,
      unique: true,
    },
    donor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    campaign: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
      required: true,
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [1, 'Platform support amount must be at least 1'],
    },
    paymentMethod: {
      type: String,
      required: true,
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
      required: true,
    },
    status: {
      type: String,
      enum: ['completed', 'refunded'],
      default: 'completed',
    },
  },
  {
    timestamps: true,
  },
);

platformSupportTransactionSchema.index({ donor: 1, createdAt: -1 });
platformSupportTransactionSchema.index({ campaign: 1, createdAt: -1 });
platformSupportTransactionSchema.index({ createdAt: -1 });

const PlatformSupportTransaction = mongoose.model(
  'PlatformSupportTransaction',
  platformSupportTransactionSchema,
);

export default PlatformSupportTransaction;
