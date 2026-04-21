import * as CartService from '../../services/ecommerce/cart.service.js';
import { StatusCodes } from 'http-status-codes';

export const getMyCart = async (req, res, next) => {
  try {
    const cart = await CartService.getCart(req.user._id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

export const addToCart = async (req, res, next) => {
  try {
    const cart = await CartService.addToCart(req.user._id, req.body);
    res.status(StatusCodes.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

export const updateCartItem = async (req, res, next) => {
  try {
    const cart = await CartService.updateCartItem(
      req.user._id,
      req.params.itemId || req.body.itemId || req.body.variantId,
      req.body.quantity,
    );
    res.status(StatusCodes.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

export const removeCartItem = async (req, res, next) => {
  try {
    const cart = await CartService.removeFromCart(
      req.user._id,
      req.params.itemId || req.body?.itemId || req.body?.variantId,
    );
    res.status(StatusCodes.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

export const clearCart = async (req, res, next) => {
  try {
    const cart = await CartService.clearCart(req.user._id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};
