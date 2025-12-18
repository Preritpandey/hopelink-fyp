import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final String baseUrl = 'http://localhost:3008/api/v1';

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // Validate password
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        errorMessage.value = 'Email and password are required';
        return false;
      }

      if (!_isValidEmail(email)) {
        errorMessage.value = 'Please enter a valid email address';
        return false;
      }

      if (!_isValidPassword(password)) {
        errorMessage.value = 'Password must be at least 6 characters';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await http
          .post(
            Uri.parse(ApiEndpoints.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Request timed out after 30 seconds'),
          );

      // Handle different status codes
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          if (data['success'] == true && data['token'] != null) {
            final token = data['token'] as String;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
            await prefs.setString(
              'user_email',
              data['user']?['email'] ?? email,
            );
            await prefs.setString('user_name', data['user']?['name'] ?? '');
            await prefs.setBool('is_logged_in', true);
            return true;
          } else {
            errorMessage.value = data['message'] ?? 'Login failed';
            return false;
          }
        } on FormatException {
          errorMessage.value = 'Invalid response from server';
          return false;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        errorMessage.value = 'Invalid email or password';
        return false;
      } else if (response.statusCode == 429) {
        errorMessage.value = 'Too many login attempts. Please try again later';
        return false;
      } else if (response.statusCode >= 500) {
        errorMessage.value = 'Server error. Please try again later';
        return false;
      } else {
        errorMessage.value = 'Login failed. Please try again';
        return false;
      }
    } on SocketException {
      errorMessage.value = 'No internet connection. Please check your network';
      return false;
    } on TimeoutException {
      errorMessage.value = 'Connection timed out. Please try again';
      return false;
    } on FormatException {
      errorMessage.value = 'Invalid response format from server';
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get the stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
