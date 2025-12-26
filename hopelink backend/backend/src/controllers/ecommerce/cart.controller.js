import * as CartService from '../../services/ecommerce/cart.service.js';
import { StatusCodes } from 'http-status-codes';

export const getMyCart = async (req, res) => {
  try {
    const cart = await CartService.getCart(req.user.userId);
    res.status(StatusCodes.OK).json(cart);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const addToCart = async (req, res) => {
  try {
    const { productId, variantId, quantity } = req.body;
    const cart = await CartService.addToCart(req.user.userId, productId, variantId, quantity); // Ensure quantity is handled correctly in service (add vs set)
    // Service 'addToCart' implements adding to existing qty
    res.status(StatusCodes.OK).json(cart);
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const updateCartItem = async (req, res) => {
  try {
    const { variantId, quantity } = req.body;
    const cart = await CartService.updateCartItem(req.user.userId, variantId, quantity);
    res.status(StatusCodes.OK).json(cart);
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const removeCartItem = async (req, res) => {
  try {
    const { variantId } = req.params; // Assuming variantId is passed in path or body. Path is cleaner for DELETE.
    // If using body for DELETE: req.body.variantId
    // Standard REST usually uses ID in path.
    const cart = await CartService.removeFromCart(req.user.userId, variantId);
    res.status(StatusCodes.OK).json(cart);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};
