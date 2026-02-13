import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import '../controllers/volunteer_application_controller.dart';
import '../models/volunteer_job_model.dart';

class VolunteerJobApplicationPage extends StatefulWidget {
  const VolunteerJobApplicationPage({super.key});

  @override
  State<VolunteerJobApplicationPage> createState() =>
      _VolunteerJobApplicationPageState();
}

class _VolunteerJobApplicationPageState
    extends State<VolunteerJobApplicationPage>
    with SingleTickerProviderStateMixin {
  late VolunteerJob job;
  final VolunteerApplicationController _controller = Get.put(
    VolunteerApplicationController(),
  );

  final _formKey = GlobalKey<FormState>();
  final _whyHireController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    job = Get.arguments as VolunteerJob;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _whyHireController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      _controller.setResume(File(result.files.single.path!));
    }
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      if (_controller.resumeFile.value == null) {
        Get.snackbar(
          'Resume Required',
          'Please upload your resume in PDF format',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
        return;
      }

      final success = await _controller.submitApplication(
        jobId: job.id,
        whyHire: _whyHireController.text,
        skills: _skillsController.text,
        experience: _experienceController.text,
      );

      if (success) {
        Get.back();
        Get.back();
        Get.snackbar(
          'Success!',
          'Your application has been submitted successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 3),
        );
      }
    }
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildJobInfo(),
                          32.verticalSpace,
                          _buildWhyHireField(),
                          24.verticalSpace,
                          _buildSkillsField(),
                          24.verticalSpace,
                          _buildExperienceField(),
                          24.verticalSpace,
                          _buildResumeUpload(),
                          32.verticalSpace,
                          _buildSubmitButton(),
                          16.verticalSpace,
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
              'Apply for Position',
              style: AppTextStyle.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorToken.primary.color.withOpacity(0.1),
            AppColorToken.primary.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorToken.primary.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorToken.primary.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.work_rounded,
              color: AppColorToken.primary.color,
              size: 28,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: AppTextStyle.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                4.verticalSpace,
                Text(
                  job.organizationName,
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColorToken.primary.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyHireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              color: AppColorToken.primary.color,
              size: 20,
            ),
            8.horizontalSpace,
            Text(
              'Why should we hire you?',
              style: AppTextStyle.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            Text(
              ' *',
              style: AppTextStyle.bodyLarge.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Container(
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
          child: TextFormField(
            controller: _whyHireController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us why you\'re the perfect fit for this role...',
              hintStyle: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please tell us why we should hire you';
              }
              if (value.length < 50) {
                return 'Please provide at least 50 characters';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.orange, size: 20),
            8.horizontalSpace,
            Text(
              'Your Skills',
              style: AppTextStyle.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            Text(
              ' *',
              style: AppTextStyle.bodyLarge.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        8.verticalSpace,
        Text(
          'Separate skills with commas',
          style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
        ),
        12.verticalSpace,
        Container(
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
          child: TextFormField(
            controller: _skillsController,
            decoration: InputDecoration(
              hintText: 'e.g., Teaching, Communication, First Aid',
              hintStyle: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please list your skills';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_history_rounded, color: Colors.blue, size: 20),
            8.horizontalSpace,
            Text(
              'Experience',
              style: AppTextStyle.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            Text(
              ' *',
              style: AppTextStyle.bodyLarge.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        12.verticalSpace,
        Container(
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
          child: TextFormField(
            controller: _experienceController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your relevant experience...',
              hintStyle: AppTextStyle.bodyMedium.copyWith(
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your experience';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResumeUpload() {
    return Obx(() {
      final hasResume = _controller.resumeFile.value != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.purple, size: 20),
              8.horizontalSpace,
              Text(
                'Resume',
                style: AppTextStyle.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              Text(
                ' *',
                style: AppTextStyle.bodyLarge.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          Text(
            'Upload your resume in PDF format',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          12.verticalSpace,
          GestureDetector(
            onTap: _pickResume,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasResume
                      ? AppColorToken.primary.color
                      : Colors.grey[300]!,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColorToken.primary.color.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasResume ? _buildResumePreview() : _buildUploadPrompt(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUploadPrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_rounded,
            color: AppColorToken.primary.color,
            size: 40,
          ),
        ),
        16.verticalSpace,
        Text(
          'Click to upload resume',
          style: AppTextStyle.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        4.verticalSpace,
        Text(
          'PDF format only',
          style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildResumePreview() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.red,
            size: 32,
          ),
        ),
        16.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _controller.resumeFile.value!.path.split('/').last,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              4.verticalSpace,
              Text(
                'Click to change',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColorToken.primary.color,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _controller.removeResume(),
          icon: const Icon(Icons.close_rounded),
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final isLoading = _controller.isSubmitting.value;

      return GestureDetector(
        onTap: isLoading ? null : _submitApplication,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoading
                  ? [Colors.grey[400]!, Colors.grey[400]!]
                  : [
                      AppColorToken.primary.color,
                      AppColorToken.primary.color.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColorToken.primary.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Submit Application',
                      style: AppTextStyle.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
