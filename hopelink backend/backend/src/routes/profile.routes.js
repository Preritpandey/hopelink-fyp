import express from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import { updateProfile, uploadProfilePhoto, uploadCV } from '../controllers/profile.controller.js';
import { uploadImage, uploadPdf } from '../middleware/multer.js';

const router = express.Router();

// Protected routes (require authentication)
router.use(authenticate);

// Update profile
router.put('/', updateProfile);

// Upload profile photo
router.post(
  '/photo',
  uploadImage.single('profileImage'),
  uploadProfilePhoto
);

// Upload CV
router.post(
  '/cv',
  uploadPdf.single('cv'),
  uploadCV
);

export default router;
