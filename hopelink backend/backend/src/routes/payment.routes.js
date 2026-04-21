import express from 'express';
import {
  initStripePayment,
  verifyStripePayment,
  verifyOrderPayment,
  verifyKhalti,
  initKhaltiPayment,
  lookupKhaltiPayment,
  khaltiReturnPage,
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
      khaltiPublicKey: PAYMENT_CONFIG.khalti.publicKey || '',
      khaltiEnvironment: PAYMENT_CONFIG.khalti.environment || 'test',
      currency: PAYMENT_CONFIG.stripe.currency || 'npr',
    },
  });
});

// Lightweight return URL for Khalti checkout so the SDK can hand users
// back to the app without sitting on a full external web page.
router.get('/khalti/return', khaltiReturnPage);

// All payment routes below require authentication
router.use(authenticate);

// Stripe
router.post('/stripe/init', initStripePayment);
router.post('/stripe/verify', verifyStripePayment);
router.post('/verify', verifyOrderPayment);

// Khalti
router.post('/khalti/init', initKhaltiPayment);
router.post('/khalti/lookup', lookupKhaltiPayment);
router.post('/khalti/verify', verifyKhalti);

export default router;
