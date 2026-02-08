import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import '../models/volunteer_job_model.dart';

class HorizontalVolunteerJobCard extends StatelessWidget {
  final VolunteerJob job;
  final int index;
  final AnimationController animationController;

  const HorizontalVolunteerJobCard({
    super.key,
    required this.job,
    required this.index,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: () {
          Get.toNamed('/volunteer-job-details', arguments: job);
          // Get.to(() => VolunteerJobDetailsPage());
        },
        child: Container(
          width: 300,
          margin: EdgeInsets.only(left: index == 0 ? 24 : 12, right: 12),
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
              _buildHeader(),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorToken.primary.color.withOpacity(0.1),
            AppColorToken.primary.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildJobTypeIcon(),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.organizationName,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  job.category,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildJobTypeIcon() {
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  Widget _buildStatusBadge() {
    final bool isAvailable = job.isOpen && job.hasPositionsAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          12.verticalSpace,
          Text(
            maxLines: 2,
            job.description,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          16.verticalSpace,
          _buildSkillsRow(),
          const Spacer(),
          _buildInfoRow(),
        ],
      ),
    );
  }

  Widget _buildSkillsRow() {
    final displaySkills = job.requiredSkills.take(2).toList();
    final hasMore = job.requiredSkills.length > 2;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displaySkills.map(
          (skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              skill,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColorToken.primary.color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${job.requiredSkills.length - 3}',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey[600]),
        6.horizontalSpace,
        Text(
          '${job.remainingPositions} positions',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Icon(Icons.schedule_rounded, size: 16, color: Colors.grey[600]),
        6.horizontalSpace,
        Text(
          '${job.creditHours}h',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final daysLeft = job.applicationDeadline.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (job.certificateProvided)
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColorToken.primary.color,
                ),
                6.horizontalSpace,
                Text(
                  'Certificate',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                16.horizontalSpace,
              ],
            ),
          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[600]),
          6.horizontalSpace,
          Expanded(
            child: Text(
              daysLeft > 0 ? '$daysLeft days left' : 'Deadline passed',
              style: AppTextStyle.bodySmall.copyWith(
                color: daysLeft > 0 ? Colors.grey[700] : Colors.red,
                fontWeight: FontWeight.w500,
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
