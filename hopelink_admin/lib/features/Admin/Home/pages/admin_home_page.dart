import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopelink_admin/features/Admin/reports/pages/admin_reports_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Auth/pages/login_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _orgIdKey = 'org_id';
  static const _orgNameKey = 'org_name';

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_orgIdKey);
    await prefs.remove(_orgNameKey);
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return AdminReportsPage();
  }
}
