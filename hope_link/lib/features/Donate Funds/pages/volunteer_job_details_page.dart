import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../models/volunteer_job_model.dart';
import '../widgets/volunteer_job_apply_button.dart';

class VolunteerJobDetailsPage extends StatefulWidget {
  const VolunteerJobDetailsPage({super.key});

  @override
  State<VolunteerJobDetailsPage> createState() =>
      _VolunteerJobDetailsPageState();
}

class _VolunteerJobDetailsPageState extends State<VolunteerJobDetailsPage>
    with SingleTickerProviderStateMixin {
  late VolunteerJob job;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    job = Get.arguments as VolunteerJob;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          20.verticalSpace,
                          _buildQuickInfo(),
                          24.verticalSpace,
                          _buildDescription(),
                          24.verticalSpace,
                          _buildRequiredSkills(),
                          24.verticalSpace,
                          _buildLocationInfo(),
                          24.verticalSpace,
                          _buildBenefits(),
                          24.verticalSpace,
                          _buildDeadlineInfo(),
                          100.verticalSpace, // Space for apply button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: VolunteerJobApplyButton(job: job),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: Colors.grey[800]),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Text(
              'Job Details',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Share functionality
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.share_rounded, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildJobTypeChip(),
              12.horizontalSpace,
              _buildStatusChip(),
            ],
          ),
          16.verticalSpace,
          Text(
            job.title,
            style: AppTextStyle.h2.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
              height: 1.2,
            ),
          ),
          12.verticalSpace,
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_rounded,
                  size: 20,
                  color: AppColorToken.primary.color,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.organizationName,
                      style: AppTextStyle.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      job.category,
                      style: AppTextStyle.bodyMedium.copyWith(
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
    );
  }

  Widget _buildJobTypeChip() {
    IconData icon;
    Color color;
    String label;

    switch (job.jobType.toLowerCase()) {
      case 'remote':
        icon = Icons.laptop_mac_rounded;
        color = Colors.blue;
        label = 'Remote';
        break;
      case 'onsite':
        icon = Icons.location_on_rounded;
        color = Colors.orange;
        label = 'On-site';
        break;
      case 'hybrid':
        icon = Icons.home_work_rounded;
        color = Colors.purple;
        label = 'Hybrid';
        break;
      default:
        icon = Icons.work_outline_rounded;
        color = Colors.grey;
        label = job.jobType;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          6.horizontalSpace,
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final bool isAvailable = job.isOpen && job.hasPositionsAvailable;
    final color = isAvailable ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          6.horizontalSpace,
          Text(
            isAvailable ? 'Open' : 'Closed',
            style: AppTextStyle.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.people_outline_rounded,
                'Positions',
                '${job.remainingPositions}/${job.positionsAvailable}',
                AppColorToken.primary.color,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildInfoItem(
                Icons.schedule_rounded,
                'Credit Hours',
                '${job.creditHours}h',
                Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        8.verticalSpace,
        Text(
          value,
          style: AppTextStyle.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        4.verticalSpace,
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          12.verticalSpace,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              job.description,
              style: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredSkills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Skills',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          12.verticalSpace,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.requiredSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorToken.primary.color.withOpacity(0.1),
                        AppColorToken.primary.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColorToken.primary.color.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColorToken.primary.color,
                      ),
                      8.horizontalSpace,
                      Text(
                        skill,
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColorToken.primary.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          12.verticalSpace,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorToken.primary.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColorToken.primary.color,
                    size: 24,
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.location.address,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        '${job.location.city}, ${job.location.state}',
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

  Widget _buildBenefits() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits',
            style: AppTextStyle.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          12.verticalSpace,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorToken.primary.color.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  Icons.verified_rounded,
                  'Certificate',
                  job.certificateProvided
                      ? 'Certificate of completion provided'
                      : 'No certificate provided',
                  job.certificateProvided ? Colors.green : Colors.grey,
                ),
                16.verticalSpace,
                _buildBenefitItem(
                  Icons.access_time_rounded,
                  'Credit Hours',
                  '${job.creditHours} volunteer hours credited',
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        16.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              4.verticalSpace,
              Text(
                description,
                style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineInfo() {
    final daysLeft = job.applicationDeadline.difference(DateTime.now()).inDays;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: daysLeft > 7
                ? [
                    AppColorToken.primary.color.withOpacity(0.1),
                    AppColorToken.primary.color.withOpacity(0.05),
                  ]
                : [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: daysLeft > 7
                ? AppColorToken.primary.color.withOpacity(0.2)
                : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: daysLeft > 7 ? AppColorToken.primary.color : Colors.orange,
              size: 24,
            ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Deadline',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    dateFormat.format(job.applicationDeadline),
                    style: AppTextStyle.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: daysLeft > 7 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                daysLeft > 0 ? '$daysLeft days left' : 'Expired',
                style: AppTextStyle.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
