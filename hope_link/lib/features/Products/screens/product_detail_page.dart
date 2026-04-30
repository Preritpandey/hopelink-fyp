import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/features/Commerce/controllers/cart_controller.dart';

import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/app_colors.dart';
import '../widgets/product_image_gallery.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());
    controller.selectProduct(product);
    final content = _ProductContent.fromProduct(product);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _NaturalBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _DetailAppBar(product: product, content: content),
              SliverToBoxAdapter(
                child: _DetailBody(
                  controller: controller,
                  content: content,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 112)),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StickyAddToCartBar(
              controller: controller,
              cartController: cartController,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductContent {
  final String title;
  final String brandTag;
  final String narrative;
  final List<String> specs;
  final String impactTitle;
  final String impactDescription;
  final List<String> craftsmanshipTags;

  const _ProductContent({
    required this.title,
    required this.brandTag,
    required this.narrative,
    required this.specs,
    required this.impactTitle,
    required this.impactDescription,
    required this.craftsmanshipTags,
  });

  factory _ProductContent.fromProduct(ProductModel product) {
    final orgName = product.org.organizationName.trim().isEmpty
        ? 'HopeLink Artisan Collective'
        : product.org.organizationName.trim();
    final baseDescription = product.description.trim();
    final lowerCombined =
        '${product.name} ${product.description} ${product.category}'
            .toLowerCase();
    final scarfLike = lowerCombined.contains('scarf') ||
        lowerCombined.contains('wool') ||
        lowerCombined.contains('leno') ||
        lowerCombined.contains('woven');

    final title = scarfLike
        ? 'Hand-Woven Leno Scarf'
        : _normalizeTitle(product.name);

    final narrative = scarfLike
        ? 'Handmade on a rigid heddle loom, this airy scarf features a beautiful Leno lacy texture with soft fringe detailing for a refined handmade finish.'
        : _normalizeNarrative(baseDescription);

    final specs = scarfLike
        ? const [
            'Material: 100% Pure Wool',
            'Dimensions: 165cm x 20cm',
            'Technique: Rigid Heddle Loom & Leno Weave',
            'Finish: Hand-tied fringe edges',
          ]
        : _genericSpecs(product);

    final impactTitle = 'Community Impact';
    final impactDescription = product.beneficiaryDescription.trim().isNotEmpty
        ? product.beneficiaryDescription.trim()
        : scarfLike
            ? 'Every purchase helps support elderly weavers with sustainable income, preserving traditional weaving skills and dignified community livelihoods.'
            : 'Each purchase supports artisan communities through income-generating craft work and locally rooted production.';

    final craftsmanshipTags = scarfLike
        ? const ['Handwoven', 'Natural fibers', 'Artisan made']
        : const ['Handmade', 'Purposeful purchase', 'Small-batch'];

    return _ProductContent(
      title: title,
      brandTag: 'By $orgName',
      narrative: narrative,
      specs: specs,
      impactTitle: impactTitle,
      impactDescription: impactDescription,
      craftsmanshipTags: craftsmanshipTags,
    );
  }

  static String _normalizeTitle(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Handcrafted Product';
    if (trimmed.toLowerCase() == 'doko') {
      return 'Hand-Woven Wool Scarf';
    }
    return trimmed;
  }

  static String _normalizeNarrative(String description) {
    if (description.isEmpty) {
      return 'Thoughtfully crafted by community makers, designed to feel warm, useful, and distinctly handmade.';
    }
    return description;
  }

  static List<String> _genericSpecs(ProductModel product) {
    final specs = <String>[
      if (product.category.trim().isNotEmpty)
        'Category: ${product.category.trim()}',
      'Craft: Handmade artisan product',
      'Availability: Small-batch production',
    ];
    return specs;
  }
}

class _NaturalBackdrop extends StatelessWidget {
  const _NaturalBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              const Color(0xFFF8F5ED),
              AppColors.accent.withOpacity(0.08),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -18,
              child: _BackdropOrb(
                size: 150,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
            Positioned(
              top: 220,
              left: -42,
              child: _BackdropOrb(
                size: 120,
                color: AppColors.accent.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: 160,
              right: -38,
              child: _BackdropOrb(
                size: 130,
                color: AppColors.primaryLight.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final ProductModel product;
  final _ProductContent content;

  const _DetailAppBar({required this.product, required this.content});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).width * 1.12,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: _SoftIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _SoftIconButton(
            icon: Icons.ios_share_rounded,
            onPressed: () {},
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
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.42),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _HeroInfoCard(content: content),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SoftIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  final _ProductContent content;

  const _HeroInfoCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Handmade Essential',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.brandTag,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ProductController controller;
  final _ProductContent content;

  const _DetailBody({
    required this.controller,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    if (product == null) return const SizedBox.shrink();

    final activeVariants = controller.activeVariantsFor(product);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriceAndTrustCard(
            controller: controller,
            product: product,
            craftsmanshipTags: content.craftsmanshipTags,
          ),
          const SizedBox(height: 18),
          if (activeVariants.length > 1)
            Obx(
              () => _BentoCard(
                child: _ColorVariantPicker(
                  variants: activeVariants,
                  selectedVariant: controller.selectedVariant,
                  onSelected: controller.selectVariant,
                ),
              ),
            ),
          if (activeVariants.length > 1) const SizedBox(height: 18),
          _BentoCard(
            child: _StorySection(content: content),
          ),
          const SizedBox(height: 18),
          _BentoCard(
            child: _SpecsSection(specs: content.specs),
          ),
          const SizedBox(height: 18),
          _ImpactCard(
            title: content.impactTitle,
            description: content.impactDescription,
          ),
          const SizedBox(height: 18),
          Obx(() {
            final variant = controller.selectedVariant;
            if (variant == null) return const SizedBox.shrink();
            return _AvailabilityCard(variant: variant);
          }),
        ],
      ),
    );
  }
}

class _PriceAndTrustCard extends StatelessWidget {
  final ProductController controller;
  final ProductModel product;
  final List<String> craftsmanshipTags;

  const _PriceAndTrustCard({
    required this.controller,
    required this.product,
    required this.craftsmanshipTags,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final variant = controller.selectedVariant;
      final displayPrice = variant != null
          ? variant.price
          : product.basePrice;

      return _BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NPR ${displayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (product.ratingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.starColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${product.ratingAverage.toStringAsFixed(1)} (${product.ratingCount})',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: craftsmanshipTags
                  .map((tag) => _SoftTag(label: tag))
                  .toList(),
            ),
          ],
        ),
      );
    });
  }
}

