import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/organization_model.dart';

// ─────────────────────────────────────────────────────────────
class OrganizationController extends GetxController {
  // ── Step tracking (0-indexed, 4 steps total) ─────────────────
  final currentStep = 0.obs;
  static const int totalSteps = 5;

  // ── Loading / result state ────────────────────────────────────
  final isLoading = false.obs;
  final submissionResult = Rxn<OrganizationRegistrationResponse>();
  final errorMessage = ''.obs;

  // ─── FORM KEYS ────────────────────────────────────────────────
  final formKeyStep0 = GlobalKey<FormState>();
  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();
  final formKeyStep3 = GlobalKey<FormState>();
  final formKeyStep4 = GlobalKey<FormState>();

  // ─── TEXT CONTROLLERS ─────────────────────────────────────────

  // Step 0 — Organization Info
  final orgNameCtrl = TextEditingController();
  final regNumberCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: 'Nepal');
  final cityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final selectedOrgType = OrganizationType.ngo.obs;

  // Step 1 — Contact & Social
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final instagramCtrl = TextEditingController();
  final linkedinCtrl = TextEditingController();

  // Step 2 — Representative
  final repNameCtrl = TextEditingController();
  final designationCtrl = TextEditingController();

  // Step 3 — Bank Details
  final bankNameCtrl = TextEditingController();
  final accountHolderCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final bankBranchCtrl = TextEditingController();

  // Step 4 — Mission
  final primaryCauseCtrl = TextEditingController();
  final missionCtrl = TextEditingController();
  final activeMembersCtrl = TextEditingController();
  final campaignsCtrl = TextEditingController();

  // ─── FILE STATE ───────────────────────────────────────────────
  final taxCertFile = Rxn<PlatformFile>();
  final registrationCertificateFile = Rxn<PlatformFile>();
  final constitutionFile = Rxn<PlatformFile>();
  final proofOfAddressFile = Rxn<PlatformFile>();
  final voidChequeFile = Rxn<PlatformFile>();

  // ─── DATE PICKER ─────────────────────────────────────────────
  DateTime? selectedDate;

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2020),
      firstDate: DateTime(1990),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4AA),
            onPrimary: Color(0xFF0A0F1E),
            surface: Color(0xFF141929),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      selectedDate = picked;
      dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ─── FILE PICKER HELPERS ──────────────────────────────────────
  Future<void> pickFile(String type) async {
    final allowedExtensions = _allowedExtensions(type);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    switch (type) {
      case 'registrationCertificate':
        registrationCertificateFile.value = file;
        break;
      case 'taxCertificate':
        taxCertFile.value = file;
        break;
      case 'constitutionFile':
        constitutionFile.value = file;
        break;
      case 'proofOfAddress':
        proofOfAddressFile.value = file;
        break;
      case 'voidCheque':
        voidChequeFile.value = file;
        break;
    }
  }

  List<String> _allowedExtensions(String type) {
    if (type == 'registrationCertificate' ||
        type == 'taxCertificate' ||
        type == 'constitutionFile') {
      return ['pdf'];
    }
    return ['jpg', 'jpeg', 'png'];
  }

  String _fileLabel(String type) {
    switch (type) {
      case 'registrationCertificate':
        return 'Registration Certificate (PDF)';
      case 'taxCertificate':
        return 'Tax Certificate (PDF)';
      case 'constitutionFile':
        return 'Constitution File (PDF)';
      case 'proofOfAddress':
        return 'Proof of Address (JPG/PNG)';
      case 'voidCheque':
        return 'Void Cheque (JPG/PNG)';
      default:
        return type;
    }
  }

  PlatformFile? fileFor(String type) {
    switch (type) {
      case 'registrationCertificate':
        return registrationCertificateFile.value;
      case 'taxCertificate':
        return taxCertFile.value;
      case 'constitutionFile':
        return constitutionFile.value;
      case 'proofOfAddress':
        return proofOfAddressFile.value;
      case 'voidCheque':
        return voidChequeFile.value;
      default:
        return null;
    }
  }

  // ─── NAVIGATION ───────────────────────────────────────────────
  void nextStep() {
    final valid = _validateCurrentStep();
    if (!valid) return;
    if (currentStep.value < totalSteps - 1) currentStep.value++;
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return formKeyStep0.currentState?.validate() ?? false;
      case 1:
        return formKeyStep1.currentState?.validate() ?? false;
      case 2:
        return formKeyStep2.currentState?.validate() ?? false;
      case 3:
        return formKeyStep3.currentState?.validate() ?? false;
      case 4:
        return _validateFiles();
      default:
        return true;
    }
  }

  bool _validateFiles() {
    if (registrationCertificateFile.value == null ||
        taxCertFile.value == null ||
        constitutionFile.value == null ||
        proofOfAddressFile.value == null ||
        voidChequeFile.value == null) {
      errorMessage.value = 'Please upload all required documents.';
      return false;
    }
    errorMessage.value = '';
    return true;
  }

  // ─── SUBMIT ───────────────────────────────────────────────────
  Future<void> submit() async {
    if (!_validateFiles()) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uri = Uri.parse(
        'http://localhost:3008/api/v1/organizations/register',
      );
      final request = http.MultipartRequest('POST', uri);

      // Text fields
      request.fields.addAll({
        'organizationName': orgNameCtrl.text.trim(),
        'organizationType': selectedOrgType.value.label,
        'registrationNumber': regNumberCtrl.text.trim(),
        'dateOfRegistration': dateCtrl.text.trim(),
        'country': countryCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'registeredAddress': addressCtrl.text.trim(),
        'officialEmail': emailCtrl.text.trim(),
        'officialPhone': phoneCtrl.text.trim(),
        'website': websiteCtrl.text.trim(),
        'facebook': facebookCtrl.text.trim(),
        'instagram': instagramCtrl.text.trim(),
        'linkedin': linkedinCtrl.text.trim(),
        'representativeName': repNameCtrl.text.trim(),
        'designation': designationCtrl.text.trim(),
        'bankName': bankNameCtrl.text.trim(),
        'accountHolderName': accountHolderCtrl.text.trim(),
        'accountNumber': accountNumberCtrl.text.trim(),
        'bankBranch': bankBranchCtrl.text.trim(),
        'primaryCause': primaryCauseCtrl.text.trim(),
        'missionStatement': missionCtrl.text.trim(),
        'activeMembers': activeMembersCtrl.text.trim(),
        'recentCampaigns': campaignsCtrl.text.trim(),
      });

      // File fields
      await _attachFile(
          request, 'registrationCertificate', registrationCertificateFile.value!);
      await _attachFile(request, 'taxCertificate', taxCertFile.value!);
      await _attachFile(request, 'constitutionFile', constitutionFile.value!);
      await _attachFile(request, 'proofOfAddress', proofOfAddressFile.value!);
      await _attachFile(request, 'voidCheque', voidChequeFile.value!);

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        submissionResult.value = OrganizationRegistrationResponse.fromJson(
          json,
        );
        currentStep.value = totalSteps; // success screen
      } else {
        errorMessage.value =
            json['message'] as String? ?? 'Registration failed.';
      }
    } on SocketException {
      errorMessage.value = 'No internet connection. Please check your network.';
    } catch (e) {
      errorMessage.value = 'Unexpected error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _attachFile(
    http.MultipartRequest request,
    String field,
    PlatformFile pf,
  ) async {
    final ext = p.extension(pf.name).replaceFirst('.', '').toLowerCase();
    final mime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
    request.files.add(
      await http.MultipartFile.fromPath(
        field,
        pf.path!,
        contentType: MediaType.parse(mime),
      ),
    );
  }

  // ─── RESET ────────────────────────────────────────────────────
  void reset() {
    currentStep.value = 0;
    submissionResult.value = null;
    errorMessage.value = '';
    for (final c in [
      orgNameCtrl,
      regNumberCtrl,
      dateCtrl,
      countryCtrl,
      cityCtrl,
      addressCtrl,
      emailCtrl,
      phoneCtrl,
      websiteCtrl,
      facebookCtrl,
      instagramCtrl,
      linkedinCtrl,
      repNameCtrl,
      designationCtrl,
      bankNameCtrl,
      accountHolderCtrl,
      accountNumberCtrl,
      bankBranchCtrl,
      primaryCauseCtrl,
      missionCtrl,
      activeMembersCtrl,
      campaignsCtrl,
    ]) {
      c.clear();
    }
    countryCtrl.text = 'Nepal';
    selectedDate = null;
    taxCertFile.value = null;
    registrationCertificateFile.value = null;
    constitutionFile.value = null;
    proofOfAddressFile.value = null;
    voidChequeFile.value = null;
    selectedOrgType.value = OrganizationType.ngo;
  }

  @override
  void onClose() {
    for (final c in [
      orgNameCtrl,
      regNumberCtrl,
      dateCtrl,
      countryCtrl,
      cityCtrl,
      addressCtrl,
      emailCtrl,
      phoneCtrl,
      websiteCtrl,
      facebookCtrl,
      instagramCtrl,
      linkedinCtrl,
      repNameCtrl,
      designationCtrl,
      bankNameCtrl,
      accountHolderCtrl,
      accountNumberCtrl,
      bankBranchCtrl,
      primaryCauseCtrl,
      missionCtrl,
      activeMembersCtrl,
      campaignsCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  // ── Step metadata ─────────────────────────────────────────────
  static const stepTitles = [
    'Organization Info',
    'Contact & Social',
    'Representative',
    'Bank Details',
    'Documents',
  ];

  static const stepIcons = [
    Icons.business_rounded,
    Icons.language_rounded,
    Icons.person_rounded,
    Icons.account_balance_rounded,
    Icons.folder_rounded,
  ];
}
