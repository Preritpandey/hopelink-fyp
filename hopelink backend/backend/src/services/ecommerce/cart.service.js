import Cart from '../../models/ecommerce/cart.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Product from '../../models/ecommerce/product.model.js';

export const getCart = async (userId) => {
  let cart = await Cart.findOne({ userId })
    .populate({
      path: 'items.productId',
      model: Product
    })
    .populate({
      path: 'items.variantId',
      model: ProductVariant
    });
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
  }
  return cart;
};

export const addToCart = async (userId, productId, variantId, quantity) => {
  const variant = await ProductVariant.findById(variantId);
  if (!variant) throw new Error('Variant not found');
  if (variant.stock < quantity) throw new Error('Insufficient stock');
  
  let cart = await Cart.findOne({ userId });
  if (!cart) {
    cart = new Cart({ userId, items: [] });
  }

  const itemIndex = cart.items.findIndex(p => p.variantId.toString() === variantId.toString());
  if (itemIndex > -1) {
    cart.items[itemIndex].quantity += quantity;
  } else {
    cart.items.push({ 
      productId, 
      variantId, 
      quantity,
      priceSnapshot: variant.price 
    });
  }
  
  return await cart.save();
};

export const updateCartItem = async (userId, variantId, quantity) => {
  const cart = await Cart.findOne({ userId });
  if (!cart) throw new Error('Cart not found');
  
  const itemIndex = cart.items.findIndex(p => p.variantId.toString() === variantId.toString());
  
  if (quantity <= 0) {
    // Remove functionality if quantity is 0 or less
    if (itemIndex > -1) {
      cart.items.splice(itemIndex, 1);
    }
  } else {
    if (itemIndex > -1) {
        // Check stock
        const variant = await ProductVariant.findById(variantId);
        if (variant.stock < quantity) throw new Error('Insufficient stock');
        cart.items[itemIndex].quantity = quantity;
    }
  }
  return await cart.save();
};

export const removeFromCart = async (userId, variantId) => {
  const cart = await Cart.findOne({ userId });
  if (!cart) return null;
  
  cart.items = cart.items.filter(item => item.variantId.toString() !== variantId.toString());
  return await cart.save();
};
