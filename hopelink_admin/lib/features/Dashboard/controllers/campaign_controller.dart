import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign_model.dart';
import 'campaign_list_controller.dart';

class CampaignController extends GetxController {
  static const _base = 'http://localhost:3008/api/v1';

  // ── Auth ────────────────────────────────────────────────────
  String _token = '';
  final _orgName = ''.obs;
  final _userName = ''.obs;

  // ── State ───────────────────────────────────────────────────
  final campaigns = <Campaign>[].obs;
  final selectedCampaign = Rxn<Campaign>();
  final categories = <CampaignCategory>[].obs;
  final isLoadingList = false.obs;
  final isSubmitting = false.obs;
  final errorMsg = ''.obs;
  final successMsg = ''.obs;
  final currentNavIndex = 0.obs; // 0=Dashboard 1=Campaigns 2=Create

  // ── Wizard state ────────────────────────────────────────────
  final wizardStep = 0.obs; // 0=Info 1=Images 2=Updates 3=FAQs
  String _createdCampaignId = '';

  // ── Create form ─────────────────────────────────────────────
  final createFormKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final startDateCtrl = TextEditingController();
  final endDateCtrl = TextEditingController();
  final selectedCategory = ''.obs;
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Image upload ─────────────────────────────────────────────
  final pickedImages = <PlatformFile>[].obs;
  final isUploadingImages = false.obs;

  // ── Update form ─────────────────────────────────────────────
  final updateFormKey = GlobalKey<FormState>();
  final updateTitleCtrl = TextEditingController();
  final updateDescCtrl = TextEditingController();
  final isPostingUpdate = false.obs;

  // ── FAQ form ─────────────────────────────────────────────────
  final faqFormKey = GlobalKey<FormState>();
  final faqQuestionCtrl = TextEditingController();
  final faqAnswerCtrl = TextEditingController();
  final isPostingFaq = false.obs;

  // ── Getters ──────────────────────────────────────────────────
  String get orgName => _orgName.value;
  String get userName => _userName.value;
  DashboardStats get stats => DashboardStats.fromCampaigns(campaigns);

  // ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    _orgName.value = prefs.getString('org_name') ?? 'Your Organization';
    _userName.value = prefs.getString('user_name') ?? 'Admin';
    await fetchCampaigns();
    await fetchCategories();
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // ─── FETCH campaigns ─────────────────────────────────────────
  Future<void> fetchCampaigns() async {
    isLoadingList.value = true;
    try {
      final res = await http
          .get(
            Uri.parse('$_base/campaigns/organization'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final list = (json['data'] as List)
            .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
            .toList();
        campaigns.assignAll(list);
      }
    } catch (_) {}
    isLoadingList.value = false;
  }

  // ─── FETCH categories ─────────────────────────────────────────
  Future<void> fetchCategories() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/categories'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final list = (json['data'] as List)
            .map((e) => CampaignCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        categories.assignAll(list);
      }
    } catch (_) {
      // If categories API unavailable, use fallback
      categories.assignAll([
        const CampaignCategory(id: '69533b891456cdbcd16177ad', name: 'Health'),
        const CampaignCategory(
          id: '69533b891456cdbcd16177ae',
          name: 'Education',
        ),
        const CampaignCategory(
          id: '69533b891456cdbcd16177af',
          name: 'Environment',
        ),
        const CampaignCategory(
          id: '69533b891456cdbcd16177b0',
          name: 'Disaster Relief',
        ),
        const CampaignCategory(
          id: '69533b891456cdbcd16177b1',
          name: 'Women Empowerment',
        ),
      ]);
    }
  }

  // ─── Date pickers ─────────────────────────────────────────────
  Future<void> pickStartDate(BuildContext ctx) async {
    final picked = await _showPicker(ctx, _startDate ?? DateTime.now());
    if (picked != null) {
      _startDate = picked;
      startDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> pickEndDate(BuildContext ctx) async {
    final picked = await _showPicker(
      ctx,
      _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
    );
    if (picked != null) {
      _endDate = picked;
      endDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<DateTime?> _showPicker(BuildContext ctx, DateTime initial) {
    return showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00C896),
            onPrimary: Colors.black,
            surface: Color(0xFF111E35),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ─── STEP 1 — Create campaign ─────────────────────────────────
  Future<void> createCampaign() async {
    if (!(createFormKey.currentState?.validate() ?? false)) return;
    if (selectedCategory.value.isEmpty) {
      errorMsg.value = 'Please select a category.';
      return;
    }
    isSubmitting.value = true;
    errorMsg.value = '';
    try {
      final body = CreateCampaignRequest(
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        category: selectedCategory.value,
        startDate: '${startDateCtrl.text}T00:00:00.000Z',
        endDate: '${endDateCtrl.text}T00:00:00.000Z',
        targetAmount: double.parse(targetCtrl.text.replaceAll(',', '')),
      );
      final res = await http
          .post(
            Uri.parse('$_base/campaigns'),
            headers: _authHeaders,
            body: jsonEncode(body.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        final created = Campaign.fromJson(json['data'] as Map<String, dynamic>);
        _createdCampaignId = created.id;
        selectedCampaign.value = created;
        campaigns.insert(0, created);
        wizardStep.value = 1; // move to images step
        successMsg.value = 'Campaign created! Now add images.';
      } else {
        errorMsg.value =
            json['message'] as String? ?? 'Failed to create campaign.';
      }
    } on SocketException {
      errorMsg.value = 'No internet connection.';
    } catch (e) {
      errorMsg.value = 'Error: $e';
    }
    isSubmitting.value = false;
  }

  // ─── STEP 2 — Upload images ───────────────────────────────────
  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withReadStream: false,
    );
    if (result != null) {
      pickedImages.addAll(result.files);
    }
  }

  void removeImage(int index) {
    pickedImages.removeAt(index);
  }

  Future<void> uploadImages() async {
    if (pickedImages.isEmpty) {
      wizardStep.value = 2;
      return;
    }
    if (_createdCampaignId.isEmpty) return;
    isUploadingImages.value = true;
    errorMsg.value = '';
    try {
      final uri = Uri.parse('$_base/campaigns/$_createdCampaignId/images');
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
        successMsg.value = 'Images uploaded!';
        wizardStep.value = 2;
      } else {
        errorMsg.value = json['message'] as String? ?? 'Image upload failed.';
      }
    } catch (e) {
      errorMsg.value = 'Upload error: $e';
    }
    isUploadingImages.value = false;
  }

  // ─── STEP 3 — Post update ─────────────────────────────────────
  Future<void> postUpdate() async {
    if (!(updateFormKey.currentState?.validate() ?? false)) return;
    isPostingUpdate.value = true;
    errorMsg.value = '';
    try {
      final res = await http
          .post(
            Uri.parse('$_base/campaigns/$_createdCampaignId/updates'),
            headers: _authHeaders,
            body: jsonEncode({
              'title': updateTitleCtrl.text.trim(),
              'description': updateDescCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        successMsg.value = 'Update posted!';
        updateTitleCtrl.clear();
        updateDescCtrl.clear();
      } else {
        errorMsg.value = json['message'] as String? ?? 'Failed to post update.';
      }
    } catch (e) {
      errorMsg.value = 'Error: $e';
    }
    isPostingUpdate.value = false;
  }

  void skipToFaqs() => wizardStep.value = 3;

  // ─── STEP 4 — Post FAQ ────────────────────────────────────────
  Future<void> postFaq() async {
    if (!(faqFormKey.currentState?.validate() ?? false)) return;
    isPostingFaq.value = true;
    errorMsg.value = '';
    try {
      final res = await http
          .post(
            Uri.parse('$_base/campaigns/$_createdCampaignId/faqs'),
            headers: _authHeaders,
            body: jsonEncode({
              'question': faqQuestionCtrl.text.trim(),
              'answer': faqAnswerCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        successMsg.value = 'FAQ added!';
        faqQuestionCtrl.clear();
        faqAnswerCtrl.clear();
      } else {
        errorMsg.value = json['message'] as String? ?? 'Failed to add FAQ.';
      }
    } catch (e) {
      errorMsg.value = 'Error: $e';
    }
    isPostingFaq.value = false;
  }

  void finishWizard() {
    fetchCampaigns();
    resetCreateForm();
    currentNavIndex.value = 1; // go to campaigns list
    _showSnack('Campaign posted successfully.', isError: false);
    _refreshCampaignListSoon();
  }

  // ─── Reset ────────────────────────────────────────────────────
  void resetCreateForm() {
    wizardStep.value = 0;
    _createdCampaignId = '';
    titleCtrl.clear();
    descCtrl.clear();
    targetCtrl.clear();
    startDateCtrl.clear();
    endDateCtrl.clear();
    selectedCategory.value = '';
    pickedImages.clear();
    updateTitleCtrl.clear();
    updateDescCtrl.clear();
    faqQuestionCtrl.clear();
    faqAnswerCtrl.clear();
    errorMsg.value = '';
    successMsg.value = '';
    _startDate = null;
    _endDate = null;
  }

  void _refreshCampaignListSoon() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (Get.isRegistered<CampaignListController>()) {
        Get.find<CampaignListController>().refresh();
      }
    });
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

  void navigateTo(int index) {
    if (index == 2) resetCreateForm();
    currentNavIndex.value = index;
  }

  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'NPR ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'NPR ${(amount / 1000).toStringAsFixed(0)}K';
    return 'NPR ${amount.toStringAsFixed(0)}';
  }

  String formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  void onClose() {
    for (final c in [
      titleCtrl,
      descCtrl,
      targetCtrl,
      startDateCtrl,
      endDateCtrl,
      updateTitleCtrl,
      updateDescCtrl,
      faqQuestionCtrl,
      faqAnswerCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
