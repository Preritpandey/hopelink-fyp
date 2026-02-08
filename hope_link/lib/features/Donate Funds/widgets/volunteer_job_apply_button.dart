import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import '../models/volunteer_job_model.dart';
import '../pages/volunteer_job_application_page.dart';

class VolunteerJobApplyButton extends StatelessWidget {
  final VolunteerJob job;

  const VolunteerJobApplyButton({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final bool canApply = job.isOpen &&
        job.hasPositionsAvailable &&
        !job.isDeadlinePassed;

    return GestureDetector(
      onTap: canApply
          ? () {
              Get.to(
                () => const VolunteerJobApplicationPage(),
                arguments: job,
                transition: Transition.rightToLeft,
                duration: const Duration(milliseconds: 300),
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: canApply
              ? LinearGradient(
                  colors: [
                    AppColorToken.primary.color,
                    AppColorToken.primary.color.withOpacity(0.8),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[300]!,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canApply
              ? [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canApply ? Icons.send_rounded : Icons.lock_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              _getButtonText(),
              style: AppTextStyle.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (!job.isOpen) {
      return 'Position Closed';
    } else if (!job.hasPositionsAvailable) {
      return 'No Positions Available';
    } else if (job.isDeadlinePassed) {
      return 'Deadline Passed';
    } else {
      return 'Apply Now';
    }
  }
}
