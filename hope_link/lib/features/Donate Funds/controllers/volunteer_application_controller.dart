import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerApplicationController extends GetxController {
  final Rx<File?> resumeFile = Rx<File?>(null);
  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;

  void setResume(File file) {
    resumeFile.value = file;
  }

  void removeResume() {
    resumeFile.value = null;
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

  Future<bool> submitApplication({
    required String jobId,
    required String whyHire,
    required String skills,
    required String experience,
  }) async {
    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      final token = await _getAuthToken();
      if (token == null) {
        errorMessage.value = 'Authentication token not found';
        Get.snackbar(
          'Error',
          'Please log in again',
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
        isSubmitting.value = false;
        return false;
      }

      if (resumeFile.value == null) {
        errorMessage.value = 'Resume is required';
        isSubmitting.value = false;
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.volunteerJobs}/$jobId/apply'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['whyHire'] = whyHire;
      request.fields['skills'] = skills;
      request.fields['experience'] = experience;

      // Add file with explicit content type and robust filename handling
      final file = resumeFile.value!;
      final filename = p.basename(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'resume',
        file.path,
        contentType: MediaType('application', 'pdf'),
        filename: filename,
      );
      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Clear form
          resumeFile.value = null;
          return true;
        } else {
          errorMessage.value = jsonData['message'] ?? 'Application failed';
          Get.snackbar(
            'Error',
            errorMessage.value,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        }
      } else {
        final jsonData = json.decode(response.body);
        errorMessage.value =
            jsonData['message'] ?? 'Failed to submit application';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('Error submitting application: $e');
      Get.snackbar(
        'Error',
        'Failed to submit application. Please try again.',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
