import Wishlist from '../../models/ecommerce/wishlist.model.js';
import Product from '../../models/ecommerce/product.model.js';
import { NotFoundError } from '../../errors/index.js';

const getWishlistQuery = (userId) =>
  Wishlist.findOne({ userId }).populate({
    path: 'products',
    match: { isDeleted: false, isActive: true },
    populate: [
      { path: 'category', select: 'name slug' },
      { path: 'orgId', select: 'organizationName' },
    ],
  });

export const getWishlist = async (userId) => {
  let wishlist = await getWishlistQuery(userId);
  if (!wishlist) {
    wishlist = await Wishlist.create({ userId, products: [] });
    wishlist = await getWishlistQuery(userId);
  }

  return wishlist;
};

export const addToWishlist = async (userId, productId) => {
  const product = await Product.findOne({
    _id: productId,
    isDeleted: false,
    isActive: true,
  });

  if (!product) {
    throw new NotFoundError('Product not found');
  }

  await Wishlist.findOneAndUpdate(
    { userId },
    { $addToSet: { products: productId } },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  return getWishlist(userId);
};

export const removeFromWishlist = async (userId, productId) => {
  const wishlist = await Wishlist.findOneAndUpdate(
    { userId },
    { $pull: { products: productId } },
    { new: true },
  );

  if (!wishlist) {
    throw new NotFoundError('Wishlist not found');
  }

  return getWishlist(userId);
};
