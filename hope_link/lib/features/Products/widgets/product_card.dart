import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../models/product_model.dart';
import '../screens/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailPage(product: product)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _ProductImage(product: product)),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrgBadge(orgName: product.org.organizationName),
                      6.verticalSpace,
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                          height: 1.25,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        product.priceDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColorToken.primary.color,
                        ),
                      ),
                      4.verticalSpace,
                      if (product.ratingAverage > 0)
                        _RatingRow(
                          rating: product.ratingAverage,
                          reviewCount: product.ratingCount,
                        ),
                      const Spacer(),
                      if (product.beneficiaryDescription.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.volunteer_activism_rounded,
                              size: 13,
                              color: AppColorToken.primary.color.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            4.horizontalSpace,
                            Expanded(
                              child: Text(
                                product.beneficiaryDescription,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: AppColors.grey600,
                                  fontStyle: FontStyle.italic,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductModel product;

  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'product-${product.id}',
          child: product.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: product.coverImage!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColorToken.lightGrey.color),
                  errorWidget: (_, __, ___) => _ImageFallback(product: product),
                )
              : _ImageFallback(product: product),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.transparent,
                  AppColors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        ),
        if (product.displayVariants.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 104),
              child: _FloatingBadge(
                label: '${product.displayVariants.length} options',
              ),
            ),
          ),
        Positioned(
          left: 10,
          bottom: 10,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: _FloatingBadge(
              label: product.category.isNotEmpty
                  ? product.category.toUpperCase()
                  : 'PRODUCT',
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final String label;

  const _FloatingBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColorToken.primary.color,
          letterSpacing: 0.2,
        ),
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
      color: const Color(0xFFF2F4EF),
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: AppTextStyle.h2.copyWith(
            color: AppColorToken.primary.color.withValues(alpha: 0.35),
            fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        orgName.isNotEmpty ? orgName : 'Community Partner',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColorToken.primary.color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 14, color: AppColors.amber[700]),
        2.horizontalSpace,
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyle.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.grey700,
          ),
        ),
        if (reviewCount > 0) ...[
          4.horizontalSpace,
          Flexible(
            child: Text(
              '($reviewCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.labelSmall.copyWith(color: AppColors.grey500),
            ),
          ),
        ],
      ],
    );
  }
}
