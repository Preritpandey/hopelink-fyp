import { StatusCodes } from 'http-status-codes';
import * as WishlistService from '../../services/ecommerce/wishlist.service.js';

export const getWishlist = async (req, res, next) => {
  try {
    const wishlist = await WishlistService.getWishlist(req.user._id);
    res.status(StatusCodes.OK).json({
      success: true,
      data: wishlist,
    });
  } catch (error) {
    next(error);
  }
};

export const addToWishlist = async (req, res, next) => {
  try {
    const wishlist = await WishlistService.addToWishlist(
      req.user._id,
      req.params.productId,
    );
    res.status(StatusCodes.OK).json({
      success: true,
      data: wishlist,
    });
  } catch (error) {
    next(error);
  }
};

export const removeFromWishlist = async (req, res, next) => {
  try {
    const wishlist = await WishlistService.removeFromWishlist(
      req.user._id,
      req.params.productId,
    );
    res.status(StatusCodes.OK).json({
      success: true,
      data: wishlist,
    });
  } catch (error) {
    next(error);
  }
};
