import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColorToken.primary.color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _ProductCardImage(product: product)),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _OrgBadge(orgName: product.org.organizationName),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          height: 1.2,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.priceDisplay,
                            style: AppTextStyle.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColorToken.primary.color,
                            ),
                          ),
                          if (product.ratingAverage > 0)
                            _RatingChip(rating: product.ratingAverage),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            size: 13,
                            color: AppColorToken.primary.color.withOpacity(0.8),
                          ),
                          4.horizontalSpace,
                          Expanded(
                            child: Text(
                              product.beneficiaryDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.bodySmall.copyWith(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
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

class _ProductCardImage extends StatelessWidget {
  final ProductModel product;
  const _ProductCardImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        product.coverImage != null
            ? CachedNetworkImage(
                imageUrl: product.coverImage!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColorToken.lightGrey.color),
                errorWidget: (_, __, ___) => _ImageFallback(product: product),
              )
            : _ImageFallback(product: product),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),
        if (product.displayVariants.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '${product.displayVariants.length} options',
                style: AppTextStyle.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColorToken.primary.color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ProductModel product;
  const _ImageFallback({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColorToken.lightGrey.color,
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: AppTextStyle.h2.copyWith(
            color: AppColorToken.primary.color.withOpacity(0.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        orgName,
        style: AppTextStyle.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColorToken.primary.color,
          letterSpacing: 0.2,
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
        Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
        2.horizontalSpace,
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyle.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
