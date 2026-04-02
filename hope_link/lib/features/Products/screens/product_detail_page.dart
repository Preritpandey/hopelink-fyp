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
    final controller = Get.find<ProductController>();
    controller.selectProduct(product);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _PlayfulBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _DetailAppBar(product: product),
              SliverToBoxAdapter(child: _DetailBody(controller: controller)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
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

class _PlayfulBackdrop extends StatelessWidget {
  const _PlayfulBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.12),
              AppColors.background,
              AppColors.accent.withOpacity(0.12),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _Blob(
                size: 160,
                color: AppColors.accent.withOpacity(0.18),
              ),
            ),
            Positioned(
              top: 180,
              left: -60,
              child: _Blob(
                size: 200,
                color: AppColors.primary.withOpacity(0.14),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -50,
              child: _Blob(
                size: 180,
                color: AppColors.accentLight.withOpacity(0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.45),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final ProductModel product;
  const _DetailAppBar({required this.product});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width * 1.05,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _GlassIconButton(
            icon: Icons.share_outlined,
            onPressed: () {
              // Share logic here
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageGallery(images: product.images),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: _HeroOverlay(product: product),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ProductController controller;
  const _DetailBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    if (product == null) return const SizedBox.shrink();

    final activeVariants = controller.activeVariantsFor(product);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaRow(
            left: _OrgPill(orgName: product.org.organizationName),
            right: product.ratingCount > 0
                ? _RatingDisplay(
                    rating: product.ratingAverage,
                    count: product.ratingCount,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          _TitleBlock(product: product),
          const SizedBox(height: 14),
          _PriceDisplay(controller: controller, product: product),
          const SizedBox(height: 18),
          _InfoChips(
            category: product.category,
            ratingCount: product.ratingCount,
          ),
          const SizedBox(height: 24),
          if (activeVariants.length > 1) ...[
            Obx(
              () => _SectionCard(
                title: 'Choose a variant',
                child: VariantSelector(
                  variants: activeVariants,
                  selectedVariant: controller.selectedVariant,
                  onSelected: controller.selectVariant,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          _SectionCard(
            title: 'About this product',
            child: Text(
              product.description,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _BeneficiaryCard(description: product.beneficiaryDescription),
          const SizedBox(height: 18),
          Obx(() {
            if (controller.selectedVariant != null) {
              return _StockBadge(variant: controller.selectedVariant!);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primary.withOpacity(0.06)),
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
            _PricePill(variant: variant),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: inStock
                    ? () {
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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class _HeroOverlay extends StatelessWidget {
  final ProductModel product;
  const _HeroOverlay({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrgPill(orgName: product.org.organizationName),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(
                icon: Icons.category_outlined,
                label: product.category.isEmpty ? 'Curated' : product.category,
              ),
              if (product.ratingCount > 0) ...[
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.star_rounded,
                  label: product.ratingAverage.toStringAsFixed(1),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

class _MetaRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const _MetaRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        left,
        if (right != null) right!,
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final ProductModel product;
  const _TitleBlock({required this.product});

  @override
  Widget build(BuildContext context) {
    return Text(
      product.name,
      style: const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
    );
  }
}

class _InfoChips extends StatelessWidget {
  final String category;
  final int ratingCount;
  const _InfoChips({required this.category, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          icon: Icons.category_outlined,
          label: category.isEmpty ? 'Curated' : category,
        ),
        if (ratingCount > 0)
          const _Chip(
            icon: Icons.verified_rounded,
            label: 'Artisan verified',
          ),
        const _Chip(
          icon: Icons.local_shipping_outlined,
          label: 'Nationwide delivery',
        ),
        const _Chip(
          icon: Icons.spa_outlined,
          label: 'Handmade',
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final ProductVariant? variant;
  const _PricePill({required this.variant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.18),
            AppColors.accent.withOpacity(0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
            variant != null ? 'NPR ${variant!.price.toStringAsFixed(0)}' : '--',
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
