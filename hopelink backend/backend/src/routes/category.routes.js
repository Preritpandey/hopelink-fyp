import express from 'express';
import {
  createCategory,
  getCategories,
  getCategory,
  updateCategory,
  deleteCategory,
  getSubcategories,
  getCategoryTree,
} from '../controllers/category.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { handleFileUpload } from '../config/multer.config.js';

const router = express.Router();

// Public routes
router.get('/', getCategories);
router.get('/tree', getCategoryTree);
router.get('/:id', getCategory);
router.get('/:id/subcategories', getSubcategories);

// Protected routes (admin only)
router.use(authenticate);
router.use(authorize('admin'));

// File upload configuration for category images and icons
const uploadFields = [
  { name: 'icon', maxCount: 1 },
  { name: 'image', maxCount: 1 },
];

// Admin routes
router.post('/', handleFileUpload(uploadFields), createCategory);
router.put('/:id', handleFileUpload(uploadFields), updateCategory);
router.delete('/:id', deleteCategory);

export default router;
