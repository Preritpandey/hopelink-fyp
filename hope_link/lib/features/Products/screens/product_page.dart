import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Commerce/controllers/cart_controller.dart';

import '../controllers/product_controller.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with SingleTickerProviderStateMixin {
  late final ProductController _controller = Get.put(ProductController());
  late final CartController _cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());

  final TextEditingController _searchController = TextEditingController();
  final RxString _searchText = ''.obs;
  Timer? _searchDebounce;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _searchController.addListener(() {
      _searchText.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      _controller.searchProducts(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _controller.searchProducts('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primarySoft,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 20.0;

            return RefreshIndicator(
              onRefresh: _controller.refreshProducts,
              color: AppColorToken.primary.color,
              backgroundColor: AppColors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _MarketplaceHeader(
                        controller: _controller,
                        cartController: _cartController,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _MarketplaceSearchBar(
                        controller: _searchController,
                        searchText: _searchText,
                        onChanged: _onSearchChanged,
                        onClear: _clearSearch,
                      ),
                    ),
                  ),
                  // SliverPadding(
                  //   padding: EdgeInsets.fromLTRB(
                  //     horizontalPadding,
                  //     16,
                  //     horizontalPadding,
                  //     8,
                  //   ),
                  //   sliver: SliverToBoxAdapter(
                  //     child: Obx(
                  //       () => _MarketplaceSummary(
                  //         productCountLabel: 'Curated products',
                  //         productCount: _controller.products.length.toString(),
                  //         subtitle:
                  //             'Handpicked goods from artisan partners and community sellers.',
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Obx(() {
                    if (_controller.isLoading && !_controller.hasProducts) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadingState(),
                      );
                    }

                    if (_controller.hasError && !_controller.hasProducts) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          message: _controller.errorMessage,
                          onRetry: _controller.refreshProducts,
                        ),
                      );
                    }

                    if (!_controller.hasProducts) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      );
                    }

                    return _ProductsGrid(
                      controller: _controller,
                      animationController: _animationController,
                      maxWidth: constraints.maxWidth,
                      horizontalPadding: horizontalPadding,
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarketplaceHeader extends StatelessWidget {
  final ProductController controller;
  final CartController cartController;

  const _MarketplaceHeader({
    required this.controller,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketplace',
                      style: AppTextStyle.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColorToken.primary.color,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'Discover artisan products and everyday essentials',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.grey600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: controller.refreshProducts,
              ),
              8.horizontalSpace,
              Obx(
                () => _HeaderIconButton(
                  icon: Icons.shopping_cart_outlined,
                  tooltip: 'Cart',
                  onTap: () => Get.toNamed('/cart'),
                  badgeLabel: cartController.itemCount > 0
                      ? '${cartController.itemCount}'
                      : null,
                ),
              ),
              8.horizontalSpace,
              _HeaderIconButton(
                icon: Icons.local_shipping_outlined,
                tooltip: 'Orders',
                onTap: () => Get.toNamed('/orders'),
              ),
            ],
          ),
          16.verticalSpace,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                icon: Icons.verified_rounded,
                label: 'Curated sellers',
              ),
              _HeaderChip(icon: Icons.eco_rounded, label: 'Ethical sourcing'),
              _HeaderChip(
                icon: Icons.favorite_border_rounded,
                label: 'Community impact',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? badgeLabel;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.grey800, size: 22),
            ),
            if (badgeLabel != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorToken.primary.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColorToken.primary.color),
          6.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColorToken.primary.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final RxString searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _MarketplaceSearchBar({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search products, artisans, or causes...',
            hintStyle: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.grey400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Icon(Icons.search_rounded, color: AppColors.grey500),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: searchText.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: AppColors.grey400),
                    onPressed: onClear,
                  )
                : const SizedBox.shrink(),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final ProductController controller;
  final AnimationController animationController;
  final double maxWidth;
  final double horizontalPadding;

  const _ProductsGrid({
    required this.controller,
    required this.animationController,
    required this.maxWidth,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
      sliver: Obx(() {
        final availableWidth = maxWidth - (horizontalPadding * 2);
        final crossAxisCount = availableWidth >= 1100
            ? 4
            : availableWidth >= 720
            ? 3
            : 2;
        const gridSpacing = 16.0;
        final cardWidth =
            (availableWidth - (gridSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final cardHeight = (cardWidth * 1.55).clamp(300.0, 360.0);
        final products = controller.products;
        final showLoadingMore = controller.currentPage < controller.totalPages;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == products.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColorToken.primary.color,
                  ),
                ),
              );
            }

            if (index == products.length - 1 &&
                showLoadingMore &&
                !controller.isLoading) {
              controller.loadMoreProducts();
            }

            final animation = CurvedAnimation(
              parent: animationController,
              curve: Interval(
                (index * 0.06).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: ProductCard(product: products[index]),
              ),
            );
          }, childCount: products.length + (showLoadingMore ? 1 : 0)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: gridSpacing,
            crossAxisSpacing: gridSpacing,
            mainAxisExtent: cardHeight,
          ),
        );
      }),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColorToken.primary.color,
            strokeWidth: 2.2,
          ),
          16.verticalSpace,
          Text(
            'Loading products...',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColorToken.error.color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColorToken.error.color,
              ),
            ),
            20.verticalSpace,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
            24.verticalSpace,
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColorToken.primary.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorToken.primary.color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 46,
                color: AppColorToken.primary.color,
              ),
            ),
            20.verticalSpace,
            Text(
              'No products yet',
              style: AppTextStyle.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            8.verticalSpace,
            Text(
              'Check back soon. Our artisans are crafting something special.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
