import Review from '../../models/ecommerce/review.model.js';
import Order from '../../models/ecommerce/order.model.js';
import { BadRequestError } from '../../errors/index.js';

export const addReview = async (userId, productId, rating, reviewText) => {
  const hasPurchased = await Order.findOne({
    userId,
    paymentStatus: 'paid',
    items: { $elemMatch: { productId } },
  });

  if (!hasPurchased) {
    throw new BadRequestError('You can only review products you have purchased.');
  }

  const review = await Review.create({
    userId,
    productId,
    rating,
    reviewText,
    orderId: hasPurchased._id,
  });

  return review;
};

export const getProductReviews = async (productId) => {
  return await Review.find({ productId }).populate('userId', 'name profileImage');
};
