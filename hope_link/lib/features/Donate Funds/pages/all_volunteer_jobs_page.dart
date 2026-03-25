import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';

import '../controllers/volunteer_job_controller.dart';
import '../widgets/horizontal_volunteer_job_card.dart';

class AllVolunteerJobsPage extends StatefulWidget {
  const AllVolunteerJobsPage({super.key});

  @override
  State<AllVolunteerJobsPage> createState() => _AllVolunteerJobsPageState();
}

class _AllVolunteerJobsPageState extends State<AllVolunteerJobsPage>
    with SingleTickerProviderStateMixin {
  late final VolunteerJobController _volunteerJobController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _volunteerJobController = Get.isRegistered<VolunteerJobController>()
        ? Get.find<VolunteerJobController>()
        : Get.put(VolunteerJobController());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _volunteerJobController.setFilter('all');
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Volunteer Opportunities',
          style: AppTextStyle.h4.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
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
        child: Obx(() {
          if (_volunteerJobController.isLoading.value &&
              _volunteerJobController.filteredJobs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_volunteerJobController.filteredJobs.isEmpty) {
            return Center(
              child: Text(
                'No volunteer opportunities found',
                style: AppTextStyle.bodyMedium.copyWith(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _volunteerJobController.filteredJobs.length,
            itemBuilder: (context, index) {
              final job = _volunteerJobController.filteredJobs[index];
              return HorizontalVolunteerJobCard(
                job: job,
                index: index,
                animationController: _animationController,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              );
            },
          );
        }),
      ),
    );
  }
}
