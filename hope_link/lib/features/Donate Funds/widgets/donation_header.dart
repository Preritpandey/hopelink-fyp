import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/campaign_controller.dart';

class DonationHeader extends StatelessWidget {
  const DonationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final CampaignController campaignController = Get.put(CampaignController());

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
