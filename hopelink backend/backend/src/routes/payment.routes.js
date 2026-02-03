import express from 'express';
import {
  initStripePayment,
  verifyStripePayment,
  verifyKhalti,
} from '../controllers/payment.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import PAYMENT_CONFIG from '../config/payment.config.js';

const router = express.Router();

// Public route to expose non-sensitive payment config (publishable key)
router.get('/config', (req, res) => {
  return res.json({
    success: true,
    data: {
      publishableKey: PAYMENT_CONFIG.stripe.publishableKey || '',
      currency: PAYMENT_CONFIG.stripe.currency || 'npr',
    },
  });
});

// All payment routes below require authentication
router.use(authenticate);

// Stripe
router.post('/stripe/init', initStripePayment);
router.post('/stripe/verify', verifyStripePayment);

// Khalti
router.post('/khalti/verify', verifyKhalti);

export default router;

