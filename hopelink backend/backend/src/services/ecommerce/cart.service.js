import Cart from '../../models/ecommerce/cart.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Product from '../../models/ecommerce/product.model.js';
import { BadRequestError, NotFoundError } from '../../errors/index.js';

const buildCartQuery = (userId) =>
  Cart.findOne({ userId })
    .populate({
      path: 'items.productId',
      model: Product,
      populate: {
        path: 'category',
        select: 'name slug',
      },
    })
    .populate({
      path: 'items.variantId',
      model: ProductVariant,
    });

const hydrateCart = (cart) => {
  const plainCart = cart.toObject();
  const subTotal = plainCart.items.reduce(
    (sum, item) => sum + item.priceSnapshot * item.quantity,
    0,
  );

  return {
    ...plainCart,
    itemCount: plainCart.items.reduce((sum, item) => sum + item.quantity, 0),
    subTotal,
  };
};

const resolveCartItem = (cart, itemIdOrVariantId) => {
  let item = cart.items.id(itemIdOrVariantId);
  if (item) {
    return item;
  }

  return (
    cart.items.find(
      (cartItem) => String(cartItem.variantId || '') === String(itemIdOrVariantId || ''),
    ) || null
  );
};

const getCartItemInventorySnapshot = async ({ productId, variantId }) => {
  const product = await Product.findOne({
    _id: productId,
    isDeleted: false,
    isActive: true,
  });

  if (!product) {
    throw new NotFoundError('Product not found');
  }

  if (product.stock <= 0) {
    throw new BadRequestError('This product is currently out of stock');
  }

  if (variantId) {
    const variant = await ProductVariant.findOne({
      _id: variantId,
      productId,
      isDeleted: false,
      isActive: true,
    });

    if (!variant) {
      throw new NotFoundError('Product variant not found');
    }

    if (variant.stock <= 0) {
      throw new BadRequestError('This product variant is currently out of stock');
    }

    return {
      product,
      variant,
      availableStock: Math.min(product.stock, variant.stock),
      price: variant.price,
    };
  }

  return {
    product,
    variant: null,
    availableStock: product.stock,
    price: product.price,
  };
};

export const getCart = async (userId) => {
  let cart = await buildCartQuery(userId);
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
    cart = await buildCartQuery(userId);
  }

  return hydrateCart(cart);
};

export const addToCart = async (userId, { productId, variantId, quantity }) => {
  const parsedQuantity = Number(quantity);
  if (!Number.isInteger(parsedQuantity) || parsedQuantity < 1) {
    throw new BadRequestError('Quantity must be a positive integer');
  }

  const { product, variant, availableStock, price } =
    await getCartItemInventorySnapshot({ productId, variantId });

  let cart = await Cart.findOne({ userId });
  if (!cart) {
    cart = new Cart({ userId, items: [] });
  }

  const itemIndex = cart.items.findIndex(
    (item) =>
      item.productId.toString() === productId.toString() &&
      String(item.variantId || '') === String(variantId || ''),
  );

  if (itemIndex > -1) {
    const nextQuantity = cart.items[itemIndex].quantity + parsedQuantity;
    if (nextQuantity > availableStock) {
      throw new BadRequestError('Insufficient stock for requested quantity');
    }

    cart.items[itemIndex].quantity = nextQuantity;
    cart.items[itemIndex].priceSnapshot = price;
  } else {
    if (parsedQuantity > availableStock) {
      throw new BadRequestError('Insufficient stock for requested quantity');
    }

    cart.items.push({
      productId,
      variantId: variant?._id || null,
      quantity: parsedQuantity,
      priceSnapshot: price,
      productNameSnapshot: product.name,
      productImageSnapshot: product.images?.[0]?.url || '',
    });
  }

  await cart.save();
  return getCart(userId);
};

export const updateCartItem = async (userId, itemIdOrVariantId, quantity) => {
  const parsedQuantity = Number(quantity);
  if (!Number.isInteger(parsedQuantity) || parsedQuantity < 1) {
    throw new BadRequestError('Quantity must be a positive integer');
  }

  const cart = await Cart.findOne({ userId });
  if (!cart) {
    throw new NotFoundError('Cart not found');
  }

  const item = resolveCartItem(cart, itemIdOrVariantId);
  if (!item) {
    throw new NotFoundError('Cart item not found');
  }

  const { availableStock, price, product } = await getCartItemInventorySnapshot({
    productId: item.productId,
    variantId: item.variantId,
  });

  if (parsedQuantity > availableStock) {
    throw new BadRequestError('Insufficient stock for requested quantity');
  }

  item.quantity = parsedQuantity;
  item.priceSnapshot = price;
  item.productNameSnapshot = product.name;
  item.productImageSnapshot = product.images?.[0]?.url || '';

  await cart.save();
  return getCart(userId);
};

export const removeFromCart = async (userId, itemIdOrVariantId) => {
  const cart = await Cart.findOne({ userId });
  if (!cart) {
    throw new NotFoundError('Cart not found');
  }

  const item = resolveCartItem(cart, itemIdOrVariantId);
  if (!item) {
    throw new NotFoundError('Cart item not found');
  }

  item.deleteOne();
  await cart.save();
  return getCart(userId);
};

export const clearCart = async (userId) => {
  let cart = await Cart.findOne({ userId });
  if (!cart) {
    cart = await Cart.create({ userId, items: [] });
  } else {
    cart.items = [];
    await cart.save();
  }

  return getCart(userId);
};
