import mongoose from 'mongoose';

const essentialRequestItemSchema = new mongoose.Schema(
  {
    itemName: {
      type: String,
      required: [true, 'Please provide an item name'],
      trim: true,
    },
    quantityRequired: {
      type: Number,
      required: [true, 'Please provide the required quantity'],
      min: [1, 'Required quantity must be at least 1'],
    },
    quantityFulfilled: {
      type: Number,
      default: 0,
      min: [0, 'Fulfilled quantity cannot be negative'],
    },
    unit: {
      type: String,
      required: [true, 'Please provide a unit'],
      trim: true,
    },
  },
  { _id: true },
);

const pickupLocationSchema = new mongoose.Schema(
  {
    address: {
      type: String,
      required: [true, 'Please provide a pickup address'],
      trim: true,
    },
    latitude: {
      type: Number,
      required: [true, 'Please provide pickup latitude'],
    },
    longitude: {
      type: Number,
      required: [true, 'Please provide pickup longitude'],
    },
    contactPerson: {
      type: String,
      required: [true, 'Please provide a contact person'],
      trim: true,
    },
    contactPhone: {
      type: String,
      required: [true, 'Please provide a contact phone'],
      trim: true,
    },
    availableTimeSlots: {
      type: String,
      required: [true, 'Please provide available time slots'],
      trim: true,
    },
  },
  { _id: true },
);

const essentialRequestSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Please provide a title'],
      trim: true,
      maxlength: [150, 'Title cannot be more than 150 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [2000, 'Description cannot be more than 2000 characters'],
    },
    category: {
      type: String,
      required: [true, 'Please provide a category'],
      enum: ['food', 'clothes', 'medicine', 'other'],
    },
    itemsNeeded: {
      type: [essentialRequestItemSchema],
      validate: {
        validator: (items) => Array.isArray(items) && items.length > 0,
        message: 'Please provide at least one required item',
      },
    },
    urgencyLevel: {
      type: String,
      required: [true, 'Please provide an urgency level'],
      enum: ['low', 'medium', 'high'],
    },
    expiryDate: {
      type: Date,
      required: [true, 'Please provide an expiry date'],
    },
    pickupLocations: {
      type: [pickupLocationSchema],
      validate: {
        validator: (locations) =>
          Array.isArray(locations) && locations.length > 0,
        message: 'Please provide at least one pickup location',
      },
    },
    images: [
      {
        type: String,
        trim: true,
      },
    ],
    status: {
      type: String,
      enum: ['active', 'fulfilled', 'expired'],
      default: 'active',
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: [true, 'Please provide an organization'],
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

essentialRequestSchema.index({ status: 1, category: 1, urgencyLevel: 1 });
essentialRequestSchema.index({ createdBy: 1, status: 1, createdAt: -1 });
essentialRequestSchema.index({ expiryDate: 1, status: 1 });
essentialRequestSchema.index({ title: 'text', description: 'text' });

essentialRequestSchema.pre('save', function validateExpiry(next) {
  if (this.expiryDate && this.expiryDate <= new Date() && this.status === 'active') {
    this.status = 'expired';
  }

  const hasInvalidFulfillment = this.itemsNeeded?.some(
    (item) => item.quantityFulfilled > item.quantityRequired,
  );

  if (hasInvalidFulfillment) {
    this.invalidate(
      'itemsNeeded',
      'Fulfilled quantity cannot exceed the required quantity',
    );
  }

  return next();
});

const EssentialRequest =
  mongoose.models.EssentialRequest ||
  mongoose.model('EssentialRequest', essentialRequestSchema);

export default EssentialRequest;
