import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_model.dart';

enum ActivityFilter { all, donation, eventRegistration, volunteerJob }

class ActivityController extends GetxController {
  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------

  final RxList<ActivityModel> _allActivities = <ActivityModel>[].obs;
  final RxList<ActivityModel> filteredActivities = <ActivityModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchText = ''.obs;
  final Rx<ActivityFilter> selectedFilter = ActivityFilter.all.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;

  // -------------------------------------------------------------------------
  // Config
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    fetchActivities();
  }

  // -------------------------------------------------------------------------
  // Auth helper
  // -------------------------------------------------------------------------

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // API call
  // -------------------------------------------------------------------------

  Future<void> fetchActivities({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isRefreshing.value = true;
        currentPage.value = 1;
      } else {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final token = await _getAuthToken();
      if (token == null) {
        errorMessage.value =
            'You are not authenticated. Please log in and try again.';
        return;
      }

      final uri = Uri.parse(
        ApiEndpoints.userActivities,
      ).replace(queryParameters: {'page': currentPage.value.toString()});

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final activitiesResponse = ActivitiesResponse.fromJson(decoded);

        if (activitiesResponse.success) {
          if (isRefresh || currentPage.value == 1) {
            _allActivities.assignAll(activitiesResponse.data);
          } else {
            _allActivities.addAll(activitiesResponse.data);
          }
          totalPages.value = activitiesResponse.pages;
          totalCount.value = activitiesResponse.total;
          _applyFilters();
        } else {
          errorMessage.value = 'Failed to load activities. Please try again.';
        }
      } else if (response.statusCode == 401) {
        errorMessage.value = 'Session expired. Please log in again.';
      } else if (response.statusCode == 403) {
        errorMessage.value = 'You do not have permission to view activities.';
      } else if (response.statusCode >= 500) {
        errorMessage.value = 'Server error. Please try again later.';
      } else {
        errorMessage.value =
            'Unexpected error (${response.statusCode}). Please try again.';
      }
    } on Exception catch (e) {
      debugPrint('fetchActivities error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage.value =
            'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage.value = 'Request timed out. Please try again.';
      } else {
        errorMessage.value = 'Something went wrong. Please try again.';
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // -------------------------------------------------------------------------
  // Load more (pagination)
  // -------------------------------------------------------------------------

  Future<void> loadMore() async {
    if (currentPage.value >= totalPages.value || isLoading.value) return;
    currentPage.value++;
    await fetchActivities();
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  void search(String query) {
    searchText.value = query;
    _applyFilters();
  }

  // -------------------------------------------------------------------------
  // Filter
  // -------------------------------------------------------------------------

  void setFilter(ActivityFilter filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  // -------------------------------------------------------------------------
  // Internal — combine search + filter
  // -------------------------------------------------------------------------

  void _applyFilters() {
    List<ActivityModel> result = List.from(_allActivities);

    // Activity type filter
    if (selectedFilter.value != ActivityFilter.all) {
      final typeKey = _filterToTypeKey(selectedFilter.value);
      result = result.where((a) => a.activityType == typeKey).toList();
    }

    // Full-text search
    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((a) {
        final title = a.metadata.displayTitle.toLowerCase();
        final type = a.activityType.toLowerCase();
        final resourceType = a.resourceType.toLowerCase();
        return title.contains(query) ||
            type.contains(query) ||
            resourceType.contains(query);
      }).toList();
    }

    filteredActivities.assignAll(result);
  }

  String _filterToTypeKey(ActivityFilter filter) {
    switch (filter) {
      case ActivityFilter.donation:
        return 'donation';
      case ActivityFilter.eventRegistration:
        return 'event_registration';
      case ActivityFilter.volunteerJob:
        return 'volunteer_job_enrollment';
      case ActivityFilter.all:
        return '';
    }
  }

  // -------------------------------------------------------------------------
  // Convenience getters for stats
  // -------------------------------------------------------------------------

  int get donationCount =>
      _allActivities.where((a) => a.activityType == 'donation').length;

  int get eventCount => _allActivities
      .where((a) => a.activityType == 'event_registration')
      .length;

  int get volunteerCount => _allActivities
      .where((a) => a.activityType == 'volunteer_job_enrollment')
      .length;

  double get totalDonated => _allActivities
      .where((a) => a.activityType == 'donation')
      .fold(0.0, (sum, a) => sum + (a.metadata.amount ?? 0.0));
}
