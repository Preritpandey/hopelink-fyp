import mongoose from 'mongoose';

const productVariantSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
    index: true
  },
  attributes: {
    type: Map,
    of: String,
    required: true,
    // Example: { "size": "L", "color": "Red", "material": "Cotton" }
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  sku: {
    type: String,
    required: true,
    unique: true
  },
  stock: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isDeleted: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      delete ret.createdAt;
      delete ret.updatedAt;
      delete ret.__v;
      return ret;
    }
  }
});

// Compound index to ensure unique combination of attributes per product? 
// Attributes are a Map, so standard index might be tricky. 
// Application logic should probably enforce uniqueness of variant configurations for a product.

// Register the model with Mongoose, but don't overwrite existing model to prevent re-registration
const ProductVariant = mongoose.models.ProductVariant || mongoose.model('ProductVariant', productVariantSchema);

export default ProductVariant;
