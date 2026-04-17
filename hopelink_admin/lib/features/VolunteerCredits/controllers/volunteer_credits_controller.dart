import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hopelink_admin/core/api_endpoints.dart';
import 'package:hopelink_admin/features/Event/models/org_event_model.dart';
import 'package:hopelink_admin/features/Jobs/models/job_model.dart';
import 'package:hopelink_admin/features/VolunteerCredits/models/volunteer_credit_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerCreditsController extends GetxController {
  static const _tokenKey = 'auth_token';
  static const _orgIdKey = 'org_id';

  final sourceType = VolunteerCreditSource.job.obs;
  final sourceOptions = <VolunteerCreditSourceOption>[].obs;
  final selectedSource = Rxn<VolunteerCreditSourceOption>();
  final entries = <VolunteerCreditEntry>[].obs;
  final selectedEntry = Rxn<VolunteerCreditEntry>();

  final isBootstrapping = false.obs;
  final isLoadingSources = false.obs;
  final isLoadingEntries = false.obs;
  final sourceError = ''.obs;
  final entriesError = ''.obs;
  final searchQuery = ''.obs;
  final actionLoadingId = ''.obs;

  String _token = '';
  String _orgId = '';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isBootstrapping.value = true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    _orgId = prefs.getString(_orgIdKey) ?? '';
    await fetchSources();
    isBootstrapping.value = false;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<void> fetchSources() async {
    isLoadingSources.value = true;
    sourceError.value = '';
    selectedSource.value = null;
    entries.clear();
    selectedEntry.value = null;

    try {
      if (sourceType.value == VolunteerCreditSource.job) {
        final res = await http
            .get(
              Uri.parse('${ApiEndpoints.volunteerJobs}/org/my'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 15));
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && json['success'] == true) {
          final data = VolunteerJobsResponse.fromJson(json).data;
          sourceOptions.assignAll(
            data.map(VolunteerCreditSourceOption.fromJob).toList(),
          );
        } else {
          sourceError.value =
              json['message'] as String? ?? 'Failed to load volunteer jobs.';
        }
      } else {
        if (_orgId.isEmpty) {
          sourceError.value =
              'Organization ID not found. Please sign in again.';
          sourceOptions.clear();
        } else {
          final uri = Uri.parse(
            '${ApiEndpoints.baseUrl}/events/organization/$_orgId?page=1&limit=50',
          );
          final res = await http
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 15));
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          if (res.statusCode == 200 && json['success'] == true) {
            final data = OrgEventsResponse.fromJson(json).data;
            sourceOptions.assignAll(
              data.map(VolunteerCreditSourceOption.fromEvent).toList(),
            );
          } else {
            sourceError.value =
                json['message'] as String? ?? 'Failed to load events.';
          }
        }
      }

      if (sourceOptions.isNotEmpty) {
        selectedSource.value = sourceOptions.first;
        await fetchEntries();
      }
    } on SocketException {
      sourceError.value = 'No internet connection.';
    } on TimeoutException {
      sourceError.value = 'Request timed out. Please try again.';
    } catch (e) {
      sourceError.value = 'Unexpected error: $e';
    }

    isLoadingSources.value = false;
  }

  Future<void> fetchEntries() async {
    final source = selectedSource.value;
    if (source == null) return;

    isLoadingEntries.value = true;
    entriesError.value = '';
    entries.clear();
    selectedEntry.value = null;

    try {
      late final Uri uri;
      late final VolunteerCreditListResponse parsed;

      if (source.source == VolunteerCreditSource.job) {
        uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/volunteer-applications/job/${source.id}/approved',
        );
        final res = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && json['success'] == true) {
          parsed = VolunteerCreditListResponse.fromJobJson(json);
        } else {
          entriesError.value =
              json['message'] as String? ??
              'Failed to load approved volunteers.';
          isLoadingEntries.value = false;
          return;
        }
      } else {
        uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/events/${source.id}/volunteers/approved',
        );
        final res = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && json['success'] == true) {
          parsed = VolunteerCreditListResponse.fromEventJson(json);
        } else {
          entriesError.value =
              json['message'] as String? ??
              'Failed to load approved event participants.';
          isLoadingEntries.value = false;
          return;
        }
      }

      entries.assignAll(parsed.data);
      if (entries.isNotEmpty) {
        selectedEntry.value = entries.first;
      }
    } on SocketException {
      entriesError.value = 'No internet connection.';
    } on TimeoutException {
      entriesError.value = 'Request timed out. Please try again.';
    } catch (e) {
      entriesError.value = 'Unexpected error: $e';
    }

    isLoadingEntries.value = false;
  }

  void switchSourceType(VolunteerCreditSource next) {
    if (sourceType.value == next) return;
    sourceType.value = next;
    searchQuery.value = '';
    fetchSources();
  }

  void selectSource(VolunteerCreditSourceOption? option) {
    if (option == null) return;
    selectedSource.value = option;
    fetchEntries();
  }

  void selectEntry(VolunteerCreditEntry entry) {
    selectedEntry.value = entry;
  }

  List<VolunteerCreditEntry> get filteredEntries {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries.where((entry) {
      return entry.user.name.toLowerCase().contains(q) ||
          entry.user.email.toLowerCase().contains(q) ||
          entry.user.skills.any((skill) => skill.toLowerCase().contains(q));
    }).toList();
  }

  bool get canGrantSelectedCredits {
    final source = selectedSource.value;
    final entry = selectedEntry.value;
    if (source == null || entry == null) return false;
    return !entry.creditsGranted;
  }

  Future<void> grantCredits(VolunteerCreditEntry entry) async {
    actionLoadingId.value = entry.id;
    try {
      late final Uri uri;

      if (entry.source == VolunteerCreditSource.job) {
        uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/volunteer-applications/${entry.id}/credit-hours',
        );
      } else {
        uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/events/enrollments/${entry.id}/credit-hours',
        );
      }

      final res = await http
          .patch(uri, headers: _headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        final granted = GrantCreditHoursResponse.fromJson(json);
        final idx = entries.indexWhere((e) => e.id == entry.id);
        if (idx != -1) {
          final updated = entries[idx].copyWith(
            creditHoursGranted: granted.creditHoursGranted,
            creditGrantedAt: granted.creditGrantedAt,
          );
          entries[idx] = updated;
          if (selectedEntry.value?.id == updated.id) {
            selectedEntry.value = updated;
          }
        }
        _showSnack(granted.message, isError: false);
      } else {
        _showSnack(
          json['message'] as String? ?? 'Failed to grant credit hours.',
        );
      }
    } on SocketException {
      _showSnack('No internet connection.');
    } on TimeoutException {
      _showSnack('Request timed out. Please try again.');
    } catch (e) {
      _showSnack('Unexpected error: $e');
    }

    actionLoadingId.value = '';
  }

  String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

  String formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('MMM dd, yyyy - h:mm a').format(date.toLocal());
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (Get.context == null) return;
    Get.snackbar(
      isError ? 'Error' : 'Success',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
      colorText: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
