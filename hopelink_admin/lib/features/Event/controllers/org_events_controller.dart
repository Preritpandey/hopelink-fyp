// ─────────────────────────────────────────────────────────────
//  CONTROLLER  —  org_events_controller.dart
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopelink_admin/features/Event/models/event_volunteer_model.dart';
import 'package:hopelink_admin/features/Event/models/org_event_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrgEventsController extends GetxController {
  static const _base = 'http://localhost:3008/api/v1';
  static const _tokenKey = 'auth_token';
  static const _orgIdKey = 'org_id';

  // ── State ────────────────────────────────────────────────────
  final allEvents = <OrgEvent>[].obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final activeFilter = OrgEventFilter.all.obs;
  final viewMode = EventViewMode.grid.obs;
  final searchQuery = ''.obs;
  final selectedEvent = Rxn<OrgEvent>();

  // ── Volunteer Management State ────────────────────────────────
  final eventVolunteers = <EventVolunteer>[].obs;
  final isLoadingVolunteers = false.obs;
  final volunteersError = ''.obs;
  final volunteerActionLoading = <String>[].obs; // IDs of volunteers loading
  final isUpdatingEvent = false.obs;
  final updateEventError = ''.obs;
  final isDeletingEvent = false.obs;

  // ── Meta ─────────────────────────────────────────────────────
  final total = 0.obs;
  final pages = 1.obs;
  final currentPage = 1.obs;

  // ── Session ──────────────────────────────────────────────────
  String _token = '';
  String _orgId = '';
  String orgName = '';

  final searchCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadAndFetch();
    searchCtrl.addListener(() => searchQuery.value = searchCtrl.text);
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    _orgId = prefs.getString(_orgIdKey) ?? '';
    orgName = prefs.getString('org_name') ?? 'Your Organization';
    await fetchEvents();
  }

  /// Exposes org ID from SharedPreferences (mirrors provided helper)
  Future<String?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgIdKey);
  }

  // ── Fetch ─────────────────────────────────────────────────────
  Future<void> fetchEvents({int page = 1}) async {
    if (_orgId.isEmpty) {
      errorMsg.value = 'Organization ID not found. Please log in again.';
      return;
    }

    isLoading.value = true;
    errorMsg.value = '';

    try {
      final uri = Uri.parse(
        '$_base/events/organization/$_orgId?page=$page&limit=20',
      );

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        final resp = OrgEventsResponse.fromJson(json);
        if (page == 1) {
          allEvents.assignAll(resp.data);
        } else {
          allEvents.addAll(resp.data);
        }
        total.value = resp.total;
        pages.value = resp.pages;
        currentPage.value = resp.page;
      } else {
        errorMsg.value = json['message'] as String? ?? 'Failed to load events.';
      }
    } on SocketException {
      errorMsg.value = 'No internet connection.';
    } on TimeoutException {
      errorMsg.value = 'Request timed out. Please try again.';
    } catch (e) {
      errorMsg.value = 'Unexpected error: $e';
    }

    isLoading.value = false;
  }

  @override
  Future<void> refresh() => fetchEvents(page: 1);

  // ── Filtering & Search ────────────────────────────────────────
  void setFilter(OrgEventFilter f) => activeFilter.value = f;
  void toggleViewMode() {
    viewMode.value = viewMode.value == EventViewMode.grid
        ? EventViewMode.list
        : EventViewMode.grid;
  }

  List<OrgEvent> get filteredEvents {
    var list = allEvents.toList();

    // Status filter
    if (activeFilter.value != OrgEventFilter.all) {
      final status = activeFilter.value.statusValue;
      list = list.where((e) => e.status == status).toList();
    }

    // Search
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.location.city.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  // ── Stats ─────────────────────────────────────────────────────
  int get publishedCount =>
      allEvents.where((e) => e.status == 'published').length;
  int get ongoingCount => allEvents.where((e) => e.status == 'ongoing').length;
  int get totalVolunteers =>
      allEvents.fold(0, (sum, e) => sum + e.volunteerCount);
  int get withImagesCount => allEvents.where((e) => e.hasImages).length;

  // ── Detail view ───────────────────────────────────────────────
  void openDetail(OrgEvent event) => selectedEvent.value = event;
  void closeDetail() => selectedEvent.value = null;

  // ── Formatters ────────────────────────────────────────────────
  String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
  String formatShortDate(DateTime dt) => DateFormat('MMM dd').format(dt);

  String durationLabel(OrgEvent e) {
    final diff = e.endDate.difference(e.startDate).inDays;
    if (diff == 0) return '1 Day';
    return '$diff Days';
  }

  // ── Volunteer Management ──────────────────────────────────────
  Future<void> fetchEventVolunteers(String eventId) async {
    isLoadingVolunteers.value = true;
    volunteersError.value = '';

    try {
      final uri = Uri.parse('$_base/events/$eventId/volunteers');
      print('Fetching volunteers from: $uri'); // Debug log")
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      print(
        'Volunteer fetch response: ${res.statusCode} - ${res.body}',
      ); // Debug log

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        final resp = EventVolunteersResponse.fromJson(json);
        eventVolunteers.assignAll(resp.enrollments);
      } else {
        volunteersError.value =
            json['message'] as String? ?? 'Failed to load volunteers.';
      }
    } on SocketException {
      volunteersError.value = 'No internet connection.';
    } on TimeoutException {
      volunteersError.value = 'Request timed out. Please try again.';
    } catch (e) {
      volunteersError.value = 'Unexpected error: $e';
    }

    isLoadingVolunteers.value = false;
  }

  Future<void> updateVolunteerStatus(
    String eventId,
    String enrollmentId,
    String newStatus, {
    String? notes,
  }) async {
    volunteerActionLoading.add(enrollmentId);

    try {
      final body = UpdateVolunteerStatusRequest(
        status: newStatus,
        approverNotes: notes,
      );

      final uri = Uri.parse('$_base/events/volunteers/$enrollmentId');

      final res = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        // Find and update the volunteer in the list
        final idx = eventVolunteers.indexWhere((v) => v.id == enrollmentId);
        if (idx != -1) {
          final updated = EventVolunteer.fromJson(json['data']);
          eventVolunteers[idx] = updated;
        }
        // Also refresh the event to update volunteer count
        await fetchEvents();
      } else {
        volunteersError.value =
            json['message'] as String? ?? 'Failed to update volunteer status.';
      }
    } on SocketException {
      volunteersError.value = 'No internet connection.';
    } on TimeoutException {
      volunteersError.value = 'Request timed out. Please try again.';
    } catch (e) {
      volunteersError.value = 'Unexpected error: $e';
    }

    volunteerActionLoading.remove(enrollmentId);
  }

  // ── Event Management ──────────────────────────────────────────
  Future<void> updateEvent(
    String eventId,
    UpdateEventRequest updateData,
  ) async {
    isUpdatingEvent.value = true;
    updateEventError.value = '';

    try {
      final uri = Uri.parse('$_base/events/$eventId');

      final res = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updateData.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        // Refresh the events list to show updates
        await fetchEvents();
        closeDetail();
        Get.snackbar(
          'Success',
          'Event updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        updateEventError.value =
            json['message'] as String? ?? 'Failed to update event.';
      }
    } on SocketException {
      updateEventError.value = 'No internet connection.';
    } on TimeoutException {
      updateEventError.value = 'Request timed out. Please try again.';
    } catch (e) {
      updateEventError.value = 'Unexpected error: $e';
    }

    isUpdatingEvent.value = false;
  }

  Future<void> deleteEvent(String eventId) async {
    isDeletingEvent.value = true;
    updateEventError.value = '';

    try {
      final uri = Uri.parse('$_base/events/$eventId');

      final res = await http
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        // Remove from list
        allEvents.removeWhere((e) => e.id == eventId);
        closeDetail();
        Get.snackbar(
          'Success',
          'Event deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        updateEventError.value =
            json['message'] as String? ?? 'Failed to delete event.';
      }
    } on SocketException {
      updateEventError.value = 'No internet connection.';
    } on TimeoutException {
      updateEventError.value = 'Request timed out. Please try again.';
    } catch (e) {
      updateEventError.value = 'Unexpected error: $e';
    }

    isDeletingEvent.value = false;
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
