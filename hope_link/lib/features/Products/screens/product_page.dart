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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

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
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _controller.searchProducts(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color.withOpacity(0.06),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.04),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _controller.refreshProducts,
            color: AppColorToken.primary.color,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _HeaderSection(controller: _controller),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _SearchSection(
                        controller: _searchController,
                        searchText: _searchText,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _controller.searchProducts('');
                        },
                      ),
                    ),
                  ),
                ),
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
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final ProductController controller;
  const _HeaderSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Marketplace',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColorToken.primary.color,
              ),
            ),
          ),
          12.horizontalSpace,
          IconButton(
            onPressed: controller.refreshProducts,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColorToken.primary.color,
            tooltip: 'Refresh',
          ),
          Obx(
            () => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => Get.toNamed('/cart'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  color: AppColorToken.primary.color,
                  tooltip: 'Cart',
                ),
                if (cartController.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${cartController.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/orders'),
            icon: const Icon(Icons.local_shipping_outlined),
            color: AppColorToken.primary.color,
            tooltip: 'Orders',
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final RxString searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchSection({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
              suffixIcon: searchText.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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

  const _ProductsGrid({
    required this.controller,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      sliver: Obx(() {
        final products = controller.products;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            // Load-more trigger
            if (index == products.length - 1 &&
                controller.currentPage < controller.totalPages) {
              controller.loadMoreProducts();
            }

            if (products[index] == products.last && controller.isLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorToken.primary.color,
                  ),
                ),
              );
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
          }, childCount: products.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
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
            strokeWidth: 2,
          ),
          16.verticalSpace,
          Text(
            'Loading products...',
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
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
                color: AppColorToken.error.color.withOpacity(0.08),
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
                color: Colors.grey[700],
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
                  color: Colors.white,
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
                color: AppColorToken.primary.color.withOpacity(0.08),
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
                color: Colors.grey[900],
              ),
            ),
            8.verticalSpace,
            Text(
              'Check back soon ? our artisans are crafting something special.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
