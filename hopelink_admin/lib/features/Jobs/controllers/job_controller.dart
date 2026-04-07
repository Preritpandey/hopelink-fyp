// ─────────────────────────────────────────────────────────────
//  CONTROLLER  —  job_controller.dart
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_model.dart';


// ── View mode for the jobs panel ─────────────────────────────
enum JobPanelView { list, create, applications }

class JobController extends GetxController {
  static const _base     = 'http://localhost:3008/api/v1';
  static const _tokenKey = 'auth_token';

  // ── Auth ────────────────────────────────────────────────────
  String _token = '';

  // ── Panel navigation ────────────────────────────────────────
  final panelView     = JobPanelView.list.obs;
  final selectedJob   = Rxn<VolunteerJob>();

  // ── Jobs state ───────────────────────────────────────────────
  final jobs           = <VolunteerJob>[].obs;
  final isLoadingJobs  = false.obs;
  final jobsError      = ''.obs;
  final jobSearchQuery = ''.obs;
  final jobFilter      = 'all'.obs; // 'all','open','closed','paused'

  // ── Applications state ───────────────────────────────────────
  final applications         = <JobApplication>[].obs;
  final isLoadingApplications = false.obs;
  final appsError            = ''.obs;
  final selectedApplication  = Rxn<JobApplication>();
  final appActionLoading     = ''.obs; // applicationId being actioned

  // ── Create job form state ────────────────────────────────────
  final createFormKey          = GlobalKey<FormState>();
  final titleCtrl              = TextEditingController();
  final descCtrl               = TextEditingController();
  final selectedCategory       = 'Technology'.obs;
  final addressCtrl            = TextEditingController();
  final cityCtrl               = TextEditingController();
  final stateCtrl              = TextEditingController(text: 'Bagmati');
  final latCtrl                = TextEditingController();
  final lngCtrl                = TextEditingController();
  final positionsCtrl          = TextEditingController(text: '1');
  final deadlineCtrl           = TextEditingController();
  final selectedJobType        = JobType.onsite.obs;
  final certificateProvided    = false.obs;
  final creditHoursCtrl        = TextEditingController(text: '10');
  final skillInputCtrl         = TextEditingController();
  final selectedSkills         = <String>[].obs;
  final isCreatingJob          = false.obs;
  final createError            = ''.obs;
  final createSuccess          = ''.obs;
  DateTime? _deadlineDate;

