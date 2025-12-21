import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString userEmail = ''.obs;

  static const String baseUrl = 'http://localhost:3008/api/v1/auth';

  Future<bool> sendOTP({required String email}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        userEmail.value = email;
        return true;
      } else {
        errorMessage.value = data['message'] ?? 'Failed to send OTP';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Network error. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return true;
        } else {
          errorMessage.value = data['message'] ?? 'Failed to reset password';
          return false;
        }
      } else {
        // Handle different error status codes
        if (response.statusCode == 400) {
          errorMessage.value = data['message'] ?? 'Invalid request';
        } else if (response.statusCode >= 500) {
          errorMessage.value = 'Server error. Please try again later.';
        } else {
          errorMessage.value = 'An error occurred. Please try again.';
        }
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Network error. Please check your connection.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // Future<bool> resetPassword({
  //   required String email,
  //   required String otp,
  //   required String newPassword,
  // }) async {
  //   try {
  //     isLoading.value = true;
  //     errorMessage.value = '';

  //     final response = await http.post(
  //       Uri.parse('$baseUrl/reset-password'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'email': email,
  //         'otp': otp,
  //         'newPassword': newPassword,
  //       }),
  //     );

  //     final data = json.decode(response.body);

  //     if (response.statusCode == 200 && data['success'] == true) {
  //       return true;
  //     } else {
  //       errorMessage.value = data['message'] ?? 'Failed to reset password';
  //       return false;
  //     }
  //   } catch (e) {
  //     errorMessage.value = 'Network error. Please try again.';
  //     return false;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
