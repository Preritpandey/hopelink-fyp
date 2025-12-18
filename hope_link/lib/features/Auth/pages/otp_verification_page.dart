import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/features/Auth/controllers/otp_controller.dart';
import 'package:hope_link/features/Auth/controllers/user_registration_controller.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String token;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final OtpController _otpControllerInstance = Get.put(OtpController());
  final UserRegistrationController _userController = Get.find();

  @override
  void initState() {
    super.initState();
    _otpControllerInstance.startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Your Email',
                  style: AppTextStyle.h1.bold.copyWith(
                    color: AppColorToken.primary.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ve sent a 6-digit verification code to',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.email, style: AppTextStyle.bodyMedium.bold),
                const SizedBox(height: 40),
                _buildOtpInput(),
                const SizedBox(height: 24),
                _buildVerifyButton(),
                const SizedBox(height: 24),
                _buildResendOtpSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter Verification Code', style: AppTextStyle.bodyMedium.medium),
        const SizedBox(height: 12),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: TextInputType.number,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 56,
            fieldWidth: 45,
            activeFillColor: Colors.white,
            activeColor: AppColorToken.primary.color,
            selectedColor: AppColorToken.primary.color,
            inactiveColor: Colors.grey[300]!,
            errorBorderColor: AppColorToken.error.color,
          ),
          animationType: AnimationType.fade,
          validator: (value) {
            if (value == null || value.length != 6) {
              return 'Please enter a valid 6-digit code';
            }
            return null;
          },
          onChanged: (value) {},
          beforeTextPaste: (text) {
            return text?.length == 6 && int.tryParse(text!) != null;
          },
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _otpControllerInstance.isLoading.value ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorToken.primary.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _otpControllerInstance.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Verify',
                  style: AppTextStyle.labelLarge.bold.copyWith(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResendOtpSection() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Didn\'t receive the code? ',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: _otpControllerInstance.canResend.value
                ? _resendOtp
                : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _otpControllerInstance.canResend.value
                  ? 'Resend Code'
                  : 'Resend in ${_otpControllerInstance.resendTimer.value}s',
              style: AppTextStyle.bodySmall.copyWith(
                color: _otpControllerInstance.canResend.value
                    ? AppColorToken.primary.color
                    : Colors.grey[400]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final verified = await _otpControllerInstance.verifyOtp(
      widget.email,
      _otpController.text,
      widget.token,
    );

    if (verified) {
      // Show success message and navigate to login page
      Get.snackbar(
        'Success',
        'Email verified successfully! Please log in.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        snackPosition: SnackPosition.BOTTOM,
      );
      // Navigate to login page after a short delay
      await Future.delayed(const Duration(seconds: 2));
      Get.to(() => const LoginPage());
    } else {
      Get.snackbar(
        'Verification Failed',
        _otpControllerInstance.errorMessage.value,
        backgroundColor: AppColorToken.error.color.withValues(alpha: 0.1),
        colorText: AppColorToken.error.color,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _resendOtp() async {
    final success = await _userController.resendOtp(widget.email);
    if (success) {
      _otpControllerInstance.startResendTimer();
      Get.snackbar(
        'Success',
        'New OTP has been sent to your email',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        _userController.errorMessage.value,
        backgroundColor: AppColorToken.error.color.withValues(alpha: 0.1),
        colorText: AppColorToken.error.color,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
