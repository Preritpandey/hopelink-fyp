import 'dart:io';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import '../services/profile_service.dart';

class ProfileCVController extends GetxController {
  final String token;
  ProfileCVController(this.token);

  var uploading = false.obs;
  var error = ''.obs;

  Future<void> upload(File file) async {
    try {
      uploading.value = true;
      error.value = '';
      await ProfileService.uploadCV(token, file);
      Get.snackbar(
        'Success',
        'CV uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to upload CV: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        colorText: AppColors.white,
        backgroundColor: AppColors.red,
      );
    } finally {
      uploading.value = false;
    }
  }
}

