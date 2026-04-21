import mongoose from 'mongoose';

const orderStatusHistorySchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'delivered', 'cancelled'],
    required: true
  },
  changedAt: {
    type: Date,
    default: Date.now
  },
  changedByRole: {
    type: String,
    enum: ['user', 'organization', 'admin', 'system'],
    default: 'system'
  },
  note: String,
  trackingNumber: String,
  reason: String
}, { _id: false });

const orderItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  productName: String, // Snapshot
  productImg: String, // Snapshot
  variantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ProductVariant',
    default: null
  },
  variantAttributes: {
    type: Map,
    of: String
  },
  sku: String,
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  price: { // Unit price at time of purchase
    type: Number,
    required: true
  },
  totalPrice: {
    type: Number,
    required: true
  }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orgId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Organization',
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  // Grouping ID to link split orders together if they were paid in one transaction
  transactionId: {
    type: String,
    index: true
  },
  paymentGateway: {
    type: String,
    enum: ['stripe', 'khalti'],
    required: true
  },
  paymentReference: {
    type: String
  },
  paymentTransactionId: {
    type: String
  },
  items: [orderItemSchema],
  subTotal: {
    type: Number,
    required: true
  },
  shippingFee: {
    type: Number,
    default: 0
  },
  totalAmount: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'delivered', 'cancelled'],
    default: 'pending'
  },
  shippingAddress: {
    fullName: String,
    phone: String,
    street: String,
    city: String,
    state: String,
    postalCode: String,
    country: String
  },
  trackingNumber: String,
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed'],
    default: 'pending'
  },
  paymentVerifiedAt: Date,
  paidAt: Date,
  deliveredAt: Date,
  cancelledAt: Date,
  deliveryNotes: String,
  cancellationReason: String,
  statusHistory: {
    type: [orderStatusHistorySchema],
    default: []
  },
  paymentVerificationData: {
    type: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

const Order = mongoose.model('Order', orderSchema);

export default Order;
