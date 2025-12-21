import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';
import 'package:hope_link/features/Auth/controllers/forgot_password_controller.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controller = Get.find<ForgotPasswordController>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

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
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColorToken.primary.color),
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
                        _buildResetForm(),
                        const SizedBox(height: 24),
                        _buildResendOTP(),
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
            Icons.verified_user_rounded,
            size: 40,
            color: AppColorToken.primary.color,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verify & Reset',
          style: AppTextStyle.h3.bold.copyWith(
            fontSize: 32,
            color: AppColorToken.primary.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the OTP sent to',
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColorToken.primary.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm() {
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
              'Create New Password',
              style: AppTextStyle.h3.bold.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Your new password must be different from previous passwords',
              style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildOTPField(),
            const SizedBox(height: 16),
            _buildNewPasswordField(),
            const SizedBox(height: 16),
            _buildConfirmPasswordField(),
            const SizedBox(height: 24),
            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OTP Code',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _otpController,
          borderRadius: 12,
          hintText: 'Enter 6-digit OTP',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => AppTextField(
            controller: _newPasswordController,
            borderRadius: 12,
            hintText: '••••••••',
            keyboardType: TextInputType.visiblePassword,
            obscureText: _obscureNewPassword.value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter new password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword.value
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey[600],
              ),
              onPressed: () {
                _obscureNewPassword.toggle();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => AppTextField(
            controller: _confirmPasswordController,
            borderRadius: 12,
            hintText: '••••••••',
            keyboardType: TextInputType.visiblePassword,
            obscureText: _obscureConfirmPassword.value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword.value
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey[600],
              ),
              onPressed: () {
                _obscureConfirmPassword.toggle();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Obx(
      () => AppButton(
        title: _controller.isLoading.value
            ? 'Resetting Password...'
            : 'Reset Password',
        backgroundColor: AppColorToken.primary.color,
        onPressed: _controller.isLoading.value ? null : _onResetPassword,
        width: double.infinity,
        radius: 12,
      ),
    );
  }

  Widget _buildResendOTP() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn't receive the code?",
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _onResendOTP,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Resend OTP',
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

  Future<void> _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.resetPassword(
      email: widget.email,
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Password reset successful! Please login with your new password.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColorToken.primary.color.withValues(alpha: 0.1),
        colorText: AppColorToken.primary.color,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: Icon(Icons.check_circle_outline, color: AppColorToken.primary.color),
        duration: const Duration(seconds: 3),
      );
      
      // Navigate back to login after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/login');
      });
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

  Future<void> _onResendOTP() async {
    final success = await _controller.sendOTP(email: widget.email);

    if (success) {
      Get.snackbar(
        'Success',
        'OTP resent to your email',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColorToken.primary.color.withValues(alpha: 0.1),
        colorText: AppColorToken.primary.color,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: Icon(Icons.check_circle_outline, color: AppColorToken.primary.color),
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