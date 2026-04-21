import * as ReviewService from '../../services/ecommerce/review.service.js';
import { StatusCodes } from 'http-status-codes';

export const addReview = async (req, res, next) => {
  try {
    const { productId, rating, reviewText } = req.body;
    const review = await ReviewService.addReview(req.user._id, productId, rating, reviewText);
    res.status(StatusCodes.CREATED).json({
      success: true,
      data: review,
    });
  } catch (error) {
    next(error);
  }
};

export const getProductReviews = async (req, res, next) => {
  try {
    const reviews = await ReviewService.getProductReviews(req.params.productId);
    res.status(StatusCodes.OK).json({
      success: true,
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
};
