import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/activity_controller.dart';

class ActivityStatsHeader extends StatelessWidget {
  const ActivityStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ActivityController>();

    return Obx(() {
      if (controller.isLoading.value && controller.filteredActivities.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColorToken.lightBackgroundPrimary.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorToken.primary.color.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Impact',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColorToken.lightGreyAccent.color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NPR ${NumberFormat('#,##0').format(controller.totalDonated)}',
                    style: AppTextStyle.h3.copyWith(
                      color: AppColorToken.primary.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'total donated',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColorToken.lightGreyAccent.color,
                    ),
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 10),
            // _Divider(),
            // const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    icon: Icons.favorite_rounded,
                    count: controller.donationCount,
                    label: 'Donations',
                    color: AppColorToken.primary.color,
                  ),
                  _StatItem(
                    icon: Icons.event_available_rounded,
                    count: controller.eventCount,
                    label: 'Events',
                    color: AppColorToken.primary.color,
                  ),
                  _StatItem(
                    icon: Icons.volunteer_activism_rounded,
                    count: controller.volunteerCount,
                    label: 'Volunteer',
                    color: AppColorToken.primary.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.85), size: 16),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: AppTextStyle.h6.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: color.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
