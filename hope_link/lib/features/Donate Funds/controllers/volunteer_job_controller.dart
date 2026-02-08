import 'dart:convert';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/volunteer_job_model.dart';

class VolunteerJobController extends GetxController {
  final RxList<VolunteerJob> volunteerJobs = <VolunteerJob>[].obs;
  final RxList<VolunteerJob> filteredJobs = <VolunteerJob>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVolunteerJobs();
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> fetchVolunteerJobs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await _getAuthToken();
      if (token == null) {
        errorMessage.value = 'Authentication token not found';
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.volunteerJobs),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> jobsData = jsonData['data'];
          volunteerJobs.value = jobsData
              .map((json) => VolunteerJob.fromJson(json))
              .toList();
          applyFilter();
        } else {
          errorMessage.value = jsonData['message'] ?? 'Failed to load jobs';
        }
      } else {
        errorMessage.value = 'Failed to load volunteer jobs';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('Error fetching volunteer jobs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilter();
  }

  void applyFilter() {
    if (selectedFilter.value == 'all') {
      filteredJobs.value = volunteerJobs;
    } else if (selectedFilter.value == 'active') {
      filteredJobs.value = volunteerJobs
          .where((job) => job.isOpen && job.hasPositionsAvailable)
          .toList();
    } else if (selectedFilter.value == 'remote') {
      filteredJobs.value = volunteerJobs
          .where((job) => job.jobType == 'remote')
          .toList();
    } else if (selectedFilter.value == 'onsite') {
      filteredJobs.value = volunteerJobs
          .where((job) => job.jobType == 'onsite')
          .toList();
    }
  }

  void searchJobs(String query) {
    if (query.isEmpty) {
      applyFilter();
      return;
    }

    filteredJobs.value = volunteerJobs.where((job) {
      final titleMatch = job.title.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = job.category.toLowerCase().contains(
        query.toLowerCase(),
      );
      final descriptionMatch = job.description.toLowerCase().contains(
        query.toLowerCase(),
      );
      final skillsMatch = job.requiredSkills.any(
        (skill) => skill.toLowerCase().contains(query.toLowerCase()),
      );

      return titleMatch || categoryMatch || descriptionMatch || skillsMatch;
    }).toList();
  }

  List<VolunteerJob> getJobsByCategory(String category) {
    return volunteerJobs.where((job) => job.category == category).toList();
  }

  List<String> getAllCategories() {
    return volunteerJobs.map((job) => job.category).toSet().toList();
  }

  Future<void> refreshJobs() async {
    await fetchVolunteerJobs();
  }
}
