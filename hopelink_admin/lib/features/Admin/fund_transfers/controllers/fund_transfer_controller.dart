import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api_endpoints.dart';
import '../../../Auth/services/account_switcher_service.dart';
import '../models/fund_transfer_model.dart';

class FundTransferController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _pageSize = 10;

  final transfers = <FundTransfer>[].obs;
  final donationSummaries = <DonationOrgSummary>[].obs;
  final selectedTransfer = Rxn<FundTransfer>();
  final stats = FundTransferStats.empty().obs;
  final isLoading = false.obs;
  final actionLoading = false.obs;
  final errorMessage = ''.obs;
  final statusFilter = 'all'.obs;
  final searchQuery = ''.obs;
  final currentPage = 1.obs;
  final totalItems = 0.obs;
  final nextPage = RxnInt();
  final prevPage = RxnInt();

  final searchCtrl = TextEditingController();
  String _token = '';
  Future<bool>? _sessionRefresh;

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
    refreshAll();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
  }

  Future<void> refreshAll() async {
    await fetchTransfers(page: 1);
    if (errorMessage.value == _staleSessionMessage) return;
    await Future.wait([
      fetchStats(),
      fetchDonationSummaries(),
    ]);
  }

  Future<void> fetchTransfers({int? page, bool retryAuth = true}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      if (_token.isEmpty) {
        errorMessage.value = 'Admin session expired. Please sign in again.';
        return;
      }

      final targetPage = page ?? currentPage.value;
      final params = <String, String>{
        'page': '$targetPage',
        'limit': '$_pageSize',
        if (statusFilter.value != 'all') 'status': statusFilter.value,
      };
      final uri = Uri.parse(
        ApiEndpoints.fundTransfers,
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final parsed = FundTransferResponse.fromJson(json);
        transfers.assignAll(parsed.data);
        currentPage.value = parsed.pagination?.page ?? targetPage;
        totalItems.value = parsed.pagination?.total ?? parsed.data.length;
        nextPage.value = parsed.pagination?.nextPage;
        prevPage.value = parsed.pagination?.prevPage;
        selectedTransfer.value = transfers.isEmpty
            ? null
            : transfers.firstWhereOrNull(
                    (item) => item.id == selectedTransfer.value?.id,
                  ) ??
            transfers.first;
      } else if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          await fetchTransfers(page: page, retryAuth: false);
        } else {
          errorMessage.value = _staleSessionMessage;
        }
      } else {
        errorMessage.value = _messageFromJson(json, 'Failed to load transfers.');
      }
    } on SocketException {
      errorMessage.value = 'No internet connection. Please check your network.';
    } on TimeoutException {
      errorMessage.value = 'Request timed out. Please retry.';
    } catch (e) {
      errorMessage.value = 'Unexpected error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats({bool retryAuth = true}) async {
    try {
      await _loadToken();
      final response = await http
          .get(Uri.parse(ApiEndpoints.fundTransferStats), headers: _headers)
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          stats.value = FundTransferStats.fromJson(data);
        }
      } else if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          await fetchStats(retryAuth: false);
        }
      }
    } catch (_) {
      // Stats should not block the transfer list.
    }
  }

  Future<void> fetchDonationSummaries({bool retryAuth = true}) async {
    try {
      await _loadToken();
      final response = await http
          .get(Uri.parse(ApiEndpoints.allDonationSummaries), headers: _headers)
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as List? ?? [];
        donationSummaries.assignAll(
          data
              .whereType<Map<String, dynamic>>()
              .map(DonationOrgSummary.fromJson)
              .toList(),
        );
      } else if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          await fetchDonationSummaries(retryAuth: false);
        }
      }
    } catch (_) {
      // Optional helper data for the create dialog.
    }
  }

  Future<bool> initiateTransfer({
    required String organizationId,
    required double amount,
    required String transferMethod,
    required String reason,
    String reference = '',
    String notes = '',
    bool retryAuth = true,
  }) async {
    if (organizationId.trim().isEmpty) {
      _showSnack('Organization ID is required.');
      return false;
    }
    if (amount <= 0) {
      _showSnack('Amount must be greater than 0.');
      return false;
    }
    if (reason.trim().isEmpty) {
      _showSnack('Reason is required.');
      return false;
    }

    actionLoading.value = true;
    try {
      await _loadToken();
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.fundTransfers),
            headers: _headers,
            body: jsonEncode({
              'organizationId': organizationId.trim(),
              'amount': amount,
              'transferMethod': transferMethod,
              'reason': reason.trim(),
              if (reference.trim().isNotEmpty) 'reference': reference.trim(),
              if (notes.trim().isNotEmpty) 'notes': notes.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['success'] == true) {
        _showSnack(
          json['message'] as String? ?? 'Fund transfer initiated.',
          isError: false,
        );
        await refreshAll();
        return true;
      }
      if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          return initiateTransfer(
            organizationId: organizationId,
            amount: amount,
            transferMethod: transferMethod,
            reason: reason,
            reference: reference,
            notes: notes,
            retryAuth: false,
          );
        }
        _showSnack(_staleSessionMessage);
        return false;
      }
      _showSnack(_messageFromJson(json, 'Failed to initiate transfer.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      actionLoading.value = false;
    }
    return false;
  }

  Future<bool> updateTransferStatus(
    FundTransfer transfer, {
    required String status,
    String transactionHash = '',
    String notes = '',
    String failureReason = '',
    bool retryAuth = true,
  }) async {
    actionLoading.value = true;
    try {
      await _loadToken();
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.fundTransferStatus(transfer.id)),
            headers: _headers,
            body: jsonEncode({
              'status': status,
              if (transactionHash.trim().isNotEmpty)
                'transactionHash': transactionHash.trim(),
              if (notes.trim().isNotEmpty) 'notes': notes.trim(),
              if (failureReason.trim().isNotEmpty)
                'failureReason': failureReason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        _showSnack(
          json['message'] as String? ?? 'Transfer status updated.',
          isError: false,
        );
        await refreshAll();
        return true;
      }
      if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          return updateTransferStatus(
            transfer,
            status: status,
            transactionHash: transactionHash,
            notes: notes,
            failureReason: failureReason,
            retryAuth: false,
          );
        }
        _showSnack(_staleSessionMessage);
        return false;
      }
      _showSnack(_messageFromJson(json, 'Failed to update status.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      actionLoading.value = false;
    }
    return false;
  }

  Future<bool> cancelTransfer(
    FundTransfer transfer,
    String reason, {
    bool retryAuth = true,
  }) async {
    if (reason.trim().isEmpty) {
      _showSnack('Cancellation reason is required.');
      return false;
    }
    actionLoading.value = true;
    try {
      await _loadToken();
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.cancelFundTransfer(transfer.id)),
            headers: _headers,
            body: jsonEncode({'reason': reason.trim()}),
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        _showSnack(
          json['message'] as String? ?? 'Transfer cancelled.',
          isError: false,
        );
        await refreshAll();
        return true;
      }
      if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          return cancelTransfer(transfer, reason, retryAuth: false);
        }
        _showSnack(_staleSessionMessage);
        return false;
      }
      _showSnack(_messageFromJson(json, 'Failed to cancel transfer.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      actionLoading.value = false;
    }
    return false;
  }

  Future<FundTransferReceipt?> fetchReceipt(
    FundTransfer transfer, {
    bool retryAuth = true,
  }) async {
    actionLoading.value = true;
    try {
      await _loadToken();
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.fundTransferReceipt(transfer.id)),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          return FundTransferReceipt.fromJson(data);
        }
      }
      if (_isUnauthorized(response.statusCode, json) && retryAuth) {
        if (await _refreshStaleAdminSession()) {
          return fetchReceipt(transfer, retryAuth: false);
        }
        _showSnack(_staleSessionMessage);
        return null;
      }
      _showSnack(_messageFromJson(json, 'Failed to load receipt.'));
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      actionLoading.value = false;
    }
    return null;
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
    fetchTransfers(page: 1);
  }

  void selectTransfer(FundTransfer transfer) {
    selectedTransfer.value = transfer;
  }

  Future<void> next() async {
    final page = nextPage.value;
    if (page == null || isLoading.value) return;
    await fetchTransfers(page: page);
  }

  Future<void> previous() async {
    final page = prevPage.value;
    if (page == null || isLoading.value) return;
    await fetchTransfers(page: page);
  }

  List<FundTransfer> get filteredTransfers {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return transfers.toList();
    return transfers.where((transfer) {
      return transfer.displayId.toLowerCase().contains(query) ||
          transfer.organizationName.toLowerCase().contains(query) ||
          transfer.reference.toLowerCase().contains(query) ||
          transfer.reason.toLowerCase().contains(query);
    }).toList();
  }

  List<TransferOrganization> get knownOrganizations {
    final map = <String, TransferOrganization>{};
    for (final transfer in transfers) {
      final org = transfer.organization;
      if (org != null && org.id.isNotEmpty) map[org.id] = org;
    }
    return map.values.toList()
      ..sort((a, b) => a.organizationName.compareTo(b.organizationName));
  }

  double collectedForOrg(String organizationId) {
    return donationSummaries
        .where((item) => item.organizationId == organizationId)
        .fold(0, (sum, item) => sum + item.totalAmount);
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.compact(locale: 'en');
    return 'NPR ${formatter.format(amount)}';
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String formatDateTime(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM dd, yyyy - h:mm a').format(date);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static const _staleSessionMessage =
      'Your admin session is stale. Please sign in again.';

  bool _isUnauthorized(int statusCode, Map<String, dynamic> json) {
    final message = _messageFromJson(json, '').toLowerCase();
    return statusCode == 401 ||
        message.contains('user not found') ||
        message.contains('token expired') ||
        message.contains('invalid token');
  }

  Future<bool> _refreshStaleAdminSession() async {
    final inFlight = _sessionRefresh;
    if (inFlight != null) return inFlight;
    _sessionRefresh = _refreshStaleAdminSessionInner();
    final refreshed = await _sessionRefresh!;
    _sessionRefresh = null;
    return refreshed;
  }

  Future<bool> _refreshStaleAdminSessionInner() async {
    try {
      final service = AccountSwitcherService();
      final activeEmail = await service.getActiveEmail();
      if (activeEmail == null || activeEmail.isEmpty) return false;

      final accounts = await service.getAccounts();
      final account = accounts.firstWhereOrNull(
        (item) =>
            item.email.toLowerCase() == activeEmail.toLowerCase() &&
            item.role.toLowerCase() == 'admin',
      );
      if (account == null) return false;

      await service.switchTo(account);
      await _loadToken();
      return _token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _messageFromJson(Map<String, dynamic> json, String fallback) {
    final message = json['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      final nested = error['message'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }
    return fallback;
  }

  void _showSnack(String message, {bool isError = true}) {
    Get.snackbar(
      isError ? 'Fund transfer' : 'Success',
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
