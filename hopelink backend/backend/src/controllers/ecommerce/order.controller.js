import * as OrderService from '../../services/ecommerce/order.service.js';
import { StatusCodes } from 'http-status-codes';

export const checkout = async (req, res) => {
  try {
    const { shippingAddress, paymentData } = req.body;

    if (!paymentData || !paymentData.paymentReference) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        error: 'paymentData.paymentReference is required (Stripe/Khalti ID)',
      });
    }

    // paymentData should contain e.g. { paymentReference: 'stripe_pi_123', gateway: 'stripe' | 'khalti' }
    const orders = await OrderService.createOrderFromCart(req.user.userId, shippingAddress, paymentData);
    res.status(StatusCodes.CREATED).json(orders);
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const getMyOrders = async (req, res) => {
  try {
    const orders = await OrderService.getOrdersByUser(req.user.userId);
    res.status(StatusCodes.OK).json(orders);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const getOrgOrders = async (req, res) => {
  try {
    const orgId = req.user.orgId || req.user.organization;
    const orders = await OrderService.getOrdersByOrg(orgId);
    res.status(StatusCodes.OK).json(orders);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const getOrgSalesSummary = async (req, res) => {
  try {
    const orgId = req.user.orgId || req.user.organization;
    const summary = await OrderService.getOrgSalesSummary(orgId);
    res.status(StatusCodes.OK).json(summary);
  } catch (error) {
    res
      .status(StatusCodes.INTERNAL_SERVER_ERROR)
      .json({ error: error.message });
  }
};

export const getOrgProductSalesSummary = async (req, res) => {
  try {
    const orgId = req.user.orgId || req.user.organization;
    const summary = await OrderService.getOrgProductSalesSummary(orgId);
    res.status(StatusCodes.OK).json(summary);
  } catch (error) {
    res
      .status(StatusCodes.INTERNAL_SERVER_ERROR)
      .json({ error: error.message });
  }
};
