import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_colors.dart';

/// Full-width image gallery with dot indicators and swipe support.
class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  const ProductImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.onPageChanged,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return _EmptyImage();

    return Stack(
      children: [
        // Main gallery
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              widget.onPageChanged?.call(i);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.shimmer,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.shimmer,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),

        // Dot indicators
        if (widget.images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        // Thumbnail strip
        if (widget.images.length > 1)
          Positioned(
            bottom: 36,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isActive = index == _currentIndex;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: AppColors.shimmer,
        child: const Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
