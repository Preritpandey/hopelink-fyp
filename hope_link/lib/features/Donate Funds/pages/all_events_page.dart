import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/event_controller.dart';
import '../widgets/event_list_widget.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage>
    with SingleTickerProviderStateMixin {
  late final EventController _eventController;
  late final AnimationController _animationController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _eventController = Get.isRegistered<EventController>()
        ? Get.find<EventController>()
        : Get.put(EventController());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _eventController.setFilter('all');
      _eventController.searchEvents('');
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
      backgroundColor: AppColors.inputFill,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
              ),
            ),
            4.verticalSpace,
            Text(
              'Join upcoming community moments',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.grey500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: AppColors.grey900),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _eventController.searchEvents(value);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      hintStyle: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.grey400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.grey400,
                        size: 24,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _eventController.searchEvents('');
                                setState(() {});
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.grey400,
                                size: 24,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.grey200,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.grey200,
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
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  16.verticalSpace,
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
                            padding: EdgeInsets.only(
                              right: isLastItem ? 0 : 8,
                            ),
                            child: FilterChip(
                              label: Text(filter['label'] as String),
                              selected:
                                  _eventController.selectedFilter.value ==
                                  filter['value'],
                              onSelected: (_) {
                                _eventController.setFilter(
                                  filter['value'] as String,
                                );
                              },
                              backgroundColor: AppColors.grey100,
                              selectedColor: AppColorToken.primary.color,
                              labelStyle: AppTextStyle.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    _eventController.selectedFilter.value ==
                                        filter['value']
                                    ? AppColors.white
                                    : AppColors.grey700,
                              ),
                              side: BorderSide(
                                color:
                                    _eventController.selectedFilter.value ==
                                        filter['value']
                                    ? AppColorToken.primary.color
                                    : AppColors.transparent,
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
            Container(height: 1, color: AppColors.grey200),
            Expanded(
              child: EventsListWidget(
                controller: _eventController,
                animationController: _animationController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


