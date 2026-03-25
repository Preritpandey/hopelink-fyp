import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../widgets/app_colors.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          _ProductsAppBar(controller: controller),

          // ── Body ─────────────────────────────────────────────────────────
          Obx(() {
            if (controller.isLoading && !controller.hasProducts) {
              return const SliverFillRemaining(child: _LoadingState());
            }

            if (controller.hasError && !controller.hasProducts) {
              return SliverFillRemaining(
                child: _ErrorState(
                  message: controller.errorMessage,
                  onRetry: controller.refreshProducts,
                ),
              );
            }

            if (!controller.hasProducts) {
              return const SliverFillRemaining(child: _EmptyState());
            }

            return _ProductsGrid(controller: controller);
          }),
        ],
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _ProductsAppBar extends StatelessWidget {
  final ProductController controller;
  const _ProductsAppBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.shadow,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB85C38), Color(0xFF8C3D20)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Marketplace',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  '${controller.total} handcrafted products',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: controller.refreshProducts,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Products Grid ─────────────────────────────────────────────────────────────

class _ProductsGrid extends StatelessWidget {
  final ProductController controller;
  const _ProductsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: Obx(() {
        final products = controller.products;
        return SliverGrid(
          delegate: SliverChildBuilderDelegate((context, index) {
            // Load-more trigger
            if (index == products.length - 1 &&
                controller.currentPage < controller.totalPages) {
              controller.loadMoreProducts();
            }

            return products[index] == products.last && controller.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ProductCard(product: products[index]);
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

// ── State Widgets ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Loading products…',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: AppColors.textMuted,
            ),
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
                color: AppColors.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w600,
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
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No products yet',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon — our artisans are crafting something special.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
