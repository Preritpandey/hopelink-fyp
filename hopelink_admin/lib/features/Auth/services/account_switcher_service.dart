import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hopelink_admin/core/api_endpoints.dart';
import 'package:hopelink_admin/features/Auth/models/login_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final String email;
  final String password;
  final String name;
  final String role;
  final String orgId;
  final String orgName;

  const SavedAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.orgId,
    required this.orgName,
  });

  String get displayName {
    if (role.toLowerCase() == 'organization' && orgName.isNotEmpty) {
      return orgName;
    }
    if (name.isNotEmpty) return name;
    return email;
  }

  String get subtitle => role.toLowerCase() == 'admin'
      ? 'Main admin panel'
      : 'Organization panel';

  String get initials {
    final source = displayName.trim().isNotEmpty ? displayName.trim() : email;
    return source.substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'orgId': orgId,
        'orgName': orgName,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      orgId: json['orgId'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
    );
  }
}

class AccountSwitcherService {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _orgIdKey = 'org_id';
  static const _orgNameKey = 'org_name';
  static const _accountsKey = 'saved_switch_accounts';
  static const _activeEmailKey = 'active_account_email';

  Future<List<SavedAccount>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedAccount.fromJson)
          .where((account) =>
              account.email.isNotEmpty && account.password.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> getActiveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeEmailKey);
  }

  Future<void> persistLogin({
    required LoginResponse result,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = result.user;
    final orgId = user.organization.id;
    final orgName = user.organization.name;

    await prefs.setString(_tokenKey, result.token);
    await prefs.setString(_roleKey, user.role);
    await prefs.setString(_activeEmailKey, email);

    if (orgId.isNotEmpty) {
      await prefs.setString(_orgIdKey, orgId);
    } else {
      await prefs.remove(_orgIdKey);
    }

    if (orgName.isNotEmpty) {
      await prefs.setString(_orgNameKey, orgName);
    } else {
      await prefs.remove(_orgNameKey);
    }

    await _upsertAccount(
      SavedAccount(
        email: email,
        password: password,
        name: user.name,
        role: user.role,
        orgId: orgId,
        orgName: orgName,
      ),
    );
  }

  Future<LoginUser> switchTo(SavedAccount account) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              LoginRequest(
                email: account.email,
                password: account.password,
              ).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || json['success'] != true) {
        throw AccountSwitchException(
          json['message'] as String? ?? 'Could not switch account.',
        );
      }

      final result = LoginResponse.fromJson(json);
      await persistLogin(
        result: result,
        email: account.email,
        password: account.password,
      );
      return result.user;
    } on SocketException {
      throw const AccountSwitchException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const AccountSwitchException('Request timed out. Please try again.');
    } on AccountSwitchException {
      rethrow;
    } catch (_) {
      throw const AccountSwitchException(
        'Could not switch account. Please sign in again.',
      );
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_orgIdKey);
    await prefs.remove(_orgNameKey);
    await prefs.remove(_activeEmailKey);
  }

  Future<void> _upsertAccount(SavedAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getAccounts();
    final next = [
      account,
      ...accounts.where(
        (existing) =>
            existing.email.toLowerCase() != account.email.toLowerCase(),
      ),
    ];

    await prefs.setString(
      _accountsKey,
      jsonEncode(next.map((account) => account.toJson()).toList()),
    );
  }
}

class AccountSwitchException implements Exception {
  final String message;
  const AccountSwitchException(this.message);

  @override
  String toString() => message;
}
