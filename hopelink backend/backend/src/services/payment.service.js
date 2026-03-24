import axios from 'axios';
import Stripe from 'stripe';
import PAYMENT_CONFIG, {
  STRIPE_SECRET_KEY,
  KHALTI_SECRET_KEY,
} from '../config/payment.config.js';

let stripeClient = null;
if (STRIPE_SECRET_KEY) {
  stripeClient = new Stripe(STRIPE_SECRET_KEY);
}

export const createStripePaymentIntent = async ({
  amount,
  currency,
  metadata = {},
}) => {
  if (!stripeClient) {
    throw new Error('Stripe is not configured on the server');
  }

  const intent = await stripeClient.paymentIntents.create({
    amount,
    currency: currency || PAYMENT_CONFIG.stripe.currency,
    metadata,
    automatic_payment_methods: { enabled: true },
  });

  return {
    id: intent.id,
    clientSecret: intent.client_secret,
    status: intent.status,
  };
};

export const retrieveStripePaymentIntent = async (paymentIntentId) => {
  if (!stripeClient) {
    throw new Error('Stripe is not configured on the server');
  }

  const intent = await stripeClient.paymentIntents.retrieve(paymentIntentId);
  return intent;
};

export const verifyKhaltiPayment = async ({ token, amount }) => {
  if (!KHALTI_SECRET_KEY) {
    throw new Error('Khalti is not configured on the server');
  }

  const url = PAYMENT_CONFIG.khalti.verifyUrl;

  const res = await axios.post(
    url,
    {
      token,
      amount,
    },
    {
      headers: {
        Authorization: `Key ${KHALTI_SECRET_KEY}`,
      },
    },
  );

  return res.data;
};

export const normalizeKhaltiAmount = ({ amount, amountInPaisa }) => {
  const rawPaisa = amountInPaisa ?? amount;
  const parsedPaisa = Number(rawPaisa);

  if (!Number.isFinite(parsedPaisa) || parsedPaisa <= 0) {
    throw new Error('Khalti amount must be a positive number (in paisa)');
  }

  if (
    amountInPaisa != null &&
    amount != null &&
    Number(amountInPaisa) !== Number(amount)
  ) {
    throw new Error('Khalti amount mismatch between amount and amountInPaisa');
  }

  const amountInPaisaNormalized = Math.round(parsedPaisa);
  const amountInRupees = amountInPaisaNormalized / 100;

  return {
    amountInPaisa: amountInPaisaNormalized,
    amountInRupees,
  };
};

export const isKhaltiPaymentSuccessful = (result) => {
  const state =
    result?.state?.name ||
    result?.state?.code ||
    result?.status ||
    result?.payment_status;

  if (!state) return true;

  const normalized = String(state).toLowerCase();
  return ['completed', 'complete', 'paid', 'success', 'successful'].includes(
    normalized,
  );
};

export const getKhaltiPaymentId = (result, fallbackToken = '') => {
  return (
    result?.pidx ||
    result?.idx ||
    result?.payment_id ||
    result?.transaction_id ||
    fallbackToken
  );
};

export const initiateKhaltiEpayment = async ({
  amount,
  purchaseOrderId,
  purchaseOrderName,
  returnUrl,
  websiteUrl,
  customerInfo,
}) => {
  if (!KHALTI_SECRET_KEY) {
    throw new Error('Khalti is not configured on the server');
  }

  const url = PAYMENT_CONFIG.khalti.initiateUrl;
  const payload = {
    amount,
    purchase_order_id: purchaseOrderId,
    purchase_order_name: purchaseOrderName,
    return_url: returnUrl || PAYMENT_CONFIG.khalti.returnUrl,
    website_url: websiteUrl || PAYMENT_CONFIG.khalti.websiteUrl,
  };

  if (customerInfo) {
    payload.customer_info = customerInfo;
  }

  const res = await axios.post(url, payload, {
    headers: {
      Authorization: `Key ${KHALTI_SECRET_KEY}`,
    },
  });

  return res.data;
};

export const lookupKhaltiEpayment = async ({ pidx }) => {
  if (!KHALTI_SECRET_KEY) {
    throw new Error('Khalti is not configured on the server');
  }

  const url = PAYMENT_CONFIG.khalti.lookupUrl;
  const res = await axios.post(
    url,
    { pidx },
    {
      headers: {
        Authorization: `Key ${KHALTI_SECRET_KEY}`,
      },
    },
  );

  return res.data;
};

export const isKhaltiEpaymentCompleted = (result) => {
  const status = result?.status || result?.state?.name || result?.state?.code;
  if (!status) return false;
  return String(status).toLowerCase() === 'completed';
};

