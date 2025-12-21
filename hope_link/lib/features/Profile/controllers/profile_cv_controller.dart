import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/profile_service.dart';

// class ProfileCVController extends GetxController {
//   final String token;
//   ProfileCVController(this.token);

//   var uploading = false.obs;

//   Future<void> upload(File file) async {
//     uploading.value = true;
//     await ProfileService.uploadCV(token, file);
//     uploading.value = false;
//   }
// }
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
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      uploading.value = false;
    }
  }
}
