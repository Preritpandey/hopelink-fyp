import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_model.dart';
import '../../Admin/Home/pages/admin_home_page.dart';
import '../../Dashboard/home_page.dart';

class LoginController extends GetxController {
  // ── Form ───────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final errorMessage = ''.obs;
  final loginSuccess = false.obs;
  final currentUser = Rxn<LoginUser>();

  // ── Focus nodes ────────────────────────────────────────────
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  static const _baseUrl = 'http://localhost:3008/api/v1';
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _emailKey = 'saved_email';
  static const _orgIdKey = 'org_id';
  static const _orgNameKey = 'org_name';

  @override
  void onInit() {
    super.onInit();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_emailKey);
    if (saved != null && saved.isNotEmpty) {
      emailCtrl.text = saved;
      rememberMe.value = true;
    }
  }

  void toggleObscure() => obscurePassword.value = !obscurePassword.value;
  void toggleRemember(bool? v) => rememberMe.value = v ?? false;

  // ── Validators ─────────────────────────────────────────────
  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────
  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uri = Uri.parse('$_baseUrl/auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              LoginRequest(
                email: emailCtrl.text.trim(),
                password: passwordCtrl.text,
              ).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['success'] == true) {
        final result = LoginResponse.fromJson(json);

        // Persist token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, result.token);
        await prefs.setString(_roleKey, result.user.role);

        // Save user data and organization info
        final user = result.user;
        final orgId = user.organization.id;
        final orgName = user.organization.name;

        if (orgId.isNotEmpty) {
          await prefs.setString(_orgIdKey, orgId);
        }
        if (orgName.isNotEmpty) {
          await prefs.setString(_orgNameKey, orgName);
        }

        // Save email if remember me
        if (rememberMe.value) {
          await prefs.setString(_emailKey, emailCtrl.text.trim());
        } else {
          await prefs.remove(_emailKey);
        }

        currentUser.value = result.user;
        loginSuccess.value = true;
        if (user.role.toLowerCase() == 'admin') {
          Get.offAll(() => const AdminHomePage());
        } else {
          Get.offAll(() => const DashboardShell());
        }

        // Navigate to dashboard — adjust route as needed
        // Get.offAllNamed('/dashboard');
      } else {
        errorMessage.value =
            json['message'] as String? ?? 'Invalid credentials.';
      }
    } on SocketException {
      errorMessage.value = 'No internet connection. Please check your network.';
    } on TimeoutException {
      errorMessage.value = 'Request timed out. Please try again.';
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Sign out helper ─────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_orgIdKey);
    await prefs.remove(_orgNameKey);
    currentUser.value = null;
    loginSuccess.value = false;
    passwordCtrl.clear();
    errorMessage.value = '';
  }

  // Get the stored authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get the stored organization ID
  Future<String?> getOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgIdKey);
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }
}
