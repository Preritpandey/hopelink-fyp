import express from 'express';
import {
  register,
  login as loginUser,
  logout as logoutUser,
  forgotPassword,
  resetPassword,
  verifyEmail,
  resendVerificationEmail,
  getMe,
  updatePassword,
  updateDetails,
  verifyOtp,
  resendOtp,
  resetPasswordWithOtp  
} from '../controllers/auth.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', loginUser);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password/:token', resetPassword);
router.get('/verify-email/:token', verifyEmail);
router.post('/resend-verification', resendVerificationEmail);
router.post('/verify-otp', verifyOtp);
router.post('/resend-otp', resendOtp);
router.post('/reset-password', resetPasswordWithOtp);
// Protected routes (require authentication)
router.use(authenticate);

router.get('/me', getMe);
router.put('/update-password', updatePassword);
router.put('/update-details', updateDetails);
router.post('/logout', logoutUser);

export default router;
