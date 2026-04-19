import { StatusCodes } from 'http-status-codes';
import {
  createStripePaymentIntent,
  retrieveStripePaymentIntent,
  verifyKhaltiPayment,
  normalizeKhaltiAmount,
  isKhaltiPaymentSuccessful,
  initiateKhaltiEpayment,
  lookupKhaltiEpayment,
  isKhaltiEpaymentCompleted,
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
    const { token, amount, amountInPaisa } = req.body;

    if (!token || (amount == null && amountInPaisa == null)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'token and amount (in paisa) are required',
      });
    }

    const { amountInPaisa: normalizedPaisa, amountInRupees } =
      normalizeKhaltiAmount({ amount, amountInPaisa });

    const result = await verifyKhaltiPayment({
      token,
      amount: normalizedPaisa,
    });

    if (!isKhaltiPaymentSuccessful(result)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Khalti payment is not completed',
        data: result,
      });
    }

    res.status(StatusCodes.OK).json({
      success: true,
      data: result,
      meta: {
        amountInPaisa: normalizedPaisa,
        amountInRupees,
      },
    });
  } catch (error) {
    // Khalti returns 4xx with error details; surface a clean message
    if (error.response?.data) {
      const statusCode = error.response.status || 400;
      const detail = error.response.data?.detail;
      const isInvalidCredential =
        statusCode === StatusCodes.UNAUTHORIZED &&
        typeof detail === 'string' &&
        detail.toLowerCase().includes('invalid token');

      return res.status(statusCode).json({
        success: false,
        message: isInvalidCredential
            ? 'Khalti credentials are invalid or the configured environment does not match the active Khalti keys.'
            : 'Khalti verification failed.',
        error: {
          source: 'khalti',
          ...error.response.data,
        },
      });
    }
    next(error);
  }
};

/**
 * Initialize Khalti ePayment (KPG) and return pidx for client checkout.
 *
 * @route POST /api/v1/payments/khalti/init
 */
export const initKhaltiPayment = async (req, res, next) => {
  try {
    const {
      amount,
      purchaseOrderId,
      purchaseOrderName,
      returnUrl,
      websiteUrl,
      customerInfo,
    } = req.body;

    if (!amount || !purchaseOrderId || !purchaseOrderName) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'amount, purchaseOrderId, and purchaseOrderName are required',
      });
    }

    const requestOrigin = `${req.protocol}://${req.get('host')}`;
    const defaultReturnUrl = `${requestOrigin}/api/v1/payments/khalti/return`;
    const defaultWebsiteUrl = requestOrigin;

    const result = await initiateKhaltiEpayment({
      amount,
      purchaseOrderId,
      purchaseOrderName,
      returnUrl: returnUrl || defaultReturnUrl,
      websiteUrl: websiteUrl || defaultWebsiteUrl,
      customerInfo,
    });

    res.status(StatusCodes.OK).json({
      success: true,
      data: result,
    });
  } catch (error) {
    if (error.response?.data) {
      const statusCode = error.response.status || 400;
      const detail = error.response.data?.detail;
      const isInvalidCredential =
        statusCode === StatusCodes.UNAUTHORIZED &&
        typeof detail === 'string' &&
        detail.toLowerCase().includes('invalid token');

      return res.status(statusCode).json({
        success: false,
        message: isInvalidCredential
          ? 'Khalti credentials are invalid or the configured environment does not match the active Khalti keys.'
          : 'Failed to initiate Khalti payment.',
        error: {
          source: 'khalti',
          ...error.response.data,
        },
      });
    }
    next(error);
  }
};

/**
 * Lookup Khalti ePayment status by pidx.
 *
 * @route POST /api/v1/payments/khalti/lookup
 */
export const lookupKhaltiPayment = async (req, res, next) => {
  try {
    const { pidx } = req.body;

    if (!pidx) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'pidx is required',
      });
    }

    const result = await lookupKhaltiEpayment({ pidx });
    const completed = isKhaltiEpaymentCompleted(result);

    res.status(StatusCodes.OK).json({
      success: true,
      data: result,
      meta: {
        completed,
      },
    });
  } catch (error) {
    if (error.response?.data) {
      const statusCode = error.response.status || 400;
      const detail = error.response.data?.detail;
      const isInvalidCredential =
        statusCode === StatusCodes.UNAUTHORIZED &&
        typeof detail === 'string' &&
        detail.toLowerCase().includes('invalid token');

      return res.status(statusCode).json({
        success: false,
        message: isInvalidCredential
          ? 'Khalti credentials are invalid or the configured environment does not match the active Khalti keys.'
          : 'Failed to lookup Khalti payment.',
        error: {
          source: 'khalti',
          ...error.response.data,
        },
      });
    }
    next(error);
  }
};

export const khaltiReturnPage = async (req, res) => {
  return res.status(StatusCodes.OK).send(`
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Returning to Hope Link</title>
        <style>
          body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #f4fff8 0%, #eef6ff 100%);
            font-family: Arial, sans-serif;
            color: #1f2937;
          }
          .card {
            max-width: 360px;
            padding: 32px 28px;
            border-radius: 20px;
            background: rgba(255, 255, 255, 0.96);
            box-shadow: 0 18px 50px rgba(15, 23, 42, 0.12);
            text-align: center;
          }
          .spinner {
            width: 44px;
            height: 44px;
            margin: 0 auto 18px;
            border: 4px solid #dbeafe;
            border-top-color: #2563eb;
            border-radius: 999px;
            animation: spin 0.8s linear infinite;
          }
          h1 {
            margin: 0 0 10px;
            font-size: 22px;
          }
          p {
            margin: 0;
            line-height: 1.5;
            color: #4b5563;
          }
          @keyframes spin {
            to {
              transform: rotate(360deg);
            }
          }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="spinner"></div>
          <h1>Payment Confirmed</h1>
          <p>Returning you to Hope Link. This page will close automatically.</p>
        </div>
      </body>
    </html>
  `);
};

export default {
  initStripePayment,
  verifyStripePayment,
  verifyKhalti,
  initKhaltiPayment,
  lookupKhaltiPayment,
  khaltiReturnPage,
};

