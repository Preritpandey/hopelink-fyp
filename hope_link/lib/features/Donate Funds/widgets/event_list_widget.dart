import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import '../controllers/event_controller.dart';
import '../pages/event_details_page.dart';

class EventsListWidget extends StatelessWidget {
  final EventController controller;
  final AnimationController animationController;

  const EventsListWidget({
    super.key,
    required this.controller,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.filteredEvents.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.hasError.value && controller.filteredEvents.isEmpty) {
        return _buildErrorState();
      }

      if (controller.filteredEvents.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshEvents,
        color: AppColorToken.primary.color,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: controller.filteredEvents.length,
          itemBuilder: (context, index) {
            final event = controller.filteredEvents[index];
            return _buildEventCard(event, index);
          },
        ),
      );
    });
  }

  Widget _buildEventCard(event, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          ((index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Get.to(() => EventDetailsPage(event: event)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildEventImage(event), _buildEventContent(event)],
          ),
        ),
      ),
    );
  }

  Widget _buildEventImage(event) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Image.network(
            event.primaryImageUrl,
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
                      AppColorToken.primary.color.withOpacity(0.3),
                      AppColorToken.primary.color.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event_rounded,
                    size: 60,
                    color: AppColorToken.primary.color.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
        ),
        if (event.isFeatured)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                  4.horizontalSpace,
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
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              event.category.toUpperCase(),
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventContent(event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: AppTextStyle.h3.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          8.verticalSpace,
          _buildInfoRow(
            Icons.calendar_today_rounded,
            DateFormat('MMM dd, yyyy').format(event.startDate),
          ),
          6.verticalSpace,
          _buildInfoRow(Icons.location_on_rounded, event.location.city),
          6.verticalSpace,
          _buildInfoRow(
            Icons.people_rounded,
            '${event.volunteersCount}/${event.maxVolunteers} enrolled',
          ),
          12.verticalSpace,
          _buildProgressBar(event),
          12.verticalSpace,
          Row(
            children: [
              Expanded(child: _buildOrganizerInfo(event)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColorToken.primary.color,
                      AppColorToken.primary.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorToken.primary.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    6.horizontalSpace,
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        8.horizontalSpace,
        Expanded(
          child: Text(
            text,
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(event) {
    final progress = event.progressPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${event.progressPercentage.toStringAsFixed(0)}% Enrolled',
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorToken.primary.color,
              ),
            ),
            Text(
              '${event.spotsLeft} spots left',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        8.verticalSpace,
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.9 ? Colors.orange : AppColorToken.primary.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerInfo(event) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColorToken.primary.color.withOpacity(0.1),
          child: Text(
            event.organizer.organizationName[0].toUpperCase(),
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColorToken.primary.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organized by',
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
              Text(
                event.organizer.organizationName,
                style: AppTextStyle.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColorToken.primary.color),
          16.verticalSpace,
          Text(
            'Loading events...',
            style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            16.verticalSpace,
            Text(
              controller.errorMessage.value,
              style: AppTextStyle.bodyLarge.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            24.verticalSpace,
            ElevatedButton.icon(
              onPressed: controller.refreshEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorToken.primary.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[400]),
            16.verticalSpace,
            Text(
              'No events found',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            8.verticalSpace,
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
