import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

import '../controllers/campaign_controller.dart';
import '../models/campaign_model.dart';

class CampaignsListPage extends StatefulWidget {
  const CampaignsListPage({super.key});

  @override
  State<CampaignsListPage> createState() => _CampaignsListPageState();
}

class _CampaignsListPageState extends State<CampaignsListPage>
    with SingleTickerProviderStateMixin {
  final CampaignController _controller = Get.put(CampaignController());
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'NPR ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color.withOpacity(0.05),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value &&
                      _controller.campaigns.isEmpty) {
                    return _buildLoadingState();
                  }

                  if (_controller.filteredCampaigns.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildCampaignsList();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  4.verticalSpace,
                  Obx(
                    () => Text(
                      '${_controller.filteredCampaigns.length} active campaigns',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              Obx(
                () => _controller.isOfflineMode.value
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
          if (_controller.lastSyncTime.value != null) ...[
            8.verticalSpace,
            Obx(
              () => Text(
                'Last updated: ${_formatLastSync(_controller.lastSyncTime.value!)}',
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
          ],
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _controller.searchCampaigns,
              decoration: InputDecoration(
                hintText: 'Search campaigns...',
                hintStyle: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: Obx(
                  () => _controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _controller.searchCampaigns('');
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          16.verticalSpace,
          // Filter chips
          SizedBox(
            height: 40,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', 'all'),
                  8.horizontalSpace,
                  _buildFilterChip('Active', 'active'),
                  8.horizontalSpace,
                  _buildFilterChip('Featured', 'featured'),
                ],
              ),
            ),
          ),
          16.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _controller.selectedFilter.value == value;

    return GestureDetector(
      onTap: () => _controller.setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColorToken.primary.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColorToken.primary.color
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignsList() {
    return RefreshIndicator(
      onRefresh: _controller.refreshCampaigns,
      color: AppColorToken.primary.color,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _controller.filteredCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = _controller.filteredCampaigns[index];
          return _buildCampaignCard(campaign, index);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign, int index) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
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
                parent: _animationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        child: GestureDetector(
          onTap: () => Get.toNamed('/campaign-details', arguments: campaign.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
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
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
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
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                          ),
                          child: Text(
                            'Draft',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
                      Text(
                        campaign.title,
                        style: AppTextStyle.h4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      8.verticalSpace,
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              campaign.organization.organizationName,
                              style: AppTextStyle.bodySmall.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      16.verticalSpace,
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatCurrency(campaign.currentAmount),
                                style: AppTextStyle.h5.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColorToken.primary.color,
                                ),
                              ),
                              Text(
                                '${campaign.progress.toStringAsFixed(0)}%',
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          4.verticalSpace,
                          Text(
                            'of ${_formatCurrency(campaign.targetAmount)}',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          8.verticalSpace,
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: campaign.progress / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColorToken.primary.color,
                              ),
                              minHeight: 8,
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
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColorToken.primary.color,
            ),
          ),
          16.verticalSpace,
          Text(
            'Loading campaigns...',
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
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
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            16.verticalSpace,
            Text(
              'No campaigns found',
              style: AppTextStyle.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            8.verticalSpace,
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
