import express from 'express';
import * as ProductController from '../../controllers/ecommerce/product.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';
import { uploadImage } from '../../middleware/multer.js';

const router = express.Router();

router.get('/', ProductController.listProducts);
router.get('/:id', ProductController.getProduct);

// Org only routes
router.post(
  '/',
  authenticate,
  authorize('organization', 'admin'),
  uploadImage.array('images', 5),
  ProductController.createProduct,
);
router.put(
  '/:id',
  authenticate,
  authorize('organization', 'admin'),
  uploadImage.array('images', 5),
  ProductController.updateProduct,
);
router.delete(
  '/:id',
  authenticate,
  authorize('organization', 'admin'),
  ProductController.deleteProduct,
);

export default router;
