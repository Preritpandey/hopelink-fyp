import { StatusCodes } from 'http-status-codes';
import {
  createStripePaymentIntent,
  retrieveStripePaymentIntent,
  verifyKhaltiPayment,
} from '../services/payment.service.js';

/**
 * Initialize Stripe payment for either product order or campaign donation.
 * Frontend should call this first to get clientSecret, then confirm payment on client.
 *
 * @route POST /api/v1/payments/stripe/init
 */
export const initStripePayment = async (req, res, next) => {
  try {
    const { amount, currency, type, campaignId, orgId, metadata = {} } =
      req.body;

    if (!amount || !type) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'amount and type are required',
      });
    }

    const baseMetadata = {
      type, // 'order' | 'donation'
      userId: req.user?._id?.toString() || req.user?.userId,
      campaignId: campaignId || null,
      orgId: orgId || null,
      ...metadata,
    };

    const intent = await createStripePaymentIntent({
      amount,
      currency,
      metadata: baseMetadata,
    });

    res.status(StatusCodes.OK).json({
      success: true,
      data: intent,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Simple server-side verification helper for Stripe payments.
 * Frontend can call this after successful client confirmation
 * to double-check status before creating orders/donations.
 *
 * @route POST /api/v1/payments/stripe/verify
 */
export const verifyStripePayment = async (req, res, next) => {
  try {
    const { paymentIntentId } = req.body;

    if (!paymentIntentId) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'paymentIntentId is required',
      });
    }

    const intent = await retrieveStripePaymentIntent(paymentIntentId);

    res.status(StatusCodes.OK).json({
      success: true,
      data: {
        id: intent.id,
        status: intent.status,
        amount: intent.amount,
        currency: intent.currency,
        metadata: intent.metadata,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify Khalti payment token after client-side checkout.
 * Frontend should send token + amount (in paisa) from Khalti.
 *
 * @route POST /api/v1/payments/khalti/verify
 */
export const verifyKhalti = async (req, res, next) => {
  try {
    const { token, amount } = req.body;

    if (!token || !amount) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'token and amount are required',
      });
    }

    const result = await verifyKhaltiPayment({ token, amount });

    res.status(StatusCodes.OK).json({
      success: true,
      data: result,
    });
  } catch (error) {
    // Khalti returns 4xx with error details; surface a clean message
    if (error.response?.data) {
      return res.status(error.response.status || 400).json({
        success: false,
        error: error.response.data,
      });
    }
    next(error);
  }
};

export default {
  initStripePayment,
  verifyStripePayment,
  verifyKhalti,
};

