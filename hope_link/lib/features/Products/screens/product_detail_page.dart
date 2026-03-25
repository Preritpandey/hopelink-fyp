import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/app_colors.dart';
import '../widgets/product_image_gallery.dart';
import '../widgets/variant_selector.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Get or put controller; select the product for reactive state
    final controller = Get.find<ProductController>();
    controller.selectProduct(product);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _DetailAppBar(product: product),
              SliverToBoxAdapter(child: _DetailBody(controller: controller)),
              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Bottom Action Bar ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AddToCartBar(controller: controller),
          ),
        ],
      ),
    );
  }
}

// ── App Bar with image gallery ────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final ProductModel product;
  const _DetailAppBar({required this.product});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width, // square
      pinned: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppColors.surface.withOpacity(0.9),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppColors.surface.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(
                Icons.share_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () {
                // Share logic here
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ProductImageGallery(images: product.images),
      ),
    );
  }
}

// ── Main detail body ──────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final ProductController controller;
  const _DetailBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    if (product == null) return const SizedBox.shrink();

    final activeVariants = controller.activeVariantsFor(product);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Organization + Rating ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OrgPill(orgName: product.org.organizationName),
              if (product.ratingCount > 0)
                _RatingDisplay(
                  rating: product.ratingAverage,
                  count: product.ratingCount,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Product Name ────────────────────────────────────────────────
          Text(
            product.name,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // ── Price ───────────────────────────────────────────────────────
          _PriceDisplay(controller: controller, product: product),
          const SizedBox(height: 24),

          // ── Variant Selector ────────────────────────────────────────────
          if (activeVariants.length > 1) ...[
            VariantSelector(
              variants: activeVariants,
              selectedVariant: controller.selectedVariant,
              onSelected: controller.selectVariant,
            ),
            const SizedBox(height: 24),
          ],

          // ── Divider ─────────────────────────────────────────────────────
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 20),

          // ── Description ─────────────────────────────────────────────────
          const Text(
            'About this product',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),

          // ── Beneficiary Card ─────────────────────────────────────────────
          _BeneficiaryCard(description: product.beneficiaryDescription),
          const SizedBox(height: 20),

          // ── Stock Info ───────────────────────────────────────────────────
          Obx(() {
            if (controller.selectedVariant != null)
              return _StockBadge(variant: controller.selectedVariant!);
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

// ── Add to cart bar ───────────────────────────────────────────────────────────

class _AddToCartBar extends StatelessWidget {
  final ProductController controller;
  const _AddToCartBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final variant = controller.selectedVariant;
      final inStock = variant?.inStock ?? false;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    variant != null
                        ? 'NPR ${variant.price.toStringAsFixed(0)}'
                        : '—',
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Add to cart button
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: inStock
                    ? () {
                        // Cart logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Added to cart!',
                              style: TextStyle(fontFamily: 'DM Sans'),
                            ),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.shimmer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  inStock
                      ? Icons.shopping_bag_outlined
                      : Icons.remove_shopping_cart_outlined,
                  size: 20,
                ),
                label: Text(
                  inStock ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _OrgPill extends StatelessWidget {
  final String orgName;
  const _OrgPill({required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          orgName,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingDisplay({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.starColor),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PriceDisplay extends StatelessWidget {
  final ProductController controller;
  final ProductModel product;
  const _PriceDisplay({required this.controller, required this.product});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final variant = controller.selectedVariant;
      final displayPrice = variant != null
          ? 'NPR ${variant.price.toStringAsFixed(0)}'
          : product.priceDisplay;

      return Row(
        children: [
          Text(
            displayPrice,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (product.minPrice != product.maxPrice && variant == null)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 8),
              child: Text(
                'varies by option',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _BeneficiaryCard extends StatelessWidget {
  final String description;
  const _BeneficiaryCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Impact',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final ProductVariant variant;
  const _StockBadge({required this.variant});

  @override
  Widget build(BuildContext context) {
    final inStock = variant.inStock;
    final color = inStock ? AppColors.accent : AppColors.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            inStock ? '${variant.stock} in stock' : 'Out of stock',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
