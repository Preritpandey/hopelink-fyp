import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpController extends GetxController {
  final String baseUrl = 'http://localhost:3008/api/v1';
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxInt resendTimer = 30.obs;
  final RxBool canResend = false.obs;

  Timer? _timer;

  // Verify OTP
  Future<bool> verifyOtp(String email, String otp, String token) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        successMessage.value = 'Email verified successfully!';
        // Save verification status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isEmailVerified', true);
        return true;
      } else {
        errorMessage.value =
            responseData['message'] ?? 'Invalid OTP. Please try again.';
        return false;
      }
    } catch (e) {
      errorMessage.value =
          'Connection error. Please check your internet connection.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse(ApiEndpoints.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        startResendTimer();
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        errorMessage.value = responseData['message'] ?? 'Failed to resend OTP';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Connection error. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Start resend OTP timer (robust 30s countdown)
  void startResendTimer({int seconds = 30}) {
    // Cancel any existing timer to avoid multiple concurrent timers
    _timer?.cancel();

    canResend.value = false;
    resendTimer.value = seconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendTimer.value > 0) {
        resendTimer.value = resendTimer.value - 1;
      }

      if (resendTimer.value <= 0) {
        canResend.value = true;
        t.cancel();
        _timer = null;
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    _timer = null;
    super.onClose();
  }
}
