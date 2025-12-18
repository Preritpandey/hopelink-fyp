import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserRegistrationController extends GetxController {
  static UserRegistrationController get to => Get.find();
  final bool permanent = true; // Add this line to make the instance permanent
  final String baseUrl = 'http://localhost:3008/api/v1';
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString token = ''.obs;
  final Rx<Map<String, dynamic>> userData = Rx<Map<String, dynamic>>({});

  // Text editing controllers
  late TextEditingController nameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    // Initialize any required resources
  }

  @override
  void onClose() {
    // Dispose controllers when the controller is closed
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    super.onClose();
  }

  // Clear all form fields
  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
  }

  // Register user
  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        token.value = responseData['token'] ?? '';
        userData.value = responseData['user'] ?? {};

        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token.value);
        await prefs.setBool(
          'is_logged_in',
          false,
        ); // Mark as not fully logged in until OTP verification

        // Always navigate to OTP verification page after registration
        Get.offAllNamed(
          '/verify-otp',
          arguments: {'email': email, 'token': token.value},
        );

        // Clear the form after navigation
        clearForm();
      } else {
        // If backend returns specific message for pending verification, still redirect
        final msg =
            responseData['message'] ??
            responseData['error'] ??
            'Registration failed';
        errorMessage.value = msg;
        if (response.statusCode == 400 &&
            msg.toString().toLowerCase().contains('already in use')) {
          // Attempt to detect existing unverified based on backend improvements not available
          Get.snackbar(
            'Email in use',
            'If you already registered, please verify your email.',
          );
        } else {
          Get.snackbar('Error', errorMessage.value);
        }
      }
    } catch (e) {
      errorMessage.value = 'An error occurred. Please try again.';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      isLoading.value = true;
      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update user verification status
        userData.update((val) {
          val?['isVerified'] = true;
        });
        return true;
      } else {
        errorMessage.value =
            responseData['message'] ?? 'OTP verification failed';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred during OTP verification';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // In resend otp.
  Future<bool> resendOtp(String email) async {
    try {
      isLoading.value = true;
      final response = await http.post(
        Uri.parse(ApiEndpoints.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        errorMessage.value = responseData['message'] ?? 'Failed to resend OTP';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to connect to server';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
