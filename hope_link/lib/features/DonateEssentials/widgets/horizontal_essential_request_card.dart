import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

import '../controllers/donate_essentials_controller.dart';
import '../models/essential_models.dart';

class HorizontalEssentialRequestCard extends StatelessWidget {
  const HorizontalEssentialRequestCard({
    super.key,
    required this.request,
    required this.index,
    required this.controller,
    this.animationController,
  });

  final EssentialRequest request;
  final int index;
  final DonateEssentialsController controller;
  final AnimationController? animationController;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth >= 900
        ? 360.0
        : screenWidth >= 600
        ? 330.0
        : (screenWidth - 72).clamp(280.0, 340.0).toDouble();
    final isCompact = cardWidth <= 320;

    final card = GestureDetector(
      onTap: () async {
        await controller.loadRequestDetail(request.id);
        Get.toNamed('/essential-requests');
      },
      child: Container(
        width: cardWidth,
        height: isCompact ? 386 : 408,
        margin: EdgeInsets.only(left: index == 0 ? 24 : 12, right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(isCompact: isCompact),
            Expanded(child: _contentSection(isCompact: isCompact)),
          ],
        ),
      ),
    );

    if (animationController == null) return card;

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animationController!,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: card,
    );
  }

  Widget _imageSection({required bool isCompact}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: request.images.isNotEmpty
              ? Image.network(
                  request.images.first,
                  width: double.infinity,
                  height: isCompact ? 142 : 158,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholderImage(isCompact: isCompact),
                )
              : _placeholderImage(isCompact: isCompact),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withValues(alpha: 0.04),
                  AppColors.transparent,
                  AppColors.black.withValues(alpha: 0.46),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _topChip(
            icon: Icons.inventory_2_rounded,
            label: _categoryLabel,
            backgroundColor: AppColors.white.withValues(alpha: 0.92),
            foregroundColor: AppColors.primaryDark,
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _topChip(
            icon: Icons.schedule_rounded,
            label: request.daysRemaining > 0
                ? '${request.daysRemaining} days left'
                : 'Closing soon',
            backgroundColor: AppColors.black.withValues(alpha: 0.62),
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage({required bool isCompact}) {
    return Container(
      height: isCompact ? 142 : 158,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.accentLight.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Icon(
        Icons.volunteer_activism_rounded,
        color: AppColors.primary,
        size: isCompact ? 42 : 48,
      ),
    );
  }

  Widget _contentSection({required bool isCompact}) {
    final urgencyColor = _urgencyColor;
    final totals = request.reporting.totals;
    final requiredQuantity = totals.quantityRequired;
    final remainingQuantity = totals.quantityRemaining;
    final progress = request.fulfillmentRatio;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 16,
        isCompact ? 12 : 14,
        isCompact ? 14 : 16,
        isCompact ? 14 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metaPill(
                icon: Icons.priority_high_rounded,
                label: '${request.urgencyLevel.toUpperCase()} urgency',
                color: urgencyColor,
                compact: isCompact,
              ),
              _metaPill(
                icon: Icons.pin_drop_outlined,
                label: '${request.pickupLocations.length} pickup',
                color: AppColors.grey700,
                compact: isCompact,
              ),
            ],
          ),
          (isCompact ? 10 : 12).verticalSpace,
          Text(
            request.title,
            style: AppTextStyle.h5.copyWith(
              color: AppColors.grey900,
              fontWeight: FontWeight.w800,
              height: 1.25,
              fontSize: isCompact ? 13 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          6.verticalSpace,
          Text(
            request.description,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.grey600,
              height: 1.42,
              fontSize: isCompact ? 11 : 12,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          (isCompact ? 10 : 12).verticalSpace,
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$remainingQuantity items still needed',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: isCompact ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
                4.verticalSpace,
                Text(
                  '$requiredQuantity total requested',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: isCompact ? 10 : 11,
                  ),
                ),
                8.verticalSpace,
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.grey200,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          10.verticalSpace,
          Row(
            children: [
              Expanded(child: _itemsPreview(isCompact: isCompact)),
              8.horizontalSpace,
              _dateBadge(isCompact: isCompact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsPreview({required bool isCompact}) {
    final items = request.reporting.items.isNotEmpty
        ? request.reporting.items
        : request.itemsNeeded
              .map(
                (item) => EssentialReportingItem(
                  itemName: item.itemName,
                  unit: item.unit,
                  quantityRequired: item.quantityRequired,
                  quantityPledged: 0,
                  quantityFulfilled: item.quantityFulfilled,
                  quantityRemaining:
                      item.quantityRequired - item.quantityFulfilled,
                ),
              )
              .toList();

    if (items.isEmpty) {
      return Text(
        'View requested essentials',
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: isCompact ? 10 : 11,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.take(2).map((item) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.itemName,
            style: AppTextStyle.caption.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 9 : 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _dateBadge({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 9 : 10,
        vertical: isCompact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        DateFormat('MMM d').format(request.expiryDate),
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: isCompact ? 10 : 11,
        ),
      ),
    );
  }

  Widget _topChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foregroundColor),
          4.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          5.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  String get _categoryLabel {
    if (request.category.isEmpty) return 'Essentials';
    return '${request.category[0].toUpperCase()}${request.category.substring(1)}';
  }

  Color get _urgencyColor {
    switch (request.urgencyLevel.toLowerCase()) {
      case 'high':
        return AppColors.redAccent;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}

class VerticalEssentialRequestCard extends StatelessWidget {
  const VerticalEssentialRequestCard({
    super.key,
    required this.request,
    required this.controller,
    this.animationController,
    this.animationIndex = 0,
  });

  final EssentialRequest request;
  final DonateEssentialsController controller;
  final AnimationController? animationController;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor;
    final progress = request.fulfillmentRatio;
    final totals = request.reporting.totals;

    final card = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () async {
          await controller.loadRequestDetail(request.id);
          Get.toNamed('/essential-requests');
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.images.isNotEmpty) _imageHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _pill(
                          icon: Icons.inventory_2_rounded,
                          label: _categoryLabel,
                          color: AppColors.primary,
                        ),
                        8.horizontalSpace,
                        _pill(
                          icon: Icons.priority_high_rounded,
                          label:
                              '${request.urgencyLevel.toUpperCase()} urgency',
                          color: urgencyColor,
                        ),
                        const Spacer(),
                        Text(
                          request.daysRemaining > 0
                              ? '${request.daysRemaining}d left'
                              : 'Closing',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    Text(
                      request.title,
                      style: AppTextStyle.h5.copyWith(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    6.verticalSpace,
                    Text(
                      request.description,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.grey600,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    14.verticalSpace,
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${totals.quantityRemaining} items still needed',
                                  style: AppTextStyle.bodyMedium.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: AppColors.grey700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          8.verticalSpace,
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              color: AppColors.primary,
                              backgroundColor: AppColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),
                    12.verticalSpace,
                    Row(
                      children: [
                        Expanded(child: _itemsPreview()),
                        10.horizontalSpace,
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (animationController == null) return card;

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animationController!,
          curve: Interval(
            (animationIndex * 0.08).clamp(0.0, 1.0),
            ((animationIndex * 0.08) + 0.28).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: card,
    );
  }

  Widget _imageHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Image.network(
        request.images.first,
        width: double.infinity,
        height: 156,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _itemsPreview() {
    final items = request.reporting.items.isNotEmpty
        ? request.reporting.items
        : request.itemsNeeded
              .map(
                (item) => EssentialReportingItem(
                  itemName: item.itemName,
                  unit: item.unit,
                  quantityRequired: item.quantityRequired,
                  quantityPledged: 0,
                  quantityFulfilled: item.quantityFulfilled,
                  quantityRemaining:
                      item.quantityRequired - item.quantityFulfilled,
                ),
              )
              .toList();

    if (items.isEmpty) {
      return Text(
        'View requested essentials',
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.take(3).map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.itemName,
            style: AppTextStyle.caption.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          5.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String get _categoryLabel {
    if (request.category.isEmpty) return 'Essentials';
    return '${request.category[0].toUpperCase()}${request.category.substring(1)}';
  }

  Color get _urgencyColor {
    switch (request.urgencyLevel.toLowerCase()) {
      case 'high':
        return AppColors.redAccent;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}
