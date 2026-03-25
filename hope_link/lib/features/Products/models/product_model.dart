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
    return ProductsResponse(
      products: (json['products'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
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
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      org: OrgModel.fromJson(json['orgId'] as Map<String, dynamic>),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      beneficiaryDescription: json['beneficiaryDescription'] as String? ?? '',
      category: json['category'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get minPrice =>
      variants.isEmpty ? 0 : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  double get maxPrice =>
      variants.isEmpty ? 0 : variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);

  String get priceDisplay => minPrice == maxPrice
      ? 'NPR ${minPrice.toStringAsFixed(0)}'
      : 'NPR ${minPrice.toStringAsFixed(0)} – ${maxPrice.toStringAsFixed(0)}';

  String? get coverImage => images.isNotEmpty ? images.first : null;
}

class OrgModel {
  final String id;
  final String organizationName;

  OrgModel({required this.id, required this.organizationName});

  factory OrgModel.fromJson(Map<String, dynamic> json) {
    return OrgModel(
      id: json['_id'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
    );
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
      id: json['_id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      attributes: VariantAttributes.fromJson(
          json['attributes'] as Map<String, dynamic>? ?? {}),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
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
    return parts.join(' · ');
  }
}