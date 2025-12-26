import * as OrderService from '../../services/ecommerce/order.service.js';
import { StatusCodes } from 'http-status-codes';

export const checkout = async (req, res) => {
  try {
    const { shippingAddress, paymentData } = req.body;
    // paymentData would contain e.g. { paymentReference: 'stripe_charge_id_123', ... }
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
    // req.user.orgId should be set for Org users
    const orders = await OrderService.getOrdersByOrg(req.user.orgId);
    res.status(StatusCodes.OK).json(orders);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};
