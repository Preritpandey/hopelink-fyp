import express from 'express';
import * as OrderController from '../../controllers/ecommerce/order.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.post('/checkout', OrderController.checkout);
router.get('/', OrderController.getMyOrders);
router.get('/my-orders', OrderController.getMyOrders);
router.patch(
  '/:id/status',
  authorize('organization', 'admin'),
  OrderController.updateOrderStatus,
);
router.patch('/:id/cancel', OrderController.cancelMyOrder);
router.get(
  '/org-orders',
  authorize('organization', 'admin'),
  OrderController.getOrgOrders,
);
router.get(
  '/org-sales/summary',
  authorize('organization', 'admin'),
  OrderController.getOrgSalesSummary,
);
router.get(
  '/org-sales/products',
  authorize('organization', 'admin'),
  OrderController.getOrgProductSalesSummary,
);
router.get('/:id', OrderController.getOrder);

export default router;
