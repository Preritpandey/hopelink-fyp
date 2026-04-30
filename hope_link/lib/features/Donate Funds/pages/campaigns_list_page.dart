import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

import '../controllers/campaign_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/volunteer_leaderboard_controller.dart';
import '../controllers/volunteer_job_controller.dart';
import '../pages/volunteer_leaderboard_page.dart';
import '../widgets/compact_leaderboard_preview.dart';
import '../widgets/donation_header.dart';
import '../widgets/horizontal_campaign_card.dart';
import '../widgets/horizontal_event_card.dart';
import '../widgets/horizontal_volunteer_job_card.dart';

class CampaignsListPage extends StatefulWidget {
  final String? token;

  const CampaignsListPage({super.key, this.token});

  @override
  State<CampaignsListPage> createState() => _CampaignsListPageState();
}

class _CampaignsListPageState extends State<CampaignsListPage>
    with SingleTickerProviderStateMixin {
  final CampaignController _campaignController = Get.put(CampaignController());
  final EventController _eventController = Get.put(EventController());
  final VolunteerJobController _volunteerJobController = Get.put(
    VolunteerJobController(),
  );
  final String _leaderboardPreviewTag = 'campaign-leaderboard-preview';
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchText = ''.obs;

  late AnimationController _animationController;
  late final VolunteerLeaderboardController _leaderboardPreviewController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _leaderboardPreviewController = Get.put(
      VolunteerLeaderboardController(pageSize: 3),
      tag: _leaderboardPreviewTag,
    );
    _animationController.forward();
    _searchController.addListener(() {
      _searchText.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<VolunteerLeaderboardController>(
      tag: _leaderboardPreviewTag,
    )) {
      Get.delete<VolunteerLeaderboardController>(tag: _leaderboardPreviewTag);
    }
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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
              const Color(0xFFF4FBF6),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.04),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              DonationHeader(token: widget.token),
              _buildSearchAndFilter(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Obx(
              () => TextField(
                controller: _searchController,
                onChanged: (value) {
                  _searchText.value = value;
                  _campaignController.searchCampaigns(value);
                  _eventController.searchEvents(value);
                  _volunteerJobController.searchJobs(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search campaigns, events, and volunteer roles',
                  hintStyle: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[500],
                  ),
                  suffixIcon: _searchText.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchText.value = '';
                            _campaignController.clearFilters();
                            _eventController.searchEvents('');
                            _volunteerJobController.searchJobs('');
                            _volunteerJobController.setFilter('all');
                          },
                        )
                      : const SizedBox.shrink(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                ),
              ),
            ),
          ),
          14.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _campaignController.loadCampaigns(forceRefresh: true);
        await _eventController.fetchEvents();
        await _volunteerJobController.refreshJobs();
        await _leaderboardPreviewController.refreshLeaderboard();
      },
      color: AppColorToken.primary.color,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewRail(),
            18.verticalSpace,
            CompactLeaderboardPreview(
              controller: _leaderboardPreviewController,
              onViewFullLeaderboard: () =>
                  Get.to(() => const VolunteerLeaderboardPage()),
            ),
            24.verticalSpace,
            _buildFeaturedCampaignSpotlight(),
            28.verticalSpace,
            _buildHorizontalCampaignsSection(),
            28.verticalSpace,
            _buildHorizontalVolunteerJobsSection(),
            28.verticalSpace,
            _buildHorizontalEventsSection(),
            32.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRail() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          6.verticalSpace,
          Text(
            'Browse fundraising, upcoming events, and volunteer roles ',
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          16.verticalSpace,
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                Obx(
                  () => _buildInsightCard(
                    title: 'Campaigns',
                    value: '${_campaignController.filteredCampaigns.length}',
                    subtitle:
                        '${_campaignController.featuredCampaignsCount} featured',
                    icon: Icons.volunteer_activism_rounded,
                    colors: const [Color(0xFF1E8E55), Color(0xFF38C172)],
                  ),
                ),
                12.horizontalSpace,
                Obx(
                  () => _buildInsightCard(
                    title: 'Volunteer Roles',
                    value: '${_volunteerJobController.filteredJobs.length}',
                    subtitle: 'Open ways to contribute',
                    icon: Icons.groups_rounded,
                    colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                ),
                12.horizontalSpace,
                Obx(
                  () => _buildInsightCard(
                    title: 'Events',
                    value: '${_eventController.filteredEvents.length}',
                    subtitle: 'Upcoming community moments',
                    icon: Icons.event_available_rounded,
                    colors: const [
                      Color.fromARGB(255, 80, 91, 102),
                      Color.fromARGB(255, 81, 189, 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      width: 188,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          10.verticalSpace,
          Row(
            children: [
              Text(
                title,
                style: AppTextStyle.h4.withColor(AppColorToken.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              10.horizontalSpace,
              Text(
                value,
                style: AppTextStyle.h3.bold.withColor(AppColorToken.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          1.verticalSpace,
          Text(
            subtitle,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.15,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCampaignSpotlight() {
    return Obx(() {
      if (_campaignController.filteredCampaigns.isEmpty) {
        return const SizedBox.shrink();
      }

      final featuredCampaign =
          _campaignController.filteredCampaigns.firstWhereOrNull(
            (campaign) => campaign.isFeatured,
          ) ??
          _campaignController.filteredCampaigns.first;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () =>
              Get.toNamed('/campaign-details', arguments: featuredCampaign.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF14532D),
                  AppColorToken.primary.color,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        featuredCampaign.isFeatured
                            ? 'Featured campaign'
                            : 'Recommended cause',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
                18.verticalSpace,
                Text(
                  featuredCampaign.title,
                  style: AppTextStyle.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                10.verticalSpace,
                Text(
                  featuredCampaign.description,
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                18.verticalSpace,
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildSpotlightMetric(
                      'Raised',
                      _formatCurrency(featuredCampaign.currentAmount),
                    ),
                    _buildSpotlightMetric(
                      'Goal',
                      _formatCurrency(featuredCampaign.targetAmount),
                    ),
                    _buildSpotlightMetric(
                      'Time left',
                      featuredCampaign.daysRemaining > 0
                          ? '${featuredCampaign.daysRemaining} days'
                          : 'Ending now',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSpotlightMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          4.verticalSpace,
          Text(
            value,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCampaignsSection() {
    return Obx(() {
      if (_campaignController.isLoading.value &&
          _campaignController.filteredCampaigns.isEmpty) {
        return const SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (_campaignController.filteredCampaigns.isEmpty) {
        return _buildEmptySection(
          title: 'No campaigns found',
          subtitle: 'Try another search or pull to refresh available causes.',
          icon: Icons.search_off_rounded,
        );
      }

      return _buildSectionContainer(
        title: 'Donation Campaigns',
        subtitle: 'Support causes that are actively raising help right now.',
        actionLabel: 'See All',
        onTap: () => Get.toNamed('/campaigns-all'),
        child: SizedBox(
          height: 390,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _campaignController.filteredCampaigns.length,
            itemBuilder: (context, index) {
              final campaign = _campaignController.filteredCampaigns[index];
              return HorizontalCampaignCard(
                campaign: campaign,
                index: index,
                animationController: _animationController,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildHorizontalVolunteerJobsSection() {
    return Obx(() {
      if (_volunteerJobController.isLoading.value &&
          _volunteerJobController.filteredJobs.isEmpty) {
        return const SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (_volunteerJobController.filteredJobs.isEmpty) {
        return const SizedBox.shrink();
      }

      return _buildSectionContainer(
        title: 'Volunteer Opportunities',
        subtitle:
            'Find roles with clear impact, skill fit, and time commitment.',
        actionLabel: 'See All',
        onTap: () => Get.toNamed('/volunteer-jobs-all'),
        child: SizedBox(
          height: 318,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _volunteerJobController.filteredJobs.length,
            itemBuilder: (context, index) {
              final job = _volunteerJobController.filteredJobs[index];
              return HorizontalVolunteerJobCard(
                job: job,
                index: index,
                animationController: _animationController,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildHorizontalEventsSection() {
    return Obx(() {
      if (_eventController.isLoading.value &&
          _eventController.filteredEvents.isEmpty) {
        return const SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (_eventController.filteredEvents.isEmpty) {
        return _buildEmptySection(
          title: 'No events found',
          subtitle:
              'We could not find matching events for your current search.',
          icon: Icons.event_busy_rounded,
        );
      }

      return _buildSectionContainer(
        title: 'Upcoming Events',
        subtitle: 'Join community moments, fundraisers, and on-ground action.',
        child: SizedBox(
          height: 392,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _eventController.filteredEvents.length,
            itemBuilder: (context, index) {
              final event = _eventController.filteredEvents[index];
              return HorizontalEventCard(
                event: event,
                index: index,
                animationController: _animationController,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required Widget child,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[900],
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      subtitle,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onTap != null) ...[
                12.horizontalSpace,
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorToken.primary.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppColorToken.primary.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        4.horizontalSpace,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColorToken.primary.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        14.verticalSpace,
        child,
      ],
    );
  }

  Widget _buildEmptySection({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColorToken.primary.color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColorToken.primary.color, size: 30),
            ),
            14.verticalSpace,
            Text(
              title,
              style: AppTextStyle.h5.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
              ),
            ),
            8.verticalSpace,
            Text(
              subtitle,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[600],
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _buildSyncLabel() {
    final lastSync = _campaignController.lastSyncTime.value;
    if (lastSync == null) {
      return 'Waiting for sync';
    }

    final difference = DateTime.now().difference(lastSync);
    if (difference.inMinutes < 1) {
      return 'Updated just now';
    }
    if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return 'Updated ${difference.inHours}h ago';
    }
    return 'Updated ${difference.inDays}d ago';
  }

  String _formatCurrency(double amount) {
    return 'NPR ${NumberFormat("#,##0", "en_US").format(amount)}';
  }
}
