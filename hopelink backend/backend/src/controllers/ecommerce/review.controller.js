import * as ReviewService from '../../services/ecommerce/review.service.js';
import { StatusCodes } from 'http-status-codes';

export const addReview = async (req, res) => {
  try {
    const { productId, rating, reviewText } = req.body;
    const review = await ReviewService.addReview(req.user.userId, productId, rating, reviewText);
    res.status(StatusCodes.CREATED).json(review);
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const getProductReviews = async (req, res) => {
  try {
    const reviews = await ReviewService.getProductReviews(req.params.productId);
    res.status(StatusCodes.OK).json(reviews);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};
