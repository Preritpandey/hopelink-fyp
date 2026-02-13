import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/campaign_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/volunteer_job_controller.dart';
import '../widgets/donation_header.dart';
import '../widgets/horizontal_campaign_card.dart';
import '../widgets/horizontal_event_card.dart';
import '../widgets/horizontal_volunteer_job_card.dart';

class CampaignsListPage extends StatefulWidget {
  const CampaignsListPage({super.key});

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
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchText = ''.obs;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _searchController.addListener(() {
      _searchText.value = _searchController.text;
    });
  }

  @override
  void dispose() {
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
              AppColorToken.primary.color.withOpacity(0.05),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              DonationHeader(),
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  hintText: 'Search campaigns, events, and jobs...',
                  hintStyle: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
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
                            _campaignController.searchCampaigns('');
                            _eventController.searchEvents('');
                            _volunteerJobController.searchJobs('');
                          },
                        )
                      : const SizedBox.shrink(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          16.verticalSpace,
          SizedBox(
            height: 40,
            child: ListView(
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
          16.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = _campaignController.selectedFilter.value == value;

      return GestureDetector(
        onTap: () {
          _campaignController.setFilter(value);
          _volunteerJobController.setFilter(value);
        },
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
    });
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _campaignController.loadCampaigns();
        await _eventController.fetchEvents();
        await _volunteerJobController.refreshJobs();
      },
      color: AppColorToken.primary.color,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trending',
                    style: AppTextStyle.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    'Discover impactful campaigns, events, and opportunities',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            _buildHorizontalCampaignsSection(),
            24.verticalSpace,
            _buildHorizontalVolunteerJobsSection(),
            24.verticalSpace,
            _buildHorizontalEventsSection(),
            24.verticalSpace,
          ],
        ),
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No campaigns found',
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        );
      }

      return SizedBox(
        height: 320,
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volunteer Opportunities',
                      style: AppTextStyle.h4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'Find your perfect volunteer match',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to all volunteer jobs page
                    // Get.toNamed('/volunteer-jobs-all');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorToken.primary.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppColorToken.primary.color,
                            fontWeight: FontWeight.w600,
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
            ),
          ),
          12.verticalSpace,
          SizedBox(
            height: 345,
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
        ],
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No events found',
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Upcoming Events',
              style: AppTextStyle.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
          12.verticalSpace,
          SizedBox(
            height: 320,
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
        ],
      );
    });
  }
}
