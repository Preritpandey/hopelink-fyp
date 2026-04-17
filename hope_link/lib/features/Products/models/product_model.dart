class ProductsResponse {
  final List<ProductModel> products;
  final int total;
  final int totalPages;

  ProductsResponse({
    required this.products,
    required this.total,
    required this.totalPages,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final rawProducts =
        json['products'] ??
        json['data'] ??
        json['items'] ??
        const <dynamic>[];
    final products = (rawProducts as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();

    return ProductsResponse(
      products: products,
      total: _asInt(json['total']) ?? products.length,
      totalPages: _asInt(json['totalPages']) ?? _asInt(json['pages']) ?? 1,
    );
  }
}

class ProductModel {
  final String id;
  final OrgModel org;
  final String name;
  final String description;
  final String beneficiaryDescription;
  final String category;
  final List<String> images;
  final bool isActive;
  final bool isDeleted;
  final double ratingAverage;
  final int ratingCount;
  final String slug;
  final List<ProductVariant> variants;

  ProductModel({
    required this.id,
    required this.org,
    required this.name,
    required this.description,
    required this.beneficiaryDescription,
    required this.category,
    required this.images,
    required this.isActive,
    required this.isDeleted,
    required this.ratingAverage,
    required this.ratingCount,
    required this.slug,
    required this.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _idFromDynamic(json['_id']) ?? _idFromDynamic(json['id']) ?? '',
      org: OrgModel.fromJson(json['orgId'] ?? json['organization'] ?? json['org']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      beneficiaryDescription: json['beneficiaryDescription'] as String? ?? '',
      category: _categoryLabel(json['category']),
      images: (json['images'] as List<dynamic>?)
              ?.map(_imageUrlFromJson)
              .whereType<String>()
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: _asInt(json['ratingCount']) ?? 0,
      slug: json['slug'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromJson)
              .toList() ??
          [],
    );
  }

  double get minPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  double get maxPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);

  String get priceDisplay => minPrice == maxPrice
      ? 'NPR ${minPrice.toStringAsFixed(0)}'
      : 'NPR ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}';

  String? get coverImage => images.isNotEmpty ? images.first : null;
}

class OrgModel {
  final String id;
  final String organizationName;

  OrgModel({required this.id, required this.organizationName});

  factory OrgModel.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return OrgModel(
        id: _idFromDynamic(json['_id']) ?? _idFromDynamic(json['id']) ?? '',
        organizationName:
            json['organizationName'] as String? ??
            json['name'] as String? ??
            '',
      );
    }

    if (json is String) {
      return OrgModel(id: json, organizationName: '');
    }

    return OrgModel(id: '', organizationName: '');
  }
}

class ProductVariant {
  final String id;
  final String productId;
  final VariantAttributes attributes;
  final double price;
  final String sku;
  final int stock;
  final bool isActive;
  final bool isDeleted;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.attributes,
    required this.price,
    required this.sku,
    required this.stock,
    required this.isActive,
    required this.isDeleted,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: _idFromDynamic(json['_id']) ?? '',
      productId: _idFromDynamic(json['productId']) ?? '',
      attributes: VariantAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>? ?? const {},
      ),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku'] as String? ?? '',
      stock: _asInt(json['stock']) ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  bool get inStock => stock > 0;
}

class VariantAttributes {
  final String? color;
  final String? size;
  final Map<String, dynamic> extra;

  VariantAttributes({this.color, this.size, required this.extra});

  factory VariantAttributes.fromJson(Map<String, dynamic> json) {
    return VariantAttributes(
      color: json['color'] as String?,
      size: json['size'] as String?,
      extra: json,
    );
  }

  String get displayLabel {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (size != null && size!.isNotEmpty) parts.add(size!);
    return parts.join(' - ');
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _idFromDynamic(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return value['_id'] as String? ?? value['id'] as String?;
  }
  return null;
}

String _categoryLabel(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return value['name'] as String? ??
        value['title'] as String? ??
        value['slug'] as String? ??
        (_idFromDynamic(value) ?? '');
  }
  return '';
}

String? _imageUrlFromJson(dynamic image) {
  if (image is String && image.isNotEmpty) return image;
  if (image is Map<String, dynamic>) {
    final url = image['url'] as String? ?? image['secure_url'] as String?;
    if (url != null && url.isNotEmpty) return url;
  }
  return null;
}
