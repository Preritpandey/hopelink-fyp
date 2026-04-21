import mongoose from 'mongoose';

const productSchema = new mongoose.Schema({
  orgId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Organization',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  slug: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  beneficiaryDescription: {
    type: String,
    required: true,
    description: "Description of the social impact or disabled creators behind this product"
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: true
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  sku: {
    type: String,
    trim: true,
    uppercase: true,
    sparse: true,
    unique: true
  },
  stock: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  lowStockThreshold: {
    type: Number,
    min: 0,
    default: 5
  },
  images: [{
    url: { type: String, required: true },
    publicId: { type: String },
    altText: String
  }],
  stockHistory: [{
    previousStock: { type: Number, min: 0 },
    newStock: { type: Number, required: true, min: 0 },
    note: String,
    source: {
      type: String,
      enum: ['create', 'manual', 'variant-sync', 'restore', 'system'],
      default: 'manual'
    },
    changedAt: {
      type: Date,
      default: Date.now
    }
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  archivedAt: Date,
  isDeleted: {
    type: Boolean,
    default: false,
    index: true
  },
  ratingAverage: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
    set: val => Math.round(val * 10) / 10
  },
  ratingCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true,
  toJSON: { 
  virtuals: true,
  transform: function(doc, ret) {
    if (ret.images && Array.isArray(ret.images)) {
      ret.images = ret.images.map(img => img.url || img);
    }

    ret.averageRating = ret.ratingAverage ?? 0;
    ret.totalReviews = ret.ratingCount ?? 0;
    ret.inStock = (ret.stock ?? 0) > 0;
    ret.lowStock = (ret.stock ?? 0) > 0 && (ret.stock ?? 0) <= (ret.lowStockThreshold ?? 5);

    delete ret.createdAt;
    delete ret.updatedAt;
    delete ret.__v;

    return ret;
  }
},

  toObject: { virtuals: true }
});

// Middleware to slugify name before saving
productSchema.pre('validate', function(next) {
  if (this.name && !this.slug) {
    this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
  }
  next();
});

productSchema.virtual('variants', {
  ref: 'ProductVariant',
  localField: '_id',
  foreignField: 'productId',
  match: { isDeleted: false }
});

productSchema.virtual('reviews', {
  ref: 'Review',
  localField: '_id',
  foreignField: 'productId'
});

productSchema.index({ name: 'text', description: 'text', beneficiaryDescription: 'text' });
productSchema.index({ category: 1, isDeleted: 1, isActive: 1 });
productSchema.index({ price: 1 });
productSchema.index({ stock: 1 });
productSchema.index({ ratingAverage: -1, ratingCount: -1 });

const Product = mongoose.model('Product', productSchema);

export default Product;
