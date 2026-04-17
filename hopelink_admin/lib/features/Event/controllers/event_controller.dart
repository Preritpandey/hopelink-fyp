import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';

class EventController extends GetxController {
  static const _base = 'http://localhost:3008/api/v1';

  // ── Auth ────────────────────────────────────────────────────
  String _token = '';

  // ── Wizard state ────────────────────────────────────────────
  final wizardStep = 0.obs; // 0=Basic 1=Location 2=Details 3=Images
  final isSubmitting = false.obs;
  final isUploadingImgs = false.obs;
  final errorMsg = ''.obs;
  final successMsg = ''.obs;
  final createdEvent = Rxn<Event>();
  String _createdId = '';

  // ── Form keys ────────────────────────────────────────────────
  final formKeyStep0 = GlobalKey<FormState>();
  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();

  // ── Step 0 — Basic Info ──────────────────────────────────────
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final selectedCategory = EventCategory.education.obs;
  final selectedEventType = EventType.oneDay.obs;

  // ── Step 1 — Location ────────────────────────────────────────
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController(text: 'Bagmati');
  final lngCtrl = TextEditingController();
  final latCtrl = TextEditingController();

  // ── Step 2 — Details ────────────────────────────────────────
  final startDateCtrl = TextEditingController();
  final endDateCtrl = TextEditingController();
  final maxVolunteersCtrl = TextEditingController();
  final creditHoursCtrl = TextEditingController();
  final eligibilityCtrl = TextEditingController(text: 'Anyone');
  final skillInputCtrl = TextEditingController();
  final selectedSkills = <String>[].obs;
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Step 3 — Images ─────────────────────────────────────────
  final pickedImages = <PlatformFile>[].obs;

  // ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // ── Date pickers ─────────────────────────────────────────────
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
      _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
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
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C5CFC),
            onPrimary: Colors.white,
            surface: Color(0xFF111827),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  // ── Skill chip management ─────────────────────────────────────
  void addSkill(String skill) {
    final s = skill.trim().toLowerCase();
    if (s.isEmpty || selectedSkills.contains(s)) return;
    selectedSkills.add(s);
    skillInputCtrl.clear();
  }

  void removeSkill(String skill) => selectedSkills.remove(skill);

  void addSkillFromInput() {
    if (skillInputCtrl.text.trim().isNotEmpty) {
      addSkill(skillInputCtrl.text);
    }
  }

  // ── Navigation ───────────────────────────────────────────────
  bool validateStep(int step) {
    switch (step) {
      case 0:
        return formKeyStep0.currentState?.validate() ?? false;
      case 1:
        return formKeyStep1.currentState?.validate() ?? false;
      case 2:
        return _validateStep2();
      default:
        return true;
    }
  }

  bool _validateStep2() {
    final ok = formKeyStep2.currentState?.validate() ?? false;
    if (!ok) return false;
    if (_startDate == null) {
      errorMsg.value = 'Start date is required.';
      return false;
    }
    if (_endDate == null) {
      errorMsg.value = 'End date is required.';
      return false;
    }
    if (_endDate!.isBefore(_startDate!)) {
      errorMsg.value = 'End date must be after start date.';
      return false;
    }
    return true;
  }

  void nextStep() {
    errorMsg.value = '';
    if (!validateStep(wizardStep.value)) return;
    if (wizardStep.value < 3) wizardStep.value++;
  }

  void prevStep() {
    errorMsg.value = '';
    if (wizardStep.value > 0) wizardStep.value--;
  }

  // ── SUBMIT — Step 0-2 data ────────────────────────────────────
  Future<void> submitEvent() async {
    errorMsg.value = '';
    // Step 2 form isn't mounted on the images step, so avoid revalidating there.
    if (wizardStep.value < 3 && !validateStep(2)) return;
    isSubmitting.value = true;

    try {
      final uri = Uri.parse('$_base/events');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_token';

      // Build form fields
      final coordValue = '${lngCtrl.text.trim()},${latCtrl.text.trim()}';
      final skillsValue = selectedSkills.join(',');

      final fields = CreateEventRequest(
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        category: selectedCategory.value.value,
        eventType: selectedEventType.value.value,
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        coordinates: coordValue,
        startDate: '${startDateCtrl.text}T09:00:00.000Z',
        endDate: '${endDateCtrl.text}T17:00:00.000Z',
        maxVolunteers: int.tryParse(maxVolunteersCtrl.text) ?? 0,
        creditHours: int.tryParse(creditHoursCtrl.text) ?? 0,
        eligibility: eligibilityCtrl.text.trim(),
        requiredSkills: skillsValue,
      ).toFormFields();

      req.fields.addAll(fields);

      // Attach images if any
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

      if ((streamed.statusCode == 200 || streamed.statusCode == 201) &&
          json['success'] == true) {
        final resp = CreateEventResponse.fromJson(json);
        createdEvent.value = resp.data;
        _createdId = resp.data.id;
        wizardStep.value = 4; // success screen
        successMsg.value = 'Event created successfully!';
      } else {
        errorMsg.value =
            json['message'] as String? ?? 'Failed to create event.';
      }
    } on SocketException {
      errorMsg.value = 'No internet connection.';
    } catch (e) {
      errorMsg.value = 'Unexpected error: $e';
    }

    isSubmitting.value = false;
  }

  // ── Image picker ─────────────────────────────────────────────
  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      pickedImages.addAll(result.files);
    }
  }

  void removeImage(int i) => pickedImages.removeAt(i);

  // ── Reset ─────────────────────────────────────────────────────
  void reset() {
    wizardStep.value = 0;
    errorMsg.value = '';
    successMsg.value = '';
    createdEvent.value = null;
    _createdId = '';
    _startDate = null;
    _endDate = null;
    for (final c in [
      titleCtrl,
      descCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl,
      lngCtrl,
      latCtrl,
      startDateCtrl,
      endDateCtrl,
      maxVolunteersCtrl,
      eligibilityCtrl,
      skillInputCtrl,
    ]) {
      c.clear();
    }
    stateCtrl.text = 'Bagmati';
    eligibilityCtrl.text = 'Anyone';
    selectedSkills.clear();
    pickedImages.clear();
    selectedCategory.value = EventCategory.education;
    selectedEventType.value = EventType.oneDay;
  }

  // ── Formatters ────────────────────────────────────────────────
  String formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String formatDateTime(String iso) {
    try {
      return DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  void onClose() {
    for (final c in [
      titleCtrl,
      descCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl,
      lngCtrl,
      latCtrl,
      startDateCtrl,
      endDateCtrl,
      maxVolunteersCtrl,
      eligibilityCtrl,
      skillInputCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
