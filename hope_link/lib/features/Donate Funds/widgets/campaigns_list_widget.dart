import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

import '../controllers/campaign_controller.dart';
import '../models/campaign_model.dart';
import 'post_interaction_summary.dart';

class CampaignsListWidget extends StatelessWidget {
  final CampaignController controller;
  final AnimationController animationController;

  const CampaignsListWidget({
    super.key,
    required this.controller,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.campaigns.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.filteredCampaigns.isEmpty) {
        return _buildEmptyState();
      }

      return _buildCampaignsList();
    });
  }

  Widget _buildCampaignsList() {
    return RefreshIndicator(
      onRefresh: controller.refreshCampaigns,
      color: AppColorToken.primary.color,
      backgroundColor: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: controller.filteredCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = controller.filteredCampaigns[index];
          return _buildCampaignCard(campaign, index);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign, int index) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        child: GestureDetector(
          onTap: () => Get.toNamed('/campaign-details', arguments: campaign.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {},
            onExit: (_) {},
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with overlays
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: campaign.images.isNotEmpty
                            ? Image.network(
                                campaign.images[0],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColorToken.primary.color
                                              .withOpacity(0.1),
                                          AppColorToken.primary.color
                                              .withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 64,
                                        color: AppColorToken.primary.color
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColorToken.primary.color.withOpacity(
                                        0.1,
                                      ),
                                      AppColorToken.primary.color.withOpacity(
                                        0.05,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: AppColorToken.primary.color
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                      ),
                      // Status badge - Featured
                      if (campaign.isFeatured)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFDB927),
                                  const Color(0xFFFCA311),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFDB927,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Featured',
                                  style: AppTextStyle.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Status badge - Draft
                      if (!campaign.isActive)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Draft',
                              style: AppTextStyle.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      // Category tag
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Campaign',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColorToken.primary.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          campaign.title,
                          style: AppTextStyle.h5.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        12.verticalSpace,
                        // Organization info
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Get.toNamed(
                                '/organization-profile',
                                arguments: campaign.organization.id,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColorToken.primary.color
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.business_rounded,
                                      size: 14,
                                      color: AppColorToken.primary.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    campaign.organization.organizationName,
                                    style: AppTextStyle.bodySmall.copyWith(
                                      color: AppColorToken.primary.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        PostInteractionSummary(
                          totalLikes: campaign.totalLikes,
                          commentsCount: campaign.commentsCount,
                          accentColor: AppColorToken.primary.color,
                        ),

                        20.verticalSpace,
                        // Funding progress section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amount and percentage
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Raised',
                                        style: AppTextStyle.bodySmall.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      4.verticalSpace,
                                      Text(
                                        _formatCurrency(campaign.currentAmount),
                                        style: AppTextStyle.h5.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColorToken.primary.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColorToken.primary.color
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${campaign.progress.toStringAsFixed(0)}%',
                                      style: AppTextStyle.bodyMedium.copyWith(
                                        color: AppColorToken.primary.color,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              12.verticalSpace,
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (campaign.progress / 100).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColorToken.primary.color,
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                              12.verticalSpace,
                              // Target amount
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Goal: ${_formatCurrency(campaign.targetAmount)}',
                                    style: AppTextStyle.bodySmall.copyWith(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (campaign.progress >= 100)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Funded',
                                            style: AppTextStyle.bodySmall
                                                .copyWith(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'NPR ${formatter.format(amount)}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColorToken.primary.color.withOpacity(0.3),
                  AppColorToken.primary.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColorToken.primary.color,
                ),
                strokeWidth: 4,
              ),
            ),
          ),
          24.verticalSpace,
          Text(
            'Loading campaigns...',
            style: AppTextStyle.h5.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          8.verticalSpace,
          Text(
            'Finding amazing causes for you',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorToken.primary.color.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.search_off_rounded,
                  size: 50,
                  color: AppColorToken.primary.color.withOpacity(0.5),
                ),
              ),
            ),
            28.verticalSpace,
            Text(
              'No campaigns found',
              style: AppTextStyle.h5.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
              ),
            ),
            12.verticalSpace,
            Text(
              'Try adjusting your search\nor filters to find campaigns',
              style: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            32.verticalSpace,
            // Retry button
            GestureDetector(
              onTap: controller.refreshCampaigns,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
