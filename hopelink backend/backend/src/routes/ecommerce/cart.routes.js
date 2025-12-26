import express from 'express';
import * as CartController from '../../controllers/ecommerce/cart.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate); // All cart routes require login

router.get('/', CartController.getMyCart);
router.post('/add', CartController.addToCart);
router.patch('/update', CartController.updateCartItem);
router.delete('/remove/:variantId', CartController.removeCartItem);

export default router;
