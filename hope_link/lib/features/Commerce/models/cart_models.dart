class CartResponse {
  final CartModel cart;

  CartResponse({required this.cart});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cart: CartModel.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? json,
      ),
    );
  }
}

class CartModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final int itemCount;
  final double subTotal;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.itemCount,
    required this.subTotal,
  });

  factory CartModel.empty() => CartModel(
        id: '',
        userId: '',
        items: const [],
        itemCount: 0,
        subTotal: 0,
      );

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: _readId(json),
      userId: _readString(json['userId']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList(),
      itemCount: _readInt(json['itemCount']),
      subTotal: _readDouble(json['subTotal']),
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String? variantId;
  final int quantity;
  final double priceSnapshot;
  final String productNameSnapshot;
  final String? productImageSnapshot;
  final String categoryName;

  CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.priceSnapshot,
    required this.productNameSnapshot,
    required this.productImageSnapshot,
    required this.categoryName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final category = productId is Map<String, dynamic> ? productId['category'] : null;

    return CartItem(
      id: _readId(json),
      productId: _readId(productId),
      variantId: _readNullableString(json['variantId']),
      quantity: _readInt(json['quantity']),
      priceSnapshot: _readDouble(json['priceSnapshot']),
      productNameSnapshot:
          _readString(json['productNameSnapshot']) != ''
              ? _readString(json['productNameSnapshot'])
              : (productId is Map<String, dynamic> ? _readString(productId['name']) : ''),
      productImageSnapshot:
          _readNullableString(json['productImageSnapshot']) ??
          _firstImageUrl(productId),
      categoryName: category is Map<String, dynamic>
          ? _readString(category['name'])
          : '',
    );
  }

  double get lineTotal => priceSnapshot * quantity;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final parsed = value?.toString();
  if (parsed == null || parsed.isEmpty || parsed == 'null') return null;
  return parsed;
}

String _readId(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    final id = value['_id'] ?? value['id'];
    return _readString(id);
  }
  return '';
}

String? _firstImageUrl(dynamic productId) {
  if (productId is! Map<String, dynamic>) return null;
  final images = productId['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is String) return first;
    if (first is Map<String, dynamic>) return _readNullableString(first['url']);
  }
  return null;
}
