import Order from '../../models/ecommerce/order.model.js';
import Cart from '../../models/ecommerce/cart.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Product from '../../models/ecommerce/product.model.js';
import mongoose from 'mongoose';
import { randomUUID } from 'crypto';
import {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
} from '../../errors/index.js';
import {
  retrieveStripePaymentIntent,
  lookupKhaltiEpayment,
  verifyKhaltiPayment,
  normalizeKhaltiAmount,
  isKhaltiPaymentSuccessful,
  isKhaltiEpaymentCompleted,
  isStripePaymentSuccessful,
  getStripePaymentId,
  getKhaltiPaymentId,
} from '../payment.service.js';

const ORDER_STATUS_TRANSITIONS = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
};

const buildStatusHistoryEntry = ({
  status,
  actorRole = 'system',
  note,
  trackingNumber,
  reason,
}) => ({
  status,
  changedAt: new Date(),
  changedByRole: actorRole,
  note: note || undefined,
  trackingNumber: trackingNumber || undefined,
  reason: reason || undefined,
});

const getPopulatedCart = (userId) =>
  Cart.findOne({ userId })
    .populate({
      path: 'items.productId',
      model: Product,
    })
    .populate({
      path: 'items.variantId',
      model: ProductVariant,
    });

const validateShippingAddress = (shippingAddress = {}) => {
  const requiredFields = ['fullName', 'phone', 'street', 'city', 'country'];
  const missing = requiredFields.filter((field) => !shippingAddress[field]);

  if (missing.length) {
    throw new BadRequestError(
      `Shipping address is missing required fields: ${missing.join(', ')}`,
    );
  }
};

const getCurrentInventoryForItem = async ({ productId, variantId }) => {
  const product = await Product.findOne({
    _id: productId,
    isDeleted: false,
    isActive: true,
  });

  if (!product) {
    throw new NotFoundError('Product not found');
  }

  if (variantId) {
    const variant = await ProductVariant.findOne({
      _id: variantId,
      productId,
      isDeleted: false,
      isActive: true,
    });

    if (!variant) {
      throw new NotFoundError('Product variant not found');
    }

    return {
      product,
      variant,
      price: variant.price,
      availableStock: Math.min(product.stock, variant.stock),
    };
  }

  return {
    product,
    variant: null,
    price: product.price,
    availableStock: product.stock,
  };
};

const decrementInventoryForOrder = async (order) => {
  const rollbackOperations = [];

  try {
    for (const item of order.items) {
      const productUpdate = await Product.updateOne(
        { _id: item.productId, stock: { $gte: item.quantity } },
        { $inc: { stock: -item.quantity } },
      );

      if (!productUpdate.modifiedCount) {
        throw new BadRequestError(
          `Insufficient stock for ${item.productName || 'product'}`,
        );
      }

      rollbackOperations.push({
        type: 'product',
        id: item.productId,
        quantity: item.quantity,
      });

      if (item.variantId) {
        const variantUpdate = await ProductVariant.updateOne(
          { _id: item.variantId, stock: { $gte: item.quantity } },
          { $inc: { stock: -item.quantity } },
        );

        if (!variantUpdate.modifiedCount) {
          throw new BadRequestError(
            `Insufficient variant stock for ${item.productName || 'product'}`,
          );
        }

        rollbackOperations.push({
          type: 'variant',
          id: item.variantId,
          quantity: item.quantity,
        });
      }
    }
  } catch (error) {
    for (const operation of rollbackOperations.reverse()) {
      if (operation.type === 'product') {
        await Product.updateOne(
          { _id: operation.id },
          { $inc: { stock: operation.quantity } },
        );
      } else {
        await ProductVariant.updateOne(
          { _id: operation.id },
          { $inc: { stock: operation.quantity } },
        );
      }
    }

    throw error;
  }
};

const restoreInventoryForOrder = async (order) => {
  for (const item of order.items) {
    await Product.updateOne(
      { _id: item.productId },
      { $inc: { stock: item.quantity } },
    );

    if (item.variantId) {
      await ProductVariant.updateOne(
        { _id: item.variantId },
        { $inc: { stock: item.quantity } },
      );
    }
  }
};

const markOrdersAsFailed = async (orders, verificationData = {}) => {
  const orderIds = orders.map((order) => order._id);
  await Order.updateMany(
    { _id: { $in: orderIds } },
    {
      $set: {
        paymentStatus: 'failed',
        paymentVerificationData: verificationData,
      },
    },
  );
};

