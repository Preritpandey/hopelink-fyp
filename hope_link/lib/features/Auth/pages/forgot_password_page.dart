import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';
import 'package:hope_link/features/Auth/controllers/forgot_password_controller.dart';
import 'package:hope_link/features/Auth/pages/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _controller = Get.put(ForgotPasswordController());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColorToken.primary.color,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorToken.primary.color.withValues(alpha: 0.05),
              Colors.white,
              AppColorToken.primary.color.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildEmailForm(),
                        const SizedBox(height: 24),
                        _buildBackToLogin(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColorToken.primary.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 40,
            color: AppColorToken.primary.color,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Forgot Password?',
          style: AppTextStyle.h3.bold.copyWith(
            fontSize: 32,
            color: AppColorToken.primary.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'No worries, we\'ll send you reset instructions',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorToken.primary.color.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset Password',
              style: AppTextStyle.h3.bold.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email address and we\'ll send you an OTP',
              style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildEmailField(),
            const SizedBox(height: 24),
            _buildSendOTPButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _emailController,
          borderRadius: 12,
          hintText: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!GetUtils.isEmail(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSendOTPButton() {
    return Obx(
      () => AppButton(
        title: _controller.isLoading.value ? 'Sending OTP...' : 'Send OTP',
        backgroundColor: AppColorToken.primary.color,
        onPressed: _controller.isLoading.value ? null : _onSendOTP,
        width: double.infinity,
        radius: 12,
      ),
    );
  }

  Widget _buildBackToLogin() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppColorToken.primary.color,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Back to Login',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColorToken.primary.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.sendOTP(
      email: _emailController.text.trim(),
    );

    if (success) {
      Get.to(
        () => ResetPasswordPage(email: _emailController.text.trim()),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
      Get.snackbar(
        'Success',
        'OTP sent to your email',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColorToken.primary.color.withValues(alpha: 0.1),
        colorText: AppColorToken.primary.color,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: Icon(
          Icons.check_circle_outline,
          color: AppColorToken.primary.color,
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColorToken.error.color.withValues(alpha: 0.1),
        colorText: AppColorToken.error.color,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: Icon(Icons.error_outline, color: AppColorToken.error.color),
      );
    }
  }
}
