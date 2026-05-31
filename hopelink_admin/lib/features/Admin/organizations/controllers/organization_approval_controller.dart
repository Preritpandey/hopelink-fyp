import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api_endpoints.dart';
import '../models/pending_organization_model.dart';

class OrganizationApprovalController extends GetxController {
  static const _tokenKey = 'auth_token';

  final organizations = <PendingOrganization>[].obs;
  final selectedOrganization = Rxn<PendingOrganization>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final actionLoadingId = ''.obs;
  final searchCtrl = TextEditingController();
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final totalItems = 0.obs;

  String _token = '';
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
    fetchPendingOrganizations();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
  }

  Future<void> fetchPendingOrganizations({int? page}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadToken();
      if (_token.isEmpty) {
        errorMessage.value = 'Admin session expired. Please sign in again.';
        return;
      }

      final targetPage = page ?? currentPage.value;
      final uri = Uri.parse(
        '${ApiEndpoints.adminPendingOrganizations}?page=$targetPage&limit=$_pageSize',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['success'] == true) {
        final parsed = PendingOrganizationsResponse.fromJson(json);
        organizations.assignAll(parsed.data);
        totalItems.value = parsed.count;
        if (parsed.pagination != null) {
          currentPage.value = parsed.pagination!.page;
          totalPages.value = parsed.pagination!.totalPages;
          totalItems.value = parsed.pagination!.totalItems;
        } else {
          currentPage.value = targetPage;
          totalPages.value = 1;
        }
        selectedOrganization.value = organizations.isEmpty
            ? null
            : organizations.firstWhereOrNull(
                    (org) => org.id == selectedOrganization.value?.id,
                  ) ??
                  organizations.first;
      } else {
        errorMessage.value = _messageFromJson(
          json,
          'Failed to load organizations.',
        );
      }
    } on SocketException {
      errorMessage.value = 'No internet connection. Please check your network.';
    } on TimeoutException {
      errorMessage.value = 'Request timed out. Please retry.';
    } on FormatException {
      errorMessage.value = 'Server returned an invalid response.';
    } catch (e) {
      errorMessage.value = 'Unexpected error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => fetchPendingOrganizations();

  List<PendingOrganization> get filteredOrganizations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return organizations.toList();
    return organizations.where((org) {
      return org.organizationName.toLowerCase().contains(query) ||
          org.officialEmail.toLowerCase().contains(query) ||
          org.registrationNumber.toLowerCase().contains(query) ||
          org.representativeName.toLowerCase().contains(query) ||
          org.organizationType.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> approveOrganization(PendingOrganization org) async {
    await _confirmAndAction(
      org: org,
      title: 'Approve organization?',
      message:
          'This will approve ${org.organizationName} and allow the organization to access its portal.',
      confirmLabel: 'Approve',
      endpoint: ApiEndpoints.approveOrganization(org.id),
      successMessage: '${org.organizationName} approved successfully.',
    );
    print('Endpoint: ${ApiEndpoints.approveOrganization(org.id)}');
  }

  Future<void> rejectOrganization(PendingOrganization org) async {
    await _confirmAndAction(
      org: org,
      title: 'Reject organization?',
      message:
          'This will reject ${org.organizationName}. The organization will be removed from the pending review list.',
      confirmLabel: 'Reject',
      endpoint: ApiEndpoints.rejectOrganization(org.id),
      successMessage: '${org.organizationName} rejected.',
      destructive: true,
    );
  }

  Future<void> _confirmAndAction({
    required PendingOrganization org,
    required String title,
    required String message,
    required String confirmLabel,
    required String endpoint,
    required String successMessage,
    bool destructive = false,
  }) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF101827),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFB7C4D8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _runAction(org, endpoint, successMessage);
  }

  Future<void> _runAction(
    PendingOrganization org,
    String endpoint,
    String successMessage,
  ) async {
    actionLoadingId.value = org.id;
    try {
      await _loadToken();
      final response = await http
          .put(Uri.parse(endpoint), headers: _headers)
          .timeout(const Duration(seconds: 15));
      final json = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (json['success'] == true || json.isEmpty)) {
        organizations.removeWhere((item) => item.id == org.id);
        if (selectedOrganization.value?.id == org.id) {
          selectedOrganization.value = organizations.isEmpty
              ? null
              : organizations.first;
        }
        totalItems.value = totalItems.value > 0 ? totalItems.value - 1 : 0;
        _showSnack(successMessage, isError: false);
      } else {
        _showSnack(_messageFromJson(json, 'Action failed.'));
      }
    } on SocketException {
      _showSnack('No internet connection. Please check your network.');
    } on TimeoutException {
      _showSnack('Request timed out. Please retry.');
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      actionLoadingId.value = '';
    }
  }

  void selectOrganization(PendingOrganization org) {
    selectedOrganization.value = org;
  }

  Future<void> nextPage() async {
    if (currentPage.value >= totalPages.value || isLoading.value) return;
    await fetchPendingOrganizations(page: currentPage.value + 1);
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 1 || isLoading.value) return;
    await fetchPendingOrganizations(page: currentPage.value - 1);
  }

  String _messageFromJson(Map<String, dynamic> json, String fallback) {
    final message = json['message'];
    if (message is String && message.isNotEmpty) return message;
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      final nested = error['message'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    return fallback;
  }

  void _showSnack(String message, {bool isError = true}) {
    Get.snackbar(
      isError ? 'Organization review' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      maxWidth: 520,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