const verifyStripeOrderPayment = async ({ paymentIntentId, expectedAmount }) => {
  if (!paymentIntentId) {
    throw new BadRequestError('paymentIntentId is required for Stripe verification');
  }

  const intent = await retrieveStripePaymentIntent(paymentIntentId);
  if (!isStripePaymentSuccessful(intent)) {
    throw new BadRequestError('Stripe payment is not completed');
  }

  if (Number(intent.amount) !== Math.round(expectedAmount * 100)) {
    throw new BadRequestError('Verified Stripe amount does not match order total');
  }

  return {
    paymentReference: intent.id,
    paymentTransactionId: getStripePaymentId(intent),
    verificationData: {
      id: intent.id,
      status: intent.status,
      amount: intent.amount,
      currency: intent.currency,
      metadata: intent.metadata,
    },
  };
};

const verifyKhaltiOrderPayment = async ({
  pidx,
  token,
  amount,
  amountInPaisa,
  expectedAmount,
}) => {
  let result;

  if (pidx) {
    result = await lookupKhaltiEpayment({ pidx });
    if (!isKhaltiEpaymentCompleted(result)) {
      throw new BadRequestError('Khalti payment is not completed');
    }
  } else {
    if (!token || (amount == null && amountInPaisa == null)) {
      throw new BadRequestError(
        'Khalti verification requires pidx or token with amount',
      );
    }

    const normalized = normalizeKhaltiAmount({ amount, amountInPaisa });
    result = await verifyKhaltiPayment({
      token,
      amount: normalized.amountInPaisa,
    });

    if (!isKhaltiPaymentSuccessful(result)) {
      throw new BadRequestError('Khalti payment is not completed');
    }
  }

  const providerAmount = Number(
    result?.total_amount ?? result?.amount ?? amountInPaisa ?? amount,
  );

  if (providerAmount && providerAmount !== Math.round(expectedAmount * 100)) {
    throw new BadRequestError('Verified Khalti amount does not match order total');
  }

  return {
    paymentReference: pidx || token || getKhaltiPaymentId(result, ''),
    paymentTransactionId: getKhaltiPaymentId(result, pidx || token || ''),
    verificationData: result,
  };
};

export const createOrderFromCart = async (
  userId,
  { shippingAddress, paymentGateway, paymentReference },
) => {
  validateShippingAddress(shippingAddress);

  if (!['stripe', 'khalti'].includes(paymentGateway)) {
    throw new BadRequestError('paymentGateway must be either stripe or khalti');
  }

  const cart = await getPopulatedCart(userId);
  if (!cart || cart.items.length === 0) {
    throw new BadRequestError('Cart is empty');
  }

  const transactionId = randomUUID();
  const ordersByOrg = new Map();

  for (const cartItem of cart.items) {
    const { product, variant, price, availableStock } =
      await getCurrentInventoryForItem({
        productId: cartItem.productId._id,
        variantId: cartItem.variantId?._id,
      });

    if (availableStock < cartItem.quantity) {
      throw new BadRequestError(
        `Insufficient stock for ${product.name}. Available: ${availableStock}`,
      );
    }

    const orgId = product.orgId.toString();
    const itemTotal = price * cartItem.quantity;

    if (!ordersByOrg.has(orgId)) {
      ordersByOrg.set(orgId, {
        items: [],
        subTotal: 0,
      });
    }

    const orgOrder = ordersByOrg.get(orgId);
    orgOrder.items.push({
      productId: product._id,
      productName: product.name,
      productImg: product.images?.[0]?.url || '',
      variantId: variant?._id || null,
      variantAttributes: variant?.attributes,
      sku: variant?.sku,
      quantity: cartItem.quantity,
      price,
      totalPrice: itemTotal,
    });
    orgOrder.subTotal += itemTotal;
  }

  const createdOrders = [];

  for (const [orgId, orderData] of ordersByOrg.entries()) {
    const order = await Order.create({
      orgId,
      userId,
      transactionId,
      paymentGateway,
      paymentReference: paymentReference || '',
      items: orderData.items,
      subTotal: orderData.subTotal,
      shippingFee: 0,
      totalAmount: orderData.subTotal,
      status: 'pending',
      paymentStatus: 'pending',
      shippingAddress,
      statusHistory: [buildStatusHistoryEntry({ status: 'pending' })],
    });

    createdOrders.push(order);
  }

  return {
    transactionId,
    orders: createdOrders,
    totalAmount: createdOrders.reduce((sum, order) => sum + order.totalAmount, 0),
  };
};

