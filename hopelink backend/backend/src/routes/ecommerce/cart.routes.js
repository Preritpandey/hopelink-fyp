import express from 'express';
import * as CartController from '../../controllers/ecommerce/cart.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate); // All cart routes require login

router.get('/', CartController.getMyCart);
router.post('/', CartController.addToCart);
router.delete('/clear', CartController.clearCart);
router.put('/:itemId', CartController.updateCartItem);
router.delete('/:itemId', CartController.removeCartItem);

// Backward-compatible aliases for existing clients
router.post('/add', CartController.addToCart);
router.patch('/update/:itemId', CartController.updateCartItem);
router.delete('/remove/:itemId', CartController.removeCartItem);

export default router;
