import Order from '../../models/ecommerce/order.model.js';
import Cart from '../../models/ecommerce/cart.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Product from '../../models/ecommerce/product.model.js';
import mongoose from 'mongoose';
import { randomUUID } from 'crypto';

export const createOrderFromCart = async (userId, shippingAddress, paymentData) => {
  // Transaction removed for standalone MongoDB compatibility
  try {
    const cart = await Cart.findOne({ userId })
      .populate({
        path: 'items.productId',
        model: Product
      })
      .populate({
        path: 'items.variantId',
        model: ProductVariant
      });
    if (!cart || cart.items.length === 0) throw new Error('Cart is empty');

    // validate stock again
    for (const item of cart.items) {
      if (item.variantId.stock < item.quantity) {
        throw new Error(`Insufficient stock for ${item.productId.name} - ${item.variantId.sku}`);
      }
    }

    // Group items by Organization
    const ordersByOrg = {};
    const transactionId = randomUUID();

    for (const item of cart.items) {
      const orgId = item.productId.orgId.toString();
      if (!ordersByOrg[orgId]) {
        ordersByOrg[orgId] = {
          items: [],
          subTotal: 0
        };
      }
      
      const itemTotal = item.quantity * item.variantId.price;
      
      ordersByOrg[orgId].items.push({
        productId: item.productId._id,
        productName: item.productId.name,
        productImg: item.productId.images[0]?.url,
        variantId: item.variantId._id,
        variantAttributes: item.variantId.attributes,
        sku: item.variantId.sku,
        quantity: item.quantity,
        price: item.variantId.price,
        totalPrice: itemTotal
      });
      ordersByOrg[orgId].subTotal += itemTotal;
    }

    const createdOrders = [];

    for (const orgId in ordersByOrg) {
      const orderData = ordersByOrg[orgId];
      // Basic shipping calculation (can be complex later)
      const shippingFee = 0; 
      
      const order = new Order({
        orgId,
        userId,
        transactionId,
        paymentReference: paymentData.paymentReference, // From payment gateway
        items: orderData.items,
        subTotal: orderData.subTotal,
        shippingFee,
        totalAmount: orderData.subTotal + shippingFee,
        status: 'paid', // Assuming payment success for now
        paymentStatus: 'completed',
        shippingAddress,
        paidAt: new Date()
      });
      
      await order.save();
      createdOrders.push(order);

      // Reduce stock
      for (const item of orderData.items) {
        await ProductVariant.findByIdAndUpdate(item.variantId, {
            $inc: { stock: -item.quantity }
        });
      }
    }

    // Clear cart
    cart.items = [];
    await cart.save();

    return createdOrders;

  } catch (error) {
    throw error;
  }
};

export const getOrdersByUser = async (userId) => {
  return await Order.find({ userId }).sort({ createdAt: -1 });
};

export const getOrdersByOrg = async (orgId) => {
  return await Order.find({ orgId }).sort({ createdAt: -1 });
};

export const getOrgSalesSummary = async (orgId) => {
  const mongooseOrgId = new mongoose.Types.ObjectId(orgId);

  const [summary] = await Order.aggregate([
    {
      $match: {
        orgId: mongooseOrgId,
        paymentStatus: 'completed',
      },
    },
    {
      $group: {
        _id: '$orgId',
        totalRevenue: { $sum: '$totalAmount' },
        orderCount: { $sum: 1 },
      },
    },
  ]);

  return (
    summary || {
      _id: mongooseOrgId,
      totalRevenue: 0,
      orderCount: 0,
    }
  );
};

export const getOrgProductSalesSummary = async (orgId) => {
  const mongooseOrgId = new mongoose.Types.ObjectId(orgId);

  const summary = await Order.aggregate([
    {
      $match: {
        orgId: mongooseOrgId,
        paymentStatus: 'completed',
      },
    },
    { $unwind: '$items' },
    {
      $group: {
        _id: '$items.productId',
        unitsSold: { $sum: '$items.quantity' },
        revenue: { $sum: '$items.totalPrice' },
      },
    },
  ]);

  return summary;
};
