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

