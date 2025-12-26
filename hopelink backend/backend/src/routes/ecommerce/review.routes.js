import express from 'express';
import * as ReviewController from '../../controllers/ecommerce/review.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.get('/product/:productId', ReviewController.getProductReviews);
router.post('/', authenticate, ReviewController.addReview);

export default router;
