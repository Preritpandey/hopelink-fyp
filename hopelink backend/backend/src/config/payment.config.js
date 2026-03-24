import dotenv from 'dotenv';

// Ensure env is loaded (in case this is imported before index.js)
dotenv.config();

export const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY || '';
export const STRIPE_CURRENCY = process.env.STRIPE_CURRENCY || 'npr';

export const KHALTI_SECRET_KEY = process.env.KHALTI_SECRET_KEY || '';
export const KHALTI_PUBLIC_KEY = process.env.KHALTI_PUBLIC_KEY || '';
export const KHALTI_BASE_URL =
  process.env.KHALTI_BASE_URL || 'https://khalti.com/api/v2';
export const KHALTI_RETURN_URL =
  process.env.KHALTI_RETURN_URL || 'https://khalti.com';
export const KHALTI_WEBSITE_URL =
  process.env.KHALTI_WEBSITE_URL || 'https://khalti.com';

export const STRIPE_PUBLISHABLE_KEY = process.env.STRIPE_PUBLISHABLE_KEY || '';

export const PAYMENT_CONFIG = {
  stripe: {
    enabled: !!STRIPE_SECRET_KEY,
    secretKey: STRIPE_SECRET_KEY,
    publishableKey: STRIPE_PUBLISHABLE_KEY,  // Add this
    currency: STRIPE_CURRENCY,
  },
  khalti: {
    enabled: !!KHALTI_SECRET_KEY,
    secretKey: KHALTI_SECRET_KEY,
    publicKey: KHALTI_PUBLIC_KEY,
    verifyUrl: 'https://khalti.com/api/v2/payment/verify/',
    initiateUrl: `${KHALTI_BASE_URL}/epayment/initiate/`,
    lookupUrl: `${KHALTI_BASE_URL}/epayment/lookup/`,
    returnUrl: KHALTI_RETURN_URL,
    websiteUrl: KHALTI_WEBSITE_URL,
  },
};

export default PAYMENT_CONFIG;

