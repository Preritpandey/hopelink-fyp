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
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color,
              AppColorToken.primary.color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NPR ${NumberFormat('#,##0').format(controller.totalDonated)}',
              style: AppTextStyle.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            Text(
              'total donated',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatItem(
                  icon: Icons.favorite_rounded,
                  count: controller.donationCount,
                  label: 'Donations',
                  color: Colors.white,
                ),
                _Divider(),
                _StatItem(
                  icon: Icons.event_available_rounded,
                  count: controller.eventCount,
                  label: 'Events',
                  color: Colors.white,
                ),
                _Divider(),
                _StatItem(
                  icon: Icons.volunteer_activism_rounded,
                  count: controller.volunteerCount,
                  label: 'Volunteer',
                  color: Colors.white,
                ),
              ],
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
        children: [
          Icon(icon, color: color.withOpacity(0.85), size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyle.h4.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: color.withOpacity(0.65),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.25),
    );
  }
}
