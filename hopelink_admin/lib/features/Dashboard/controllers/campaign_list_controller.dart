// ─────────────────────────────────────────────────────────────
//  CONTROLLER  —  campaign_list_controller.dart
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign_list_model.dart';


class CampaignListController extends GetxController {
  static const _base     = 'http://localhost:3008/api/v1';
  static const _tokenKey = 'auth_token';

  // ── State ────────────────────────────────────────────────────
  final allCampaigns     = <CampaignListItem>[].obs;
  final isLoading        = false.obs;
  final errorMsg         = ''.obs;
  final searchQuery      = ''.obs;
  final activeFilter     = CampaignStatusFilter.all.obs;
  final sortOption       = CampaignSortOption.newest.obs;
  final viewMode         = CampaignViewMode.grid.obs;
  final selectedCampaign = Rxn<CampaignListItem>();
  final expandedFaqIndex = (-1).obs;

  // ── Controllers ───────────────────────────────────────────────
  final searchCtrl = TextEditingController();
  String _token    = '';

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
    await fetchCampaigns();
  }

  // ── Fetch ─────────────────────────────────────────────────────
  Future<void> fetchCampaigns() async {
    isLoading.value = true;
    errorMsg.value  = '';

    try {
      final uri = Uri.parse('$_base/campaigns/');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type':  'application/json',
      }).timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && json['success'] == true) {
        final resp = CampaignListResponse.fromJson(json);
        allCampaigns.assignAll(resp.data);
      } else {
        errorMsg.value =
            json['message'] as String? ?? 'Failed to load campaigns.';
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

  @override
  Future<void> refresh() => fetchCampaigns();

  // ── Derived list ──────────────────────────────────────────────
  List<CampaignListItem> get filtered {
    var list = allCampaigns.toList();

    // Filter
    if (activeFilter.value != CampaignStatusFilter.all) {
      list = list.where((c) => c.status == activeFilter.value.value).toList();
    }

    // Search
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.organization?.organizationName.toLowerCase().contains(q) ??
                false);
      }).toList();
    }

    // Sort
    switch (sortOption.value) {
      case CampaignSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CampaignSortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CampaignSortOption.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case CampaignSortOption.target:
        list.sort((a, b) => b.targetAmount.compareTo(a.targetAmount));
        break;
    }

    return list;
  }

  // ── Stats ─────────────────────────────────────────────────────
  int get activeCount =>
      allCampaigns.where((c) => c.status == 'active').length;

  double get totalRaised =>
      allCampaigns.fold(0.0, (sum, c) => sum + c.currentAmount);

  double get totalTarget =>
      allCampaigns.fold(0.0, (sum, c) => sum + c.targetAmount);

  double get overallProgress =>
      totalTarget > 0 ? (totalRaised / totalTarget * 100).clamp(0, 100) : 0;

  int get withImagesCount =>
      allCampaigns.where((c) => c.hasImages).length;

  int get totalUpdates =>
      allCampaigns.fold(0, (sum, c) => sum + c.updates.length);

  // ── Interactions ─────────────────────────────────────────────
  void setFilter(CampaignStatusFilter f) {
    activeFilter.value = f;
    selectedCampaign.value = null;
  }

  void setSort(CampaignSortOption s) => sortOption.value = s;

  void toggleView() {
    viewMode.value = viewMode.value == CampaignViewMode.grid
        ? CampaignViewMode.list
        : CampaignViewMode.grid;
  }

  void openDetail(CampaignListItem c) {
    expandedFaqIndex.value = -1;
    selectedCampaign.value = c;
  }

  void closeDetail() => selectedCampaign.value = null;

  void toggleFaq(int index) {
    expandedFaqIndex.value =
        expandedFaqIndex.value == index ? -1 : index;
  }

  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
  }

  // ── Formatters ────────────────────────────────────────────────
  String formatCurrency(double amount) {
    final fmt = NumberFormat.compact(locale: 'en');
    return 'NPR ${fmt.format(amount)}';
  }

  String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
  String formatShort(DateTime dt) => DateFormat('MMM dd').format(dt);

  String daysLeftLabel(CampaignListItem c) {
    final d = c.daysLeft;
    if (c.isExpired) return 'Ended';
    if (d == 0) return 'Ends today';
    if (d == 1) return '1 day left';
    return '$d days left';
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
