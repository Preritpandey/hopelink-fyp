// ─────────────────────────────────────────────────────────────
//  CONTROLLER  —  campaign_report_controller.dart
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign_report_model.dart';
import '../pages/report_pdf_view_page.dart';

class CampaignReportController extends GetxController {
  static const _base = 'http://localhost:3008/api/v1';
  static const _tokenKey = 'auth_token';

  // ── State ────────────────────────────────────────────────────
  final reports = <CampaignReport>[].obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final selectedReport = Rxn<CampaignReport>();
  final actionLoading = ''.obs; // reportId currently being actioned
  final searchQuery = ''.obs;

  // ── Rejection dialog state ────────────────────────────────────
  final showRejectDialog = false.obs;
  final rejectReasonCtrl = TextEditingController();
  final rejectReasonError = ''.obs;

  // ── Search controller ────────────────────────────────────────
  final searchCtrl = TextEditingController();

  String _token = '';

  // ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _init();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    await fetchPendingReports();
  }

  // ── Token helper (mirrors LoginController pattern) ────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _fileHeaders => {
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  // ─────────────────────────────────────────────────────────────
  //  FETCH PENDING REPORTS
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchPendingReports() async {
    isLoading.value = true;
    errorMsg.value = '';

    try {
      // Ensure token is fresh
      final token = await getToken();
      if (token != null) _token = token;

      final res = await http
          .get(
            Uri.parse('$_base/campaign-reports/pending'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        final resp = CampaignReportsResponse.fromJson(json);
        reports.assignAll(resp.data);
      } else {
        errorMsg.value =
            json['message'] as String? ?? 'Failed to load reports.';
      }
    } on SocketException {
      errorMsg.value = 'No internet connection.';
    } on TimeoutException {
      errorMsg.value = 'Request timed out. Please retry.';
    } catch (e) {
      errorMsg.value = 'Unexpected error: $e';
    }

    isLoading.value = false;
  }

  Future<void> refresh() => fetchPendingReports();

  // ─────────────────────────────────────────────────────────────
  //  APPROVE
  // ─────────────────────────────────────────────────────────────
  Future<void> approveReport(String reportId) async {
    actionLoading.value = reportId;
    try {
      final res = await http
          .put(
            Uri.parse('$_base/campaign-reports/$reportId/approve'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        _removeReport(reportId);
        if (selectedReport.value?.id == reportId) {
          selectedReport.value = null;
        }
        _snack(
          'Report approved successfully',
          isError: false,
          icon: Icons.check_circle_rounded,
        );
      } else {
        _snack(json['message'] as String? ?? 'Approval failed.');
      }
    } on SocketException {
      _snack('No internet connection.');
    } catch (e) {
      _snack('Error: $e');
    }
    actionLoading.value = '';
  }

  // ─────────────────────────────────────────────────────────────
  //  OPEN REJECT DIALOG
  // ─────────────────────────────────────────────────────────────
  void openRejectDialog(CampaignReport report) {
    selectedReport.value = report;
    rejectReasonCtrl.clear();
    rejectReasonError.value = '';
    showRejectDialog.value = true;
  }

  void closeRejectDialog() {
    showRejectDialog.value = false;
    rejectReasonError.value = '';
    rejectReasonCtrl.clear();
  }

  // ─────────────────────────────────────────────────────────────
  //  REJECT
  // ─────────────────────────────────────────────────────────────
  Future<void> rejectReport() async {
    final reason = rejectReasonCtrl.text.trim();
    if (reason.isEmpty) {
      rejectReasonError.value = 'Please provide a rejection reason.';
      return;
    }

    final report = selectedReport.value;
    if (report == null) return;

    closeRejectDialog();
    actionLoading.value = report.id;

    try {
      final res = await http
          .put(
            Uri.parse('$_base/campaign-reports/${report.id}/reject'),
            headers: _authHeaders,
            body: jsonEncode({'reason': reason}),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        _removeReport(report.id);
        if (selectedReport.value?.id == report.id) {
          selectedReport.value = null;
        }
        _snack('Report rejected', isError: false, icon: Icons.cancel_rounded);
      } else {
        _snack(json['message'] as String? ?? 'Rejection failed.');
      }
    } on SocketException {
      _snack('No internet connection.');
    } catch (e) {
      _snack('Error: $e');
    }

    actionLoading.value = '';
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────
  void _removeReport(String id) {
    reports.removeWhere((r) => r.id == id);
  }

  void selectReport(CampaignReport r) => selectedReport.value = r;
  void closeDetail() => selectedReport.value = null;
  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
  }

  String resolveReportUrl(CampaignReport report) {
    final endpoint = report.reportFile.url.isNotEmpty
        ? report.reportFile.url
        : report.downloadEndpoint;

    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }

    if (endpoint.startsWith('/')) {
      return 'http://localhost:3008$endpoint';
    }

    return '$_base/$endpoint';
  }

  Future<void> viewReport(CampaignReport report) async {
    await Get.to(
      () => ReportPdfViewPage(
        title: report.reportFile.originalName,
        pdfUrl: resolveReportUrl(report),
        headers: _fileHeaders,
      ),
    );
  }

  Future<void> downloadReport(CampaignReport report) async {
    try {
      final safeName = report.reportFile.originalName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}${Platform.pathSeparator}$safeName';

      await Dio().download(
        resolveReportUrl(report),
        path,
        options: Options(headers: _fileHeaders),
      );

      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
        _snack('Report downloaded successfully', isError: false);
      } else {
        _snack('Report downloaded to $path', isError: false);
      }
    } on DioException catch (e) {
      _snack(e.response?.statusMessage ?? 'Download failed.');
    } catch (e) {
      _snack('Download failed: $e');
    }
  }

  // ── Filtered list ─────────────────────────────────────────────
  List<CampaignReport> get filtered {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return reports.toList();
    return reports.where((r) {
      return r.campaign.title.toLowerCase().contains(q) ||
          r.organization.organizationName.toLowerCase().contains(q) ||
          r.reportFile.originalName.toLowerCase().contains(q);
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────
  int get pendingCount => reports.length;

  // ── Snackbar helper ───────────────────────────────────────────
  void _snack(String msg, {bool isError = true, IconData? icon}) {
    if (Get.context == null) return;
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    rejectReasonCtrl.dispose();
    super.onClose();
  }
}
