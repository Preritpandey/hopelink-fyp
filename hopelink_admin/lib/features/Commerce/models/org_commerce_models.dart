class OrgSalesSummary {
  const OrgSalesSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.paidOrders,
    required this.pendingPaymentOrders,
    required this.cancelledOrders,
    required this.confirmedOrders,
    required this.deliveredOrders,
  });

  final double totalRevenue;
  final int totalOrders;
  final int paidOrders;
  final int pendingPaymentOrders;
  final int cancelledOrders;
  final int confirmedOrders;
  final int deliveredOrders;

  factory OrgSalesSummary.empty() => const OrgSalesSummary(
        totalRevenue: 0,
        totalOrders: 0,
        paidOrders: 0,
        pendingPaymentOrders: 0,
        cancelledOrders: 0,
        confirmedOrders: 0,
        deliveredOrders: 0,
      );

  factory OrgSalesSummary.fromJson(Map<String, dynamic> json) {
    return OrgSalesSummary(
      totalRevenue: _asDouble(json['totalRevenue']),
      totalOrders: _asInt(json['totalOrders']),
      paidOrders: _asInt(json['paidOrders']),
      pendingPaymentOrders: _asInt(json['pendingPaymentOrders']),
      cancelledOrders: _asInt(json['cancelledOrders']),
      confirmedOrders: _asInt(json['confirmedOrders']),
      deliveredOrders: _asInt(json['deliveredOrders']),
    );
  }
}

