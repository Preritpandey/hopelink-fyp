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
    ref: 'Category', // Assuming there is a Category model, otherwise String
    required: true
  },
  images: [{
    url: { type: String, required: true },
    publicId: { type: String },
    altText: String
  }],
  isActive: {
    type: Boolean,
    default: true
  },
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
  // toJSON: { 
  //   virtuals: true,
  //   transform: function(doc, ret) {
  //     if (ret.images && Array.isArray(ret.images)) {
  //       ret.images = ret.images.map(img => img.url);
  //     }
  //     delete ret.createdAt;
  //     delete ret.updatedAt;
  //     delete ret.__v;
  //     return ret;
  //   }
  // },
// Update the toJSON transform in product.model.js
// In product.model.js, update the toJSON transform to this:
toJSON: { 
  virtuals: true,
  transform: function(doc, ret) {
    // First, handle the populated organization data

    
    // Transform images array if needed
    if (ret.images && Array.isArray(ret.images)) {
      ret.images = ret.images.map(img => img.url || img); // Handle both object and string URLs
    }
    
    // Clean up fields
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
    // Add randomness to ensure uniqueness if needed, or handle duplicate error in controller
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

const Product = mongoose.model('Product', productSchema);

export default Product;
