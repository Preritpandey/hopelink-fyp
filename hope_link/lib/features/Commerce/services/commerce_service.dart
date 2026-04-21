import 'package:dio/dio.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:hope_link/core/services/api_client.dart';

import '../models/cart_models.dart';
import '../models/order_models.dart';

class CommerceService {
  CommerceService({Dio? dio}) : _dio = dio ?? ApiClient.create();

  final Dio _dio;

  Future<CartModel> getCart() async {
    final response = await _dio.get(ApiEndpoints.cart);
    return CartResponse.fromJson(_asMap(response.data)).cart;
  }

  Future<CartModel> addToCart({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.cart,
      data: {
        'productId': productId,
        if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
        'quantity': quantity,
      },
    );
    return CartResponse.fromJson(_asMap(response.data)).cart;
  }

  Future<CartModel> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.cartItem(itemId),
      data: {'quantity': quantity},
    );
    return CartResponse.fromJson(_asMap(response.data)).cart;
  }

  Future<CartModel> removeCartItem(String itemId) async {
    final response = await _dio.delete(ApiEndpoints.cartItem(itemId));
    return CartResponse.fromJson(_asMap(response.data)).cart;
  }

  Future<CartModel> clearCart() async {
    final response = await _dio.delete(ApiEndpoints.clearCart);
    return CartResponse.fromJson(_asMap(response.data)).cart;
  }

  Future<CheckoutResult> checkout({
    required ShippingAddress shippingAddress,
    required PurchasePaymentGateway paymentGateway,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.ordersCheckout,
      data: {
        'shippingAddress': shippingAddress.toJson(),
        'paymentGateway': paymentGateway.value,
      },
    );
    return CheckoutResult.fromJson(_asMap(response.data));
  }

  Future<Map<String, dynamic>> initializeStripeOrderPayment({
    required int amountInPaisa,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.createPaymentIntent,
      data: {
        'amount': amountInPaisa,
        'currency': 'npr',
        'type': 'order',
      },
    );
    return _unwrapDataMap(response.data);
  }

  Future<Map<String, dynamic>> initializeKhaltiOrderPayment({
    required int amountInPaisa,
    required String purchaseOrderId,
    required String purchaseOrderName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.khaltiInitPayment,
      data: {
        'amount': amountInPaisa,
        'purchaseOrderId': purchaseOrderId,
        'purchaseOrderName': purchaseOrderName,
      },
    );
    return _unwrapDataMap(response.data);
  }

  Future<bool> verifyOrderPayment({
    required PurchasePaymentGateway gateway,
    required String transactionId,
    String? paymentIntentId,
    String? pidx,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.verifyOrderPayment,
      data: {
        'gateway': gateway.value,
        'transactionId': transactionId,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        if (pidx != null) 'pidx': pidx,
      },
    );
    final data = _dataMap(response.data);
    return data['paymentVerified'] == true ||
        data['verified'] == true ||
        (data['orders'] is List && (data['orders'] as List).isNotEmpty);
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get(ApiEndpoints.orders);
    final data = _dataMap(response.data);
    final orders = data['data'] is List ? data['data'] : data;
    return (orders as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> getOrderDetails(String orderId) async {
    final response = await _dio.get(ApiEndpoints.orderDetails(orderId));
    final data = _dataMap(response.data);
    return OrderModel.fromJson(
      data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data,
    );
  }

  Future<OrderModel> cancelOrder(String orderId) async {
    final response = await _dio.patch(ApiEndpoints.cancelOrder(orderId));
    return OrderModel.fromJson(_dataMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  Map<String, dynamic> _dataMap(dynamic value) {
    final root = _asMap(value);
    final data = root['data'];
    if (data is Map<String, dynamic>) return {'data': data, ...root};
    return root;
  }

  Map<String, dynamic> _unwrapDataMap(dynamic value) {
    final root = _asMap(value);
    final data = root['data'];
    if (data is Map<String, dynamic>) return data;
    return root;
  }
}
