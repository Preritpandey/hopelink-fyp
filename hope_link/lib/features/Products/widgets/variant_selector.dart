import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'app_colors.dart';

/// Displays variant chips (color / size / etc.) and notifies on selection.
class VariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onSelected;

  const VariantSelector({
    super.key,
    required this.variants,
    required this.selectedVariant,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Option',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = selectedVariant?.id == variant.id;
            final outOfStock = !variant.inStock;

            return GestureDetector(
              onTap: outOfStock ? null : () => onSelected(variant),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : outOfStock
                      ? AppColors.shimmer
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : outOfStock
                        ? AppColors.divider
                        : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.attributes.displayLabel,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : outOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: outOfStock
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outOfStock
                          ? 'Out of stock'
                          : 'NPR ${variant.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : outOfStock
                            ? AppColors.textMuted
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
}