export const verifyAndFinalizeOrderPayment = async (
  userId,
  { transactionId, gateway, paymentIntentId, pidx, token, amount, amountInPaisa },
) => {
  if (!transactionId) {
    throw new BadRequestError('transactionId is required');
  }

  const orders = await Order.find({
    userId,
    transactionId,
    paymentGateway: gateway,
  });

  if (!orders.length) {
    throw new NotFoundError('Pending checkout transaction not found');
  }

  const hasTerminalOrder = orders.some((order) => order.paymentStatus === 'paid');
  if (hasTerminalOrder) {
    return {
      transactionId,
      orders,
      paymentAlreadyVerified: true,
    };
  }

  const expectedAmount = orders.reduce((sum, order) => sum + order.totalAmount, 0);
  let verifiedPayment;

  try {
    if (gateway === 'stripe') {
      verifiedPayment = await verifyStripeOrderPayment({
        paymentIntentId,
        expectedAmount,
      });
    } else if (gateway === 'khalti') {
      verifiedPayment = await verifyKhaltiOrderPayment({
        pidx,
        token,
        amount,
        amountInPaisa,
        expectedAmount,
      });
    } else {
      throw new BadRequestError('Unsupported payment gateway');
    }
  } catch (error) {
    await markOrdersAsFailed(orders, {
      gateway,
      paymentIntentId,
      pidx,
      token,
      reason: error.message,
    });
    throw error;
  }

  for (const order of orders) {
    await decrementInventoryForOrder(order);
  }

  await Order.updateMany(
    { _id: { $in: orders.map((order) => order._id) } },
    {
      $set: {
        paymentStatus: 'paid',
        paymentVerifiedAt: new Date(),
        paidAt: new Date(),
        paymentReference: verifiedPayment.paymentReference,
        paymentTransactionId: verifiedPayment.paymentTransactionId,
        paymentVerificationData: verifiedPayment.verificationData,
      },
    },
  );

  await Cart.findOneAndUpdate({ userId }, { $set: { items: [] } });

  const finalizedOrders = await Order.find({
    userId,
    transactionId,
    paymentGateway: gateway,
  }).sort({ createdAt: -1 });

  return {
    transactionId,
    orders: finalizedOrders,
    paymentVerified: true,
  };
};

export const getOrdersByUser = async (userId) => {
  return await Order.find({ userId })
    .populate('orgId', 'organizationName')
    .populate('items.productId', 'name slug images')
    .sort({ createdAt: -1 });
};

export const getOrderById = async (actor, orderId) => {
  const order = await Order.findById(orderId)
    .populate('orgId', 'organizationName')
    .populate('userId', 'name email')
    .populate('items.productId', 'name slug images');

  if (!order) {
    throw new NotFoundError('Order not found');
  }

  if (actor.role === 'organization') {
    if (order.orgId._id.toString() !== actor.organization?.toString()) {
      throw new ForbiddenError('You are not allowed to access this order');
    }
  } else if (actor.role !== 'admin') {
    if (order.userId._id.toString() !== actor._id.toString()) {
      throw new ForbiddenError('You are not allowed to access this order');
    }
  }

  return order;
};

export const getOrdersByOrg = async (orgId) => {
  return await Order.find({ orgId })
    .populate('userId', 'name email')
    .populate('items.productId', 'name slug images')
    .sort({ createdAt: -1 });
};

