// lib/features/events/pages/event_details_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventController _controller = Get.find<EventController>();
  final PageController _pageController = PageController();
  final RxInt _currentImageIndex = 0.obs;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(),
                _buildMainInfo(),
                _buildProgressSection(),
                _buildDescription(),
                _buildLocationSection(),
                _buildDateSection(),
                _buildSkillsSection(),
                _buildOrganizerSection(),
                100.verticalSpace,
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildEnrollButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColorToken.primary.color,
          ),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.share_rounded,
              color: AppColorToken.primary.color,
            ),
          ),
          onPressed: () {
            // Implement share functionality
          },
        ),
        16.horizontalSpace,
      ],
    );
  }

  Widget _buildImageCarousel() {
    if (widget.event.images.isEmpty) {
      return Container(
        height: 300,
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
            size: 80,
            color: AppColorToken.primary.color.withOpacity(0.5),
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => _currentImageIndex.value = index,
            itemCount: widget.event.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.event.images[index].url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (widget.event.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.event.images.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex.value == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex.value == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.event.isFeatured)
          Positioned(
            top: 16,
            right: 16,
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
      ],
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.event.category.toUpperCase(),
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColorToken.primary.color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          12.verticalSpace,
          Text(
            widget.event.title,
            style: AppTextStyle.h3.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          12.verticalSpace,
          Row(
            children: [
              _buildInfoChip(
                Icons.event_available_rounded,
                widget.event.eventType.replaceAll('-', ' ').toUpperCase(),
              ),
              12.horizontalSpace,
              _buildInfoChip(
                Icons.public_rounded,
                widget.event.status.toUpperCase(),
                color: widget.event.status == 'published'
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColorToken.primary.color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColorToken.primary.color),
          6.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: color ?? AppColorToken.primary.color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorToken.primary.color.withOpacity(0.1),
            AppColorToken.primary.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorToken.primary.color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Enrolled',
                widget.event.volunteersCount.toString(),
                Icons.people_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildStatItem(
                'Max Capacity',
                widget.event.maxVolunteers.toString(),
                Icons.groups_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildStatItem(
                'Spots Left',
                widget.event.spotsLeft.toString(),
                Icons.event_seat_rounded,
              ),
            ],
          ),
          16.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.event.progressPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.event.progressPercentage >= 90
                    ? Colors.orange
                    : AppColorToken.primary.color,
              ),
            ),
          ),
          8.verticalSpace,
          Text(
            '${widget.event.progressPercentage.toStringAsFixed(1)}% enrolled',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColorToken.primary.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColorToken.primary.color, size: 24),
          6.verticalSpace,
          Text(
            value,
            style: AppTextStyle.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColorToken.primary.color,
            ),
          ),
          4.verticalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this Event',
            style: AppTextStyle.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          12.verticalSpace,
          Text(
            widget.event.description,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: AppTextStyle.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          16.verticalSpace,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColorToken.primary.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: AppColorToken.primary.color,
                        size: 24,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.location.address,
                            style: AppTextStyle.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          4.verticalSpace,
                          Text(
                            '${widget.event.location.city}, ${widget.event.location.state}',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: Colors.grey[600],
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
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Schedule',
            style: AppTextStyle.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  'Start Date',
                  widget.event.startDate,
                  Icons.play_circle_outline_rounded,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: _buildDateCard(
                  'End Date',
                  widget.event.endDate,
                  Icons.stop_circle_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColorToken.primary.color, size: 24),
          8.verticalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          4.verticalSpace,
          Text(
            DateFormat('MMM dd').format(date),
            style: AppTextStyle.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            DateFormat('yyyy, hh:mm a').format(date),
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    if (widget.event.requiredSkills.isEmpty) return const SizedBox.shrink();

    final skills = widget.event.requiredSkills
        .expand((skill) => skill.split(','))
        .map((s) => s.trim())
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Skills',
            style: AppTextStyle.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          12.verticalSpace,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorToken.primary.color.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          16.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildOrganizerSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organized By',
            style: AppTextStyle.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          16.verticalSpace,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColorToken.primary.color.withOpacity(0.1),
                  child: Text(
                    widget.event.organizer.organizationName.isNotEmpty
                        ? widget.event.organizer.organizationName[0]
                              .toUpperCase()
                        : 'O',
                    style: AppTextStyle.h2.copyWith(
                      color: AppColorToken.primary.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.organizer.organizationName.isNotEmpty
                            ? widget.event.organizer.organizationName
                            : 'Organizer',
                        style: AppTextStyle.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        widget.event.organizer.officialEmail.isNotEmpty
                            ? widget.event.organizer.officialEmail
                            : 'contact@organizer.com',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
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

  Widget _buildEnrollButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(
          () => ElevatedButton(
            onPressed:
                widget.event.spotsLeft > 0 && !_controller.isEnrolling.value
                ? () => _enrollInEvent()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorToken.primary.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _controller.isEnrolling.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.how_to_reg_rounded),
                      12.horizontalSpace,
                      Text(
                        widget.event.spotsLeft > 0
                            ? 'Enroll Now'
                            : 'Event Full',
                        style: AppTextStyle.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _enrollInEvent() async {
    final success = await _controller.enrollInEvent(widget.event.id);
    if (success) {
      // Optionally navigate back or update UI
    }
  }
}
