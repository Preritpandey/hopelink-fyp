import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../screens/product_detail_page.dart';
import 'app_colors.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ─────────────────────────────────────────────
            _ProductCardImage(product: product),

            // ── Product Info ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Org badge
                  _OrgBadge(orgName: product.org.organizationName),
                  const SizedBox(height: 6),

                  // Product name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.priceDisplay,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.ratingAverage > 0)
                        _RatingChip(rating: product.ratingAverage),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Beneficiary
                  Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 13,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.beneficiaryDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProductCardImage extends StatelessWidget {
  final ProductModel product;
  const _ProductCardImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          product.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: product.coverImage!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.shimmer),
                  errorWidget: (_, __, ___) => _ImageFallback(product: product),
                )
              : _ImageFallback(product: product),

          // Variant count badge
          if (product.variants.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${product.variants.length} options',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ProductModel product;
  const _ImageFallback({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.shimmer,
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 36,
            color: AppColors.primary.withOpacity(0.4),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrgBadge extends StatelessWidget {
  final String orgName;
  const _OrgBadge({required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        orgName,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12, color: AppColors.starColor),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
