import express from 'express';
import * as OrderController from '../../controllers/ecommerce/order.controller.js';
import { authenticate } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.post('/checkout', OrderController.checkout);
router.get('/my-orders', OrderController.getMyOrders);
router.get('/org-orders', OrderController.getOrgOrders); // Should probably strictly authorize Orgs only here

export default router;
