import mongoose from 'mongoose';

const donatedItemSchema = new mongoose.Schema(
  {
    itemName: {
      type: String,
      required: [true, 'Please provide an item name'],
      trim: true,
    },
    quantity: {
      type: Number,
      required: [true, 'Please provide a quantity'],
      min: [1, 'Quantity must be at least 1'],
    },
  },
  { _id: false },
);

const donationCommitmentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Please provide a user'],
    },
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'EssentialRequest',
      required: [true, 'Please provide a request'],
    },
    itemsDonating: {
      type: [donatedItemSchema],
      validate: {
        validator: (items) => Array.isArray(items) && items.length > 0,
        message: 'Please provide at least one item to donate',
      },
    },
    selectedPickupLocationId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Please provide a pickup location'],
    },
    status: {
      type: String,
      enum: ['pledged', 'delivered', 'verified', 'rejected'],
      default: 'pledged',
    },
    deliveryDate: {
      type: Date,
    },
    proofImage: {
      type: String,
      trim: true,
    },
    fulfillmentApplied: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  },
);

donationCommitmentSchema.index({ userId: 1, createdAt: -1 });
donationCommitmentSchema.index({ requestId: 1, status: 1, createdAt: -1 });
donationCommitmentSchema.index({ selectedPickupLocationId: 1 });

const DonationCommitment =
  mongoose.models.DonationCommitment ||
  mongoose.model('DonationCommitment', donationCommitmentSchema);

export default DonationCommitment;