  // ── Search controller ────────────────────────────────────────
  final searchCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _init();
    searchCtrl.addListener(() => jobSearchQuery.value = searchCtrl.text);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    await fetchJobs();
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type':  'application/json',
      };

  // ─────────────────────────────────────────────────────────────
  //  JOBS
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchJobs() async {
    isLoadingJobs.value = true;
    jobsError.value = '';
    try {
      final res = await http
          .get(Uri.parse('$_base/volunteer-jobs/org/my'),
              headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final resp = VolunteerJobsResponse.fromJson(json);
        jobs.assignAll(resp.data);
      } else {
        jobsError.value =
            json['message'] as String? ?? 'Failed to load jobs.';
      }
    } on SocketException {
      jobsError.value = 'No internet connection.';
    } catch (e) {
      jobsError.value = 'Error: $e';
    }
    isLoadingJobs.value = false;
  }

  List<VolunteerJob> get filteredJobs {
    var list = jobs.toList();
    if (jobFilter.value != 'all') {
      list = list.where((j) => j.status.value == jobFilter.value).toList();
    }
    final q = jobSearchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((j) =>
          j.title.toLowerCase().contains(q) ||
          j.category.toLowerCase().contains(q) ||
          j.location.city.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Create Job ────────────────────────────────────────────────
  Future<void> createJob() async {
    if (!(createFormKey.currentState?.validate() ?? false)) return;
    if (selectedSkills.isEmpty) {
      createError.value = 'Please add at least one required skill.';
      return;
    }
    if (_deadlineDate == null) {
      createError.value = 'Please pick an application deadline.';
      return;
    }
    isCreatingJob.value = true;
    createError.value   = '';
    createSuccess.value = '';
    try {
      final body = CreateJobRequest(
        title:               titleCtrl.text.trim(),
        description:         descCtrl.text.trim(),
        category:            selectedCategory.value,
        requiredSkills:      selectedSkills.join(','),
        address:             addressCtrl.text.trim(),
        city:                cityCtrl.text.trim(),
        state:               stateCtrl.text.trim(),
        coordinates:         '${latCtrl.text.trim()},${lngCtrl.text.trim()}',
        positionsAvailable:  int.tryParse(positionsCtrl.text) ?? 1,
        applicationDeadline: _deadlineDate!.toIso8601String(),
        jobType:             selectedJobType.value.value,
        certificateProvided: certificateProvided.value,
        creditHours:         int.tryParse(creditHoursCtrl.text) ?? 0,
      );

      final res = await http
          .post(Uri.parse('$_base/volunteer-jobs'),
              headers: _authHeaders,
              body: jsonEncode(body.toJson()))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          json['success'] == true) {
        createSuccess.value = 'Job posted successfully!';
        final newJob = VolunteerJob.fromJson(
            json['data'] as Map<String, dynamic>);
        jobs.insert(0, newJob);
        await Future.delayed(const Duration(seconds: 1));
        _resetCreateForm();
        panelView.value = JobPanelView.list;
      } else {
        createError.value =
            json['message'] as String? ?? 'Failed to post job.';
      }
    } on SocketException {
      createError.value = 'No internet connection.';
    } catch (e) {
      createError.value = 'Error: $e';
    }
    isCreatingJob.value = false;
  }

  // ── Date picker ───────────────────────────────────────────────
  Future<void> pickDeadline(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _deadlineDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   Color(0xFF34D399),
            onPrimary: Colors.black,
            surface:   Color(0xFF0D1A2A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _deadlineDate = picked;
      deadlineCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ── Skills ───────────────────────────────────────────────────
  void addSkill(String s) {
    final clean = s.trim().toLowerCase();
    if (clean.isEmpty || selectedSkills.contains(clean)) return;
    selectedSkills.add(clean);
    skillInputCtrl.clear();
  }

  void removeSkill(String s) => selectedSkills.remove(s);

  // ─────────────────────────────────────────────────────────────
  //  APPLICATIONS
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchApplications(String jobId) async {
    isLoadingApplications.value = true;
    appsError.value = '';
    applications.clear();
    selectedApplication.value = null;
    try {
      final res = await http
          .get(Uri.parse('$_base/volunteer-applications/job/$jobId'),
              headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final resp = JobApplicationsResponse.fromJson(json);
        applications.assignAll(resp.data);
      } else {
        appsError.value =
            json['message'] as String? ?? 'Failed to load applications.';
      }
    } catch (e) {
      appsError.value = 'Error: $e';
    }
    isLoadingApplications.value = false;
  }

  // ── Approve ───────────────────────────────────────────────────
  Future<void> approveApplication(String applicationId) async {
    appActionLoading.value = applicationId;
    try {
      final res = await http
          .patch(
              Uri.parse(
                  '$_base/volunteer-applications/$applicationId/approve'),
              headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _updateApplicationStatus(applicationId, ApplicationStatus.approved);
        _showSnack('Application approved ✓', isError: false);
      } else {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _showSnack(j['message'] as String? ?? 'Approval failed.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
    appActionLoading.value = '';
  }

  // ── Reject ────────────────────────────────────────────────────
  Future<void> rejectApplication(String applicationId) async {
    appActionLoading.value = applicationId;
    try {
      final res = await http
          .patch(
              Uri.parse(
                  '$_base/volunteer-applications/$applicationId/reject'),
              headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _updateApplicationStatus(applicationId, ApplicationStatus.rejected);
        _showSnack('Application rejected', isError: false);
      } else {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _showSnack(j['message'] as String? ?? 'Rejection failed.');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
    appActionLoading.value = '';
  }

  void _updateApplicationStatus(String id, ApplicationStatus status) {
    final idx = applications.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final old = applications[idx];
    final updated = JobApplication(
      id: old.id,
      jobId: old.jobId,
      organizationId: old.organizationId,
      userId: old.userId,
      status: status,
      resumePath: old.resumePath,
      resumeOriginalName: old.resumeOriginalName,
      whyHire: old.whyHire,
      skills: old.skills,
      experience: old.experience,
      applicantSnapshot: old.applicantSnapshot,
      creditHoursGranted: old.creditHoursGranted,
      createdAt: old.createdAt,
      updatedAt: old.updatedAt,
    );
    applications[idx] = updated;
    if (selectedApplication.value?.id == id) {
      selectedApplication.value = updated;
    }
  }

  // ── Navigation ────────────────────────────────────────────────
  void openJobApplications(VolunteerJob job) {
    selectedJob.value = job;
    panelView.value   = JobPanelView.applications;
    fetchApplications(job.id);
  }

  void openCreate() {
    _resetCreateForm();
    panelView.value = JobPanelView.create;
  }

  void backToList() {
    panelView.value       = JobPanelView.list;
    selectedJob.value     = null;
    selectedApplication.value = null;
  }

  // ── Stats ─────────────────────────────────────────────────────
  int get openJobsCount   => jobs.where((j) => j.status == JobStatus.open).length;
  int get totalPositions  => jobs.fold(0, (s, j) => s + j.positionsAvailable);
  int get filledPositions => jobs.fold(0, (s, j) => s + j.positionsFilled);

  int get pendingCount    =>
      applications.where((a) => a.status == ApplicationStatus.pending).length;
  int get approvedCount   =>
      applications.where((a) => a.status == ApplicationStatus.approved).length;

  // ── Helpers ───────────────────────────────────────────────────
  String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
  String formatDateTime(DateTime dt) =>
      DateFormat('MMM dd, yyyy · h:mm a').format(dt);

  void _showSnack(String msg, {bool isError = true}) {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  void _resetCreateForm() {
    titleCtrl.clear();
    descCtrl.clear();
    addressCtrl.clear();
    cityCtrl.clear();
    stateCtrl.text = 'Bagmati';
    latCtrl.clear();
    lngCtrl.clear();
    positionsCtrl.text = '1';
    deadlineCtrl.clear();
    creditHoursCtrl.text = '10';
    skillInputCtrl.clear();
    selectedSkills.clear();
    selectedCategory.value = 'Technology';
    selectedJobType.value  = JobType.onsite;
    certificateProvided.value = false;
    _deadlineDate = null;
    createError.value   = '';
    createSuccess.value = '';
  }

  @override
  void onClose() {
    for (final c in [
      titleCtrl, descCtrl, addressCtrl, cityCtrl, stateCtrl,
      latCtrl, lngCtrl, positionsCtrl, deadlineCtrl,
      creditHoursCtrl, skillInputCtrl, searchCtrl,
    ]) { c.dispose(); }
    super.onClose();
  }
}
