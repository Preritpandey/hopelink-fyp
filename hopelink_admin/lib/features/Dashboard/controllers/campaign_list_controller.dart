// ─────────────────────────────────────────────────────────────
//  CONTROLLER  —  campaign_list_controller.dart
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
  final actionLoading    = false.obs;

  // Images upload
  final pickedImages     = <PlatformFile>[].obs;
  final isUploadingImages = false.obs;

  // Donations
  final donations        = <CampaignDonation>[].obs;
  final donationsLoading = false.obs;
  final donationsError   = ''.obs;
  final donationsNextPage = RxnInt();
  String _donationsForId = '';

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

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // ── Fetch ─────────────────────────────────────────────────────
  Future<void> fetchCampaigns() async {
    isLoading.value = true;
    errorMsg.value  = '';

    try {
      final uri = Uri.parse('$_base/campaigns/organization');
      final res = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));

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
    fetchDonations(c.id);
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

  // â”€â”€ Update Campaign â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> updateCampaign(
    String campaignId,
    UpdateCampaignRequest req,
  ) async {
    if (req.isEmpty) {
      _showSnack('No changes to update.');
      return false;
    }
    actionLoading.value = true;
    try {
      final res = await http
          .put(
            Uri.parse('$_base/campaigns/$campaignId'),
            headers: _authHeaders,
            body: jsonEncode(req.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final updated = CampaignListItem.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        _replaceCampaign(updated);
        _showSnack('Campaign updated.', isError: false);
        return true;
      }
      _showSnack(json['message'] as String? ?? 'Update failed.');
    } on SocketException {
      _showSnack('No internet connection.');
    } on TimeoutException {
      _showSnack('Request timed out. Please retry.');
    } catch (e) {
      _showSnack('Error: $e');
    }
    actionLoading.value = false;
    return false;
  }

  Future<bool> updateCampaignStatus(
    String campaignId,
    String status,
  ) {
    return updateCampaign(
      campaignId,
      UpdateCampaignRequest(status: status),
    );
  }

  // â”€â”€ Campaign Updates â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> addCampaignUpdate(
    String campaignId,
    String title,
    String description,
  ) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _showSnack('Title and description are required.');
      return false;
    }
    actionLoading.value = true;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/campaigns/$campaignId/updates'),
            headers: _authHeaders,
            body: jsonEncode({
              'title': title.trim(),
              'description': description.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        final upd = CampaignListUpdate.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        _appendUpdate(campaignId, upd);
        _showSnack('Update added.', isError: false);
        return true;
      }
      _showSnack(json['message'] as String? ?? 'Failed to add update.');
    } catch (e) {
      _showSnack('Error: $e');
    }
    actionLoading.value = false;
    return false;
  }

  // â”€â”€ Campaign FAQ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> addCampaignFaq(
    String campaignId,
    String question,
    String answer,
  ) async {
    if (question.trim().isEmpty || answer.trim().isEmpty) {
      _showSnack('Question and answer are required.');
      return false;
    }
    actionLoading.value = true;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/campaigns/$campaignId/faqs'),
            headers: _authHeaders,
            body: jsonEncode({
              'question': question.trim(),
              'answer': answer.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        final faq = CampaignListFaq.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        _appendFaq(campaignId, faq);
        _showSnack('FAQ added.', isError: false);
        return true;
      }
      _showSnack(json['message'] as String? ?? 'Failed to add FAQ.');
    } catch (e) {
      _showSnack('Error: $e');
    }
    actionLoading.value = false;
    return false;
  }

  // â”€â”€ Image Upload â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withReadStream: false,
    );
    if (result != null) {
      pickedImages.assignAll(result.files);
    }
  }

  void clearPickedImages() => pickedImages.clear();

  Future<bool> uploadCampaignImages(String campaignId) async {
    if (pickedImages.isEmpty) {
      _showSnack('Please choose images to upload.');
      return false;
    }
    isUploadingImages.value = true;
    try {
      final uri = Uri.parse('$_base/campaigns/$campaignId/images');
      final req = http.MultipartRequest('PUT', uri)
        ..headers['Authorization'] = 'Bearer $_token';
      for (final f in pickedImages) {
        final ext = f.name.split('.').last.toLowerCase();
        req.files.add(
          await http.MultipartFile.fromPath(
            'images',
            f.path!,
            contentType: MediaType.parse('image/$ext'),
          ),
        );
      }
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final urls = (json['data'] as List? ?? [])
            .map((e) => (e as Map<String, dynamic>)['url'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        _appendImages(campaignId, urls);
        clearPickedImages();
        _showSnack('Images uploaded.', isError: false);
        isUploadingImages.value = false;
        return true;
      }
      _showSnack(json['message'] as String? ?? 'Image upload failed.');
    } catch (e) {
      _showSnack('Upload error: $e');
    }
    isUploadingImages.value = false;
    return false;
  }

  // â”€â”€ Donations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchDonations(
    String campaignId, {
    int page = 1,
    int limit = 10,
  }) async {
    if (page == 1) {
      donations.clear();
      donationsNextPage.value = null;
      donationsError.value = '';
      _donationsForId = campaignId;
    }
    donationsLoading.value = true;
    try {
      final uri = Uri.parse(
        '$_base/campaigns/$campaignId/donations?page=$page&limit=$limit&sort=-createdAt',
      );
      final res = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final items = (json['data'] as List? ?? [])
            .map((e) => CampaignDonation.fromJson(e as Map<String, dynamic>))
            .toList();
        donations.addAll(items);
        final next = json['pagination']?['next']?['page'] as int?;
        donationsNextPage.value = next;
      } else {
        donationsError.value =
            json['message'] as String? ?? 'Failed to load donations.';
      }
    } catch (e) {
      donationsError.value = 'Error: $e';
    }
    donationsLoading.value = false;
  }

  Future<void> loadMoreDonations() async {
    final next = donationsNextPage.value;
    if (next == null || _donationsForId.isEmpty) return;
    await fetchDonations(_donationsForId, page: next);
  }

  // ── Formatters ────────────────────────────────────────────────
  String formatCurrency(double amount) {
    final fmt = NumberFormat.compact(locale: 'en');
    return 'NPR ${fmt.format(amount)}';
  }

  String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
  String formatShort(DateTime dt) => DateFormat('MMM dd').format(dt);
  String formatDateTime(DateTime dt) =>
      DateFormat('MMM dd, yyyy · h:mm a').format(dt);

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

  void _replaceCampaign(CampaignListItem updated) {
    final idx = allCampaigns.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      allCampaigns[idx] = updated;
    }
    if (selectedCampaign.value?.id == updated.id) {
      selectedCampaign.value = updated;
    }
    actionLoading.value = false;
  }

  void _appendUpdate(String campaignId, CampaignListUpdate update) {
    final current = _getCampaign(campaignId);
    if (current == null) return;
    final next = current.copyWith(
      updates: [update, ...current.updates],
    );
    _replaceCampaign(next);
  }

  void _appendFaq(String campaignId, CampaignListFaq faq) {
    final current = _getCampaign(campaignId);
    if (current == null) return;
    final next = current.copyWith(
      faqs: [faq, ...current.faqs],
    );
    _replaceCampaign(next);
  }

  void _appendImages(String campaignId, List<String> urls) {
    final current = _getCampaign(campaignId);
    if (current == null) return;
    final next = current.copyWith(
      images: [...urls, ...current.images],
    );
    _replaceCampaign(next);
  }

  CampaignListItem? _getCampaign(String id) {
    if (selectedCampaign.value?.id == id) {
      return selectedCampaign.value;
    }
    final idx = allCampaigns.indexWhere((c) => c.id == id);
    if (idx == -1) return null;
    return allCampaigns[idx];
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
