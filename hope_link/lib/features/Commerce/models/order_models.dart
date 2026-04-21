enum PurchasePaymentGateway { stripe, khalti }

extension PurchasePaymentGatewayX on PurchasePaymentGateway {
  String get value => name;
  String get label => this == PurchasePaymentGateway.stripe ? 'Stripe' : 'Khalti';
}

class ShippingAddress {
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }
}

class CheckoutResult {
  final String transactionId;
  final List<OrderModel> orders;
  final double totalAmount;

  CheckoutResult({
    required this.transactionId,
    required this.orders,
    required this.totalAmount,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return CheckoutResult(
      transactionId: data['transactionId']?.toString() ?? '',
      orders: (data['orders'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList(),
      totalAmount: _readDouble(data['totalAmount']),
    );
  }
}

class OrderModel {
  final String id;
  final String transactionId;
  final String organizationName;
  final String status;
  final String paymentStatus;
  final List<OrderItem> items;
  final double totalAmount;
  final ShippingAddress? shippingAddress;
  final String? trackingNumber;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.transactionId,
    required this.organizationName,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.trackingNumber,
    required this.paidAt,
    required this.deliveredAt,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final organization = json['orgId'];
    return OrderModel(
      id: _readId(json),
      transactionId: json['transactionId']?.toString() ?? '',
      organizationName: organization is Map<String, dynamic>
          ? organization['organizationName']?.toString() ?? ''
          : '',
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      totalAmount: _readDouble(json['totalAmount']),
      shippingAddress: json['shippingAddress'] is Map<String, dynamic>
          ? ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : null,
      trackingNumber: _nullableString(json['trackingNumber']),
      paidAt: _nullableDate(json['paidAt']),
      deliveredAt: _nullableDate(json['deliveredAt']),
      createdAt: _nullableDate(json['createdAt']),
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    return OrderItem(
      productId: _readId(productId),
      productName: json['productName']?.toString() ??
          (productId is Map<String, dynamic> ? productId['name']?.toString() ?? '' : ''),
      quantity: _readInt(json['quantity']),
      price: _readDouble(json['price']),
      totalPrice: _readDouble(json['totalPrice']),
    );
  }
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readId(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }
  return '';
}

String? _nullableString(dynamic value) {
  final parsed = value?.toString();
  if (parsed == null || parsed.isEmpty || parsed == 'null') return null;
  return parsed;
}

DateTime? _nullableDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