class OrgCategory {
  const OrgCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory OrgCategory.fromJson(Map<String, dynamic> json) => OrgCategory(
        id: _readId(json),
        name: (json['name'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
      );
}

class OrgOrder {
  const OrgOrder({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.totalAmount,
    required this.subTotal,
    required this.shippingFee,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.paymentGateway,
    required this.paymentReference,
    required this.trackingNumber,
    required this.deliveryNotes,
    required this.cancellationReason,
    required this.shippingAddress,
    required this.items,
    required this.statusHistory,
  });

  final String id;
  final String customerName;
  final String customerEmail;
  final double totalAmount;
  final double subTotal;
  final double shippingFee;
  final String paymentStatus;
  final String status;
  final DateTime? createdAt;
  final String paymentGateway;
  final String paymentReference;
  final String trackingNumber;
  final String deliveryNotes;
  final String cancellationReason;
  final Map<String, dynamic> shippingAddress;
  final List<OrgOrderItem> items;
  final List<OrgOrderTimelineEntry> statusHistory;

  factory OrgOrder.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] as Map<String, dynamic>?;
    return OrgOrder(
      id: _readId(json),
      customerName: (user?['name'] ?? '').toString(),
      customerEmail: (user?['email'] ?? '').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      subTotal: _asDouble(json['subTotal']),
      shippingFee: _asDouble(json['shippingFee']),
      paymentStatus: (json['paymentStatus'] ?? 'pending').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _asDate(json['createdAt']),
      paymentGateway: (json['paymentGateway'] ?? '').toString(),
      paymentReference: (json['paymentReference'] ?? '').toString(),
      trackingNumber: (json['trackingNumber'] ?? '').toString(),
      deliveryNotes: (json['deliveryNotes'] ?? '').toString(),
      cancellationReason: (json['cancellationReason'] ?? '').toString(),
      shippingAddress: ((json['shippingAddress'] as Map?) ?? const {})
          .cast<String, dynamic>(),
      items: ((json['items'] as List?) ?? const [])
          .map((item) => OrgOrderItem.fromJson(
                (item as Map).cast<String, dynamic>(),
              ))
          .toList(),
      statusHistory: ((json['statusHistory'] as List?) ?? const [])
          .map((item) => OrgOrderTimelineEntry.fromJson(
                (item as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}

class OrgOrderItem {
  const OrgOrderItem({
    required this.productName,
    required this.productImage,
    required this.sku,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.variantAttributes,
  });

  final String productName;
  final String productImage;
  final String sku;
  final int quantity;
  final double price;
  final double totalPrice;
  final Map<String, String> variantAttributes;

  factory OrgOrderItem.fromJson(Map<String, dynamic> json) {
    final variantMap = <String, String>{};
    final rawAttributes = json['variantAttributes'];
    if (rawAttributes is Map) {
      for (final entry in rawAttributes.entries) {
        variantMap[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }

    return OrgOrderItem(
      productName: (json['productName'] ?? '').toString(),
      productImage: (json['productImg'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      quantity: _asInt(json['quantity']),
      price: _asDouble(json['price']),
      totalPrice: _asDouble(json['totalPrice']),
      variantAttributes: variantMap,
    );
  }
}

class OrgOrderTimelineEntry {
  const OrgOrderTimelineEntry({
    required this.status,
    required this.changedByRole,
    required this.note,
    required this.trackingNumber,
    required this.reason,
    required this.changedAt,
  });

  final String status;
  final String changedByRole;
  final String note;
  final String trackingNumber;
  final String reason;
  final DateTime? changedAt;

  factory OrgOrderTimelineEntry.fromJson(Map<String, dynamic> json) =>
      OrgOrderTimelineEntry(
        status: (json['status'] ?? '').toString(),
        changedByRole: (json['changedByRole'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
        trackingNumber: (json['trackingNumber'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        changedAt: _asDate(json['changedAt']),
      );
}

class OrgProduct {
  const OrgProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.beneficiaryDescription,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.sku,
    required this.stock,
    required this.isActive,
    required this.lowStockThreshold,
    required this.images,
    required this.variants,
    required this.stockHistory,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String beneficiaryDescription;
  final String categoryId;
  final String categoryName;
  final double price;
  final String sku;
  final int stock;
  final bool isActive;
  final int lowStockThreshold;
  final List<String> images;
  final List<OrgProductVariant> variants;
  final List<OrgStockHistoryEntry> stockHistory;

  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  factory OrgProduct.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final categoryMap =
        category is Map ? category.cast<String, dynamic>() : <String, dynamic>{};

    final images = <String>[];
    for (final item in (json['images'] as List?) ?? const []) {
      if (item is String) {
        images.add(item);
      } else if (item is Map && item['url'] != null) {
        images.add(item['url'].toString());
      }
    }

    return OrgProduct(
      id: _readId(json),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      beneficiaryDescription:
          (json['beneficiaryDescription'] ?? '').toString(),
      categoryId: _readId(categoryMap),
      categoryName: (categoryMap['name'] ?? '').toString(),
      price: _asDouble(json['price']),
      sku: (json['sku'] ?? '').toString(),
      stock: _asInt(json['stock']),
      isActive: json['isActive'] != false,
      lowStockThreshold: _asInt(json['lowStockThreshold'], fallback: 5),
      images: images,
      variants: ((json['variants'] as List?) ?? const [])
          .map((item) => OrgProductVariant.fromJson(
                (item as Map).cast<String, dynamic>(),
              ))
          .toList(),
      stockHistory: ((json['stockHistory'] as List?) ?? const [])
          .map((item) => OrgStockHistoryEntry.fromJson(
                (item as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}

class OrgProductVariant {
  const OrgProductVariant({
    required this.id,
    required this.attributes,
    required this.price,
    required this.sku,
    required this.stock,
    required this.isActive,
    required this.isDeleted,
  });

  final String id;
  final Map<String, String> attributes;
  final double price;
  final String sku;
  final int stock;
  final bool isActive;
  final bool isDeleted;

  factory OrgProductVariant.fromJson(Map<String, dynamic> json) {
    final attributes = <String, String>{};
    final raw = json['attributes'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        attributes[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }
    return OrgProductVariant(
      id: _readId(json),
      attributes: attributes,
      price: _asDouble(json['price']),
      sku: (json['sku'] ?? '').toString(),
      stock: _asInt(json['stock']),
      isActive: json['isActive'] != false,
      isDeleted: json['isDeleted'] == true,
    );
  }
}

class OrgStockHistoryEntry {
  const OrgStockHistoryEntry({
    required this.previousStock,
    required this.newStock,
    required this.note,
    required this.source,
    required this.changedAt,
  });

  final int previousStock;
  final int newStock;
  final String note;
  final String source;
  final DateTime? changedAt;

  factory OrgStockHistoryEntry.fromJson(Map<String, dynamic> json) =>
      OrgStockHistoryEntry(
        previousStock: _asInt(json['previousStock']),
        newStock: _asInt(json['newStock']),
        note: (json['note'] ?? '').toString(),
        source: (json['source'] ?? '').toString(),
        changedAt: _asDate(json['changedAt']),
      );
}

class OrgProductSalesSummary {
  const OrgProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.image,
    required this.unitsSold,
    required this.revenue,
    required this.currentStock,
    required this.isActive,
    required this.lowStock,
    required this.outOfStock,
  });

  final String productId;
  final String productName;
  final String sku;
  final String image;
  final int unitsSold;
  final double revenue;
  final int currentStock;
  final bool isActive;
  final bool lowStock;
  final bool outOfStock;

  factory OrgProductSalesSummary.fromJson(Map<String, dynamic> json) =>
      OrgProductSalesSummary(
        productId: (json['productId'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        sku: (json['sku'] ?? '').toString(),
        image: (json['image'] ?? '').toString(),
        unitsSold: _asInt(json['unitsSold']),
        revenue: _asDouble(json['revenue']),
        currentStock: _asInt(json['currentStock']),
        isActive: json['isActive'] != false,
        lowStock: json['lowStock'] == true,
        outOfStock: json['outOfStock'] == true,
      );
}

class ProductVariantDraft {
  ProductVariantDraft({
    this.id = '',
    this.attributeName = '',
    this.optionValue = '',
    this.priceAdjustment = 0,
    this.stock = 0,
    this.sku = '',
    this.isActive = true,
    this.isDeleted = false,
  });

  final String id;
  final String attributeName;
  final String optionValue;
  final double priceAdjustment;
  final int stock;
  final String sku;
  final bool isActive;
  final bool isDeleted;

  ProductVariantDraft copyWith({
    String? id,
    String? attributeName,
    String? optionValue,
    double? priceAdjustment,
    int? stock,
    String? sku,
    bool? isActive,
    bool? isDeleted,
  }) {
    return ProductVariantDraft(
      id: id ?? this.id,
      attributeName: attributeName ?? this.attributeName,
      optionValue: optionValue ?? this.optionValue,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse((value ?? '').toString()) ?? 0;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

DateTime? _asDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String _readId(Map<String, dynamic> json) {
  return (json['_id'] ?? json['id'] ?? '').toString();
}
