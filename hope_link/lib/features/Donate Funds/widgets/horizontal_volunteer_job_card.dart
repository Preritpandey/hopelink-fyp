import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../models/volunteer_job_model.dart';
import 'post_interaction_summary.dart';
import 'save_cause_button.dart';

class HorizontalVolunteerJobCard extends StatelessWidget {
  final VolunteerJob job;
  final int index;
  final AnimationController animationController;
  final double? width;
  final EdgeInsets? margin;

  const HorizontalVolunteerJobCard({
    super.key,
    required this.job,
    required this.index,
    required this.animationController,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final resolvedWidth = width == double.infinity
        ? screenWidth - ((margin?.horizontal) ?? 48)
        : width ?? screenWidth.clamp(0.0, 420.0).toDouble() * 0.78;
    final safeWidth = (resolvedWidth as num)
        .clamp(260.0, width == double.infinity ? 520.0 : 320.0)
        .toDouble();
    final isNarrow = safeWidth < 320;
    final isWide = safeWidth >= 440;
    final cardHeight = isWide
        ? 260.0
        : isNarrow
        ? 296.0
        : 316.0;
    final borderRadius = BorderRadius.circular(18);
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval((index / 10) * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animation.value), 0),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Get.toNamed('/volunteer-job-details', arguments: job),
        child: Container(
          margin:
              margin ?? EdgeInsets.only(left: index == 0 ? 24 : 12, right: 12),
          child: SizedBox(
            width: safeWidth,
            child: Container(
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isNarrow: isNarrow, borderRadius: borderRadius),
                  Expanded(
                    child: _buildContent(isNarrow: isNarrow, isWide: isWide),
                  ),
                  _buildFooter(isNarrow: isNarrow, borderRadius: borderRadius),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isNarrow,
    required BorderRadius borderRadius,
  }) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorToken.primary.color.withOpacity(0.1),
            AppColorToken.primary.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
        ),
      ),
      child: Row(
        children: [
          _buildJobTypeIcon(isNarrow: isNarrow),
          (isNarrow ? 10 : 12).horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed(
                    '/organization-profile',
                    arguments: job.organization,
                  ),
                  child: Text(
                    job.organizationName,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColorToken.primary.color,
                      fontWeight: FontWeight.w700,
                      fontSize: isNarrow ? 11 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                2.verticalSpace,
                Text(
                  job.category,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontSize: isNarrow ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SaveCauseButton(
                postType: 'volunteerJob',
                postId: job.id,
                isSaved: job.isSavedByCurrentUser,
                backgroundColor: Colors.white.withOpacity(0.88),
              ),
              8.horizontalSpace,
              _buildStatusBadge(isNarrow: isNarrow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeIcon({required bool isNarrow}) {
    IconData icon;
    Color iconColor;

    switch (job.jobType.toLowerCase()) {
      case 'remote':
        icon = Icons.laptop_mac_rounded;
        iconColor = Colors.blue;
        break;
      case 'onsite':
        icon = Icons.location_on_rounded;
        iconColor = Colors.orange;
        break;
      case 'hybrid':
        icon = Icons.home_work_rounded;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.work_outline_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(isNarrow ? 9 : 10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: isNarrow ? 22 : 24),
    );
  }

  Widget _buildStatusBadge({required bool isNarrow}) {
    final bool isAvailable = job.isOpen && job.hasPositionsAvailable;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 10,
        vertical: isNarrow ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        isAvailable ? 'Open' : 'Closed',
        style: AppTextStyle.bodySmall.copyWith(
          color: isAvailable ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: isNarrow ? 10 : 11,
        ),
      ),
    );
  }

  Widget _buildContent({required bool isNarrow, required bool isWide}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isWide ? 18 : 16,
        isWide ? 14 : 16,
        isWide ? 18 : 16,
        isWide ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              fontSize: isNarrow ? 16 : 17,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          10.verticalSpace,
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[600],
              fontSize: isNarrow ? 12 : 13,
              height: 1.45,
            ),
          ),
          12.verticalSpace,
          _buildSkillsRow(isNarrow: isNarrow),
          const Spacer(),
          _buildInfoRow(isNarrow: isNarrow),
          10.verticalSpace,
          PostInteractionSummary(
            totalLikes: job.totalLikes,
            commentsCount: job.commentsCount,
            accentColor: AppColorToken.primary.color,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsRow({required bool isNarrow}) {
    final displaySkills = job.requiredSkills.take(2).toList();
    final hasMore = job.requiredSkills.length > 2;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displaySkills.map(
          (skill) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              skill,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColorToken.primary.color,
                fontSize: isNarrow ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (hasMore)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${job.requiredSkills.length - 2}',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[700],
                fontSize: isNarrow ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({required bool isNarrow}) {
    return Row(
      children: [
        Icon(
          Icons.people_outline_rounded,
          size: isNarrow ? 15 : 16,
          color: Colors.grey[600],
        ),
        4.horizontalSpace,
        Text(
          '${job.remainingPositions} positions',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: isNarrow ? 11 : 12,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.schedule_rounded,
          size: isNarrow ? 15 : 16,
          color: Colors.grey[600],
        ),
        4.horizontalSpace,
        Text(
          '${job.creditHours}h',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: isNarrow ? 11 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter({
    required bool isNarrow,
    required BorderRadius borderRadius,
  }) {
    final daysLeft = job.applicationDeadline.difference(DateTime.now()).inDays;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 14 : 16,
        vertical: isNarrow ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (job.certificateProvided)
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: isNarrow ? 14 : 16,
                  color: AppColorToken.primary.color,
                ),
                4.horizontalSpace,
                Text(
                  'Certificate',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w600,
                    fontSize: isNarrow ? 11 : 12,
                  ),
                ),
                12.horizontalSpace,
              ],
            ),
          Icon(
            Icons.calendar_today_rounded,
            size: isNarrow ? 13 : 14,
            color: Colors.grey[600],
          ),
          4.horizontalSpace,
          Expanded(
            child: Text(
              daysLeft > 0 ? '$daysLeft days left' : 'Deadline passed',
              style: AppTextStyle.bodySmall.copyWith(
                color: daysLeft > 0 ? Colors.grey[700] : Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: isNarrow ? 11 : 12,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColorToken.primary.color,
          ),
        ],
      ),
    );
  }
}
