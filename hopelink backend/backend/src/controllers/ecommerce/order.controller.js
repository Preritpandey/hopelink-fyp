import * as OrderService from '../../services/ecommerce/order.service.js';
import { StatusCodes } from 'http-status-codes';

export const checkout = async (req, res, next) => {
  try {
    const { shippingAddress, paymentGateway, paymentReference, paymentData } =
      req.body;

    const result = await OrderService.createOrderFromCart(req.user._id, {
      shippingAddress,
      paymentGateway: paymentGateway || paymentData?.gateway,
      paymentReference: paymentReference || paymentData?.paymentReference,
    });

    res.status(StatusCodes.CREATED).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const getMyOrders = async (req, res, next) => {
  try {
    const orders = await OrderService.getOrdersByUser(req.user._id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

export const getOrgOrders = async (req, res, next) => {
  try {
    const orgId = req.user.organization;
    const orders = await OrderService.getOrdersByOrg(orgId);
    res.status(StatusCodes.OK).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

export const getOrgSalesSummary = async (req, res, next) => {
  try {
    const orgId = req.user.organization;
    const summary = await OrderService.getOrgSalesSummary(orgId);
    res.status(StatusCodes.OK).json({
      success: true,
      data: summary,
    });
  } catch (error) {
    next(error);
  }
};

export const getOrgProductSalesSummary = async (req, res, next) => {
  try {
    const orgId = req.user.organization;
    const summary = await OrderService.getOrgProductSalesSummary(orgId);
    res.status(StatusCodes.OK).json({
      success: true,
      data: summary,
    });
  } catch (error) {
    next(error);
  }
};

export const getOrder = async (req, res, next) => {
  try {
    const order = await OrderService.getOrderById(req.user, req.params.id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

export const updateOrderStatus = async (req, res, next) => {
  try {
    const order = await OrderService.updateOrderStatus(
      req.user,
      req.params.id,
      req.body,
    );

    res.status(StatusCodes.OK).json({
      success: true,
      data: order,
    });
  } catch (error) {
    next(error);
  }
};

export const cancelMyOrder = async (req, res, next) => {
  try {
    const order = await OrderService.cancelOrderByUser(req.user._id, req.params.id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: order,
    });
  } catch (error) {
    next(error);
  }
};
