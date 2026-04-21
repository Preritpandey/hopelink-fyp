import express from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import * as WishlistController from '../../controllers/ecommerce/wishlist.controller.js';

const router = express.Router();

router.use(authenticate);

router.get('/', WishlistController.getWishlist);
router.post('/:productId', WishlistController.addToWishlist);
router.delete('/:productId', WishlistController.removeFromWishlist);

export default router;