export const updateOrderStatus = async (actor, orderId, nextStatus) => {
  const payload =
    typeof nextStatus === 'string' ? { status: nextStatus } : nextStatus || {};
  const {
    status,
    trackingNumber,
    note,
    cancellationReason,
  } = payload;

  if (!['organization', 'admin'].includes(actor.role)) {
    throw new ForbiddenError('Only organizations and admins can update order status');
  }

  const order = await Order.findById(orderId);
  if (!order) {
    throw new NotFoundError('Order not found');
  }

  if (
    actor.role === 'organization' &&
    order.orgId.toString() !== actor.organization?.toString()
  ) {
    throw new ForbiddenError('You are not allowed to manage this order');
  }

  const allowedTransitions = ORDER_STATUS_TRANSITIONS[order.status] || [];
  if (!status) {
    throw new BadRequestError('status is required');
  }
  if (!allowedTransitions.includes(status)) {
    throw new BadRequestError(
      `Invalid order status transition from ${order.status} to ${status}`,
    );
  }

  if (status !== 'cancelled' && order.paymentStatus !== 'paid') {
    throw new BadRequestError('Only paid orders can be confirmed or delivered');
  }

  if (status === 'confirmed' && order.paymentStatus !== 'paid') {
    throw new BadRequestError('Only paid orders can be confirmed');
  }

  if (status === 'cancelled' && order.paymentStatus === 'paid') {
    await restoreInventoryForOrder(order);
  }

  order.status = status;
  if (status === 'delivered') {
    order.deliveredAt = new Date();
    if (trackingNumber) {
      order.trackingNumber = trackingNumber;
    }
    if (note) {
      order.deliveryNotes = note;
    }
  }
  if (status === 'cancelled') {
    order.cancelledAt = new Date();
    if (cancellationReason) {
      order.cancellationReason = cancellationReason;
    }
  }

  order.statusHistory = order.statusHistory || [];
  order.statusHistory.push(
    buildStatusHistoryEntry({
      status,
      actorRole: actor.role,
      note,
      trackingNumber,
      reason: cancellationReason,
    }),
  );

  await order.save();
  return await getOrderById(actor, orderId);
};

export const cancelOrderByUser = async (userId, orderId) => {
  const order = await Order.findById(orderId);
  if (!order) {
    throw new NotFoundError('Order not found');
  }

  if (order.userId.toString() !== userId.toString()) {
    throw new ForbiddenError('You are not allowed to cancel this order');
  }

  if (order.status !== 'pending') {
    throw new BadRequestError('Only pending orders can be cancelled');
  }

  if (order.paymentStatus === 'paid') {
    await restoreInventoryForOrder(order);
  }

  order.status = 'cancelled';
  order.cancelledAt = new Date();
  order.statusHistory = order.statusHistory || [];
  order.statusHistory.push(
    buildStatusHistoryEntry({
      status: 'cancelled',
      actorRole: 'user',
      reason: 'Cancelled by customer',
    }),
  );
  await order.save();
  return order;
};

export const getOrgSalesSummary = async (orgId) => {
  const mongooseOrgId = new mongoose.Types.ObjectId(orgId);

  const [summary] = await Order.aggregate([
    {
      $match: {
        orgId: mongooseOrgId,
      },
    },
    {
      $group: {
        _id: '$orgId',
        totalRevenue: {
          $sum: {
            $cond: [{ $eq: ['$paymentStatus', 'paid'] }, '$totalAmount', 0],
          },
        },
        totalOrders: { $sum: 1 },
        paidOrders: {
          $sum: { $cond: [{ $eq: ['$paymentStatus', 'paid'] }, 1, 0] },
        },
        pendingPaymentOrders: {
          $sum: { $cond: [{ $eq: ['$paymentStatus', 'pending'] }, 1, 0] },
        },
        cancelledOrders: {
          $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] },
        },
        confirmedOrders: {
          $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] },
        },
        deliveredOrders: {
          $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] },
        },
      },
    },
  ]);

  return (
    summary || {
      _id: mongooseOrgId,
      totalRevenue: 0,
      totalOrders: 0,
      paidOrders: 0,
      pendingPaymentOrders: 0,
      cancelledOrders: 0,
      confirmedOrders: 0,
      deliveredOrders: 0,
    }
  );
};

export const getOrgProductSalesSummary = async (orgId) => {
  const mongooseOrgId = new mongoose.Types.ObjectId(orgId);

  const summary = await Order.aggregate([
    {
      $match: {
        orgId: mongooseOrgId,
        paymentStatus: 'paid',
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

  const products = await Product.find({
    orgId: mongooseOrgId,
    isDeleted: false,
  })
    .select('name stock lowStockThreshold images isActive sku')
    .lean();

  const salesMap = new Map(
    summary.map((item) => [item._id.toString(), item]),
  );

  return products.map((product) => {
    const finalSales = salesMap.get(product._id.toString());
    const unitsSold = finalSales?.unitsSold || 0;
    const revenue = finalSales?.revenue || 0;
    const currentStock = Number(product.stock || 0);
    const threshold = Number(product.lowStockThreshold || 5);

    return {
      productId: product._id,
      productName: product.name,
      sku: product.sku || '',
      image: product.images?.[0]?.url || product.images?.[0] || '',
      unitsSold,
      revenue,
      currentStock,
      isActive: product.isActive,
      lowStock: currentStock > 0 && currentStock <= threshold,
      outOfStock: currentStock <= 0,
    };
  });
};