class _ColorVariantPicker extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onSelected;

  const _ColorVariantPicker({
    required this.variants,
    required this.selectedVariant,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Color',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your preferred tone. Price stays consistent across the available options.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: variants.map((variant) {
            final isSelected = selectedVariant?.id == variant.id;
            final outOfStock = !variant.inStock;
            final label = _variantColorLabel(variant);
            final swatch = _colorForVariant(label);

            return GestureDetector(
              onTap: outOfStock ? null : () => onSelected(variant),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : outOfStock
                            ? AppColors.divider
                            : AppColors.divider,
                    width: isSelected ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: swatch.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: outOfStock
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          outOfStock ? 'Out of stock' : 'Ready to add',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: outOfStock
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _variantColorLabel(ProductVariant variant) {
    final color = variant.attributes.color?.trim();
    if (color != null && color.isNotEmpty) return color;
    final label = variant.attributes.displayLabel.trim();
    return label.isEmpty ? 'Artisan tone' : label;
  }

  Color _colorForVariant(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('red')) return const Color(0xFFB5453C);
    if (normalized.contains('blue')) return const Color(0xFF5A7396);
    if (normalized.contains('green')) return const Color(0xFF7C9A6D);
    if (normalized.contains('pink')) return const Color(0xFFD59A9D);
    if (normalized.contains('cinnamon')) return const Color(0xFFA46745);
    if (normalized.contains('orange')) return const Color(0xFFD48A54);
    return AppColors.accent;
  }
}

class _StorySection extends StatelessWidget {
  final _ProductContent content;

  const _StorySection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Piece',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.narrative,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            height: 1.7,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SpecsSection extends StatelessWidget {
  final List<String> specs;

  const _SpecsSection({required this.specs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Details',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...specs.map(
          (spec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spec,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String title;
  final String description;

  const _ImpactCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.14),
            const Color(0xFFF8F5ED),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    height: 1.65,
                    color: AppColors.textSecondary,
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

class _AvailabilityCard extends StatelessWidget {
  final ProductVariant variant;

  const _AvailabilityCard({required this.variant});

  @override
  Widget build(BuildContext context) {
    final inStock = variant.inStock;
    final color = inStock ? AppColors.successColor : AppColors.errorColor;

    return _BentoCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              inStock ? Icons.inventory_2_outlined : Icons.error_outline_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inStock ? 'Available now' : 'Currently unavailable',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inStock
                      ? '${variant.stock} pieces ready to ship'
                      : 'This color is temporarily out of stock.',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

class _StickyAddToCartBar extends StatelessWidget {
  final ProductController controller;
  final CartController cartController;

  const _StickyAddToCartBar({
    required this.controller,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final variant = controller.selectedVariant;
      final inStock = variant != null
          ? variant.inStock
          : _productInStock(controller.selectedProduct);

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () => Get.toNamed('/cart'),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: inStock
                      ? () {
                          final product = controller.selectedProduct;
                          if (product == null) return;
                          cartController.addToCart(
                            productId: product.id,
                            variantId: variant?.id,
                            quantity: 1,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.shimmer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  bool _productInStock(ProductModel? product) {
    if (product == null) return false;
    return product.inStock;
  }
}

class _SoftTag extends StatelessWidget {
  final String label;

  const _SoftTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final Widget child;

  const _BentoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
