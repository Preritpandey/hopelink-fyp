import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/campaign_controller.dart';
import '../widgets/campaigns_list_widget.dart';

class AllCampaignsPage extends StatefulWidget {
  const AllCampaignsPage({super.key});

  @override
  State<AllCampaignsPage> createState() => _AllCampaignsPageState();
}

class _AllCampaignsPageState extends State<AllCampaignsPage>
    with SingleTickerProviderStateMixin {
  late final CampaignController _campaignController;
  late final AnimationController _animationController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _campaignController = Get.isRegistered<CampaignController>()
        ? Get.find<CampaignController>()
        : Get.put(CampaignController());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _campaignController.setFilter('all');
      _campaignController.searchCampaigns('');
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaigns',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
              ),
            ),
            4.verticalSpace,
            Text(
              'Make a difference in people\'s lives',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: _campaignController.searchCampaigns,
                    decoration: InputDecoration(
                      hintText: 'Search campaigns...',
                      hintStyle: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _campaignController.searchCampaigns('');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColorToken.primary.color,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  // Filter Chips
                  Obx(() {
                    final filters = [
                      {'label': 'All', 'value': 'all'},
                      {'label': 'Active', 'value': 'active'},
                      {'label': 'Featured', 'value': 'featured'},
                    ];
                    return Row(
                      children: filters.map((filter) {
                        final isLastItem = filter == filters.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: isLastItem ? 0 : 8),
                            child: FilterChip(
                              label: Text(filter['label'] as String),
                              selected:
                                  _campaignController.selectedFilter.value ==
                                  filter['value'],
                              onSelected: (selected) {
                                _campaignController.setFilter(
                                  filter['value'] as String,
                                );
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: AppColorToken.primary.color,
                              labelStyle: AppTextStyle.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    _campaignController.selectedFilter.value ==
                                        filter['value']
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              side: BorderSide(
                                color:
                                    _campaignController.selectedFilter.value ==
                                        filter['value']
                                    ? AppColorToken.primary.color
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
            // Divider
            Container(height: 1, color: Colors.grey[200]),
            // Campaign List
            Expanded(
              child: CampaignsListWidget(
                controller: _campaignController,
                animationController: _animationController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
