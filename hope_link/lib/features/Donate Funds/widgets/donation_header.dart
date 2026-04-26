import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/features/Profile/controllers/volunteer_credit_controller.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/campaign_controller.dart';

class DonationHeader extends StatelessWidget {
  final String? token;

  const DonationHeader({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    final CampaignController campaignController = Get.put(CampaignController());
    final VolunteerCreditController? creditController =
        token != null && token!.isNotEmpty
            ? (Get.isRegistered<VolunteerCreditController>()
                ? Get.find<VolunteerCreditController>()
                : Get.put(VolunteerCreditController(token!)))
            : (Get.isRegistered<VolunteerCreditController>()
                ? Get.find<VolunteerCreditController>()
                : null);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, isCompact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? screenWidth - 48 : 220,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Campaigns',
                      style: AppTextStyle.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorToken.primary.color,
                      ),
                    ),
                    // Obx(
                    //   () => Text(
                    //     '${campaignController.filteredCampaigns.length} active campaigns',
                    //     style: AppTextStyle.bodySmall.copyWith(
                    //       color: Colors.grey[600],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              SizedBox(
                width: isCompact ? screenWidth - 48 : null,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment:
                      isCompact ? WrapAlignment.start : WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildHeaderAction(
                          label: 'Essentials',
                          icon: Icons.inventory_2_outlined,
                          onPressed: () => Get.toNamed('/essentials'),
                          compact: isCompact,
                        ),
                        if (creditController != null)
                          _buildPointsBadge(creditController),
                      ],
                    ),
                    Obx(
                      () => campaignController.isOfflineMode.value
                          ? _buildOfflineBadge()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool compact,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildPointsBadge(VolunteerCreditController controller) {
    return Obx(() {
      final credits = controller.credits.value;
      final isLoading = controller.isLoading.value && credits == null;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColorToken.primary.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Points',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorToken.primary.color,
                ),
              )
            else
              Text(
                '${credits?.totalPoints ?? 0}',
                style: AppTextStyle.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorToken.primary.color,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
