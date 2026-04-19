import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
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

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (creditController != null) ...[
                    _buildPointsBadge(creditController),
                    10.horizontalSpace,
                  ],
                  Obx(
                    () => campaignController.isOfflineMode.value
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
          // if (campaignController.lastSyncTime.value != null) ...[
          //   8.verticalSpace,
          //   // Obx(
          //   //   () => Text(
          //   //     'Last updated: ${_formatLastSync(campaignController.lastSyncTime.value!)}',
          //   //     style: AppTextStyle.bodySmall.copyWith(
          //   //       color: Colors.grey[500],
          //   //       fontSize: 11,
          //   //     ),
          //   //   ),
          //   // ),
          // ],
        ],
      ),
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
