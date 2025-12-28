import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/campaign_controller.dart';
import '../controllers/event_controller.dart';
import '../widgets/campaigns_list_widget.dart';
import '../widgets/donation_header.dart';
import '../widgets/event_list_widget.dart';

class CampaignsListPage extends StatefulWidget {
  const CampaignsListPage({super.key});

  @override
  State<CampaignsListPage> createState() => _CampaignsListPageState();
}

class _CampaignsListPageState extends State<CampaignsListPage>
    with SingleTickerProviderStateMixin {
  final CampaignController _campaignController = Get.put(CampaignController());
  final EventController _eventController = Get.put(EventController());
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  final RxInt _selectedTab = 0.obs;

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
              _buildTabSelector(),
              16.verticalSpace,
              _buildSearchAndFilter(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildTabButton(
                label: 'Donations',
                index: 0,
                icon: Icons.favorite_rounded,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                label: 'Events',
                index: 1,
                icon: Icons.event_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedTab.value == index;

    return GestureDetector(
      onTap: () {
        _selectedTab.value = index;
        _searchController.clear();
        if (index == 0) {
          _campaignController.searchCampaigns('');
        } else {
          _eventController.searchEvents('');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColorToken.primary.color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            8.horizontalSpace,
            Text(
              label,
              style: AppTextStyle.bodyMedium.copyWith(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
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
                  if (_selectedTab.value == 0) {
                    _campaignController.searchCampaigns(value);
                  } else {
                    _eventController.searchEvents(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: _selectedTab.value == 0
                      ? 'Search campaigns...'
                      : 'Search events...',
                  hintStyle: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                  ),
                  suffixIcon:
                      _selectedTab.value >= 0 &&
                          _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            if (_selectedTab.value == 0) {
                              _campaignController.searchCampaigns('');
                            } else {
                              _eventController.searchEvents('');
                            }
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
    // Use Obx to reactively check which tab is selected and get the right controller
    return Obx(() {
      final isSelected = _selectedTab.value == 0
          ? _campaignController.selectedFilter.value == value
          : _eventController.selectedFilter.value == value;

      return GestureDetector(
        onTap: () {
          if (_selectedTab.value == 0) {
            _campaignController.setFilter(value);
          } else {
            _eventController.setFilter(value);
          }
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
    return Obx(() {
      if (_selectedTab.value == 0) {
        return CampaignsListWidget(
          controller: _campaignController,
          animationController: _animationController,
        );
      } else {
        return EventsListWidget(
          controller: _eventController,
          animationController: _animationController,
        );
      }
    });
  }
}
