import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/activity_controller.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_stats_header.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  final ActivityController _controller = Get.put(ActivityController());
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _searchController.addListener(() {
      _controller.search(_searchController.text);
    });

    // Load more on scroll to bottom
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Activities',
                  style: AppTextStyle.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[900],
                  ),
                ),
                Obx(
                  () => Text(
                    '${_controller.totalCount.value} total activities',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Obx(
      () => GestureDetector(
        onTap: _controller.isRefreshing.value
            ? null
            : () => _controller.fetchActivities(isRefresh: true),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: _controller.isRefreshing.value
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColorToken.primary.color,
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  color: AppColorToken.primary.color,
                  size: 20,
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
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
            decoration: InputDecoration(
              hintText: 'Search your activities...',
              hintStyle: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
              suffixIcon: _controller.searchText.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _controller.search('');
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
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip('All', ActivityFilter.all, Icons.apps_rounded),
            8.horizontalSpace,
            _filterChip(
              'Donations',
              ActivityFilter.donation,
              Icons.favorite_rounded,
            ),
            8.horizontalSpace,
            _filterChip(
              'Events',
              ActivityFilter.eventRegistration,
              Icons.event_available_rounded,
            ),
            8.horizontalSpace,
            _filterChip(
              'Volunteer',
              ActivityFilter.volunteerJob,
              Icons.volunteer_activism_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, ActivityFilter filter, IconData icon) {
    return Obx(() {
      final isSelected = _controller.selectedFilter.value == filter;
      return GestureDetector(
        onTap: () => _controller.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyle.bodySmall.copyWith(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    return Obx(() {
      // Initial loading
      if (_controller.isLoading.value &&
          _controller.filteredActivities.isEmpty) {
        return _buildLoadingState();
      }

      // Error with no data
      if (_controller.errorMessage.value.isNotEmpty &&
          _controller.filteredActivities.isEmpty) {
        return _buildErrorState();
      }

      // Empty state
      if (_controller.filteredActivities.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => _controller.fetchActivities(isRefresh: true),
        color: AppColorToken.primary.color,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  16.verticalSpace,
                  const ActivityStatsHeader(),
                  20.verticalSpace,
                  _buildSectionLabel(),
                  8.verticalSpace,
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _controller.filteredActivities.length) {
                  return _buildPaginationLoader();
                }
                final activity = _controller.filteredActivities[index];
                return ActivityCard(
                  activity: activity,
                  index: index,
                  animationController: _animationController,
                );
              }, childCount: _controller.filteredActivities.length + 1),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      );
    });
  }

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Recent Activity',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          const Spacer(),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorToken.primary.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_controller.filteredActivities.length} items',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColorToken.primary.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationLoader() {
    return Obx(() {
      if (!_controller.isLoading.value || _controller.currentPage.value <= 1) {
        return const SizedBox(height: 8);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColorToken.primary.color,
            strokeWidth: 2,
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Loading / error / empty states
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 24),
      itemCount: 5,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops!',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _controller.fetchActivities(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColorToken.primary.color,
                      AppColorToken.primary.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorToken.primary.color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Try Again',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColorToken.primary.color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 40,
                color: AppColorToken.primary.color.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Activities Yet',
              style: AppTextStyle.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.searchText.value.isNotEmpty
                  ? 'No results for "${_controller.searchText.value}"'
                  : 'Start donating, attending events,\nor volunteering to see your activity here.',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loader card
// ---------------------------------------------------------------------------

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final shimmerColor = Color.lerp(
          Colors.grey[200]!,
          Colors.grey[100]!,
          _shimmer.value,
        )!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 130,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
