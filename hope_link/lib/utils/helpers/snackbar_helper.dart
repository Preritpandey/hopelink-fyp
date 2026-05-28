

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:hope_link/core/theme/app_colors.dart';

class SnackbarHelper {
  static void showSuccessSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.green.withOpacity(0.9),
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  static void showErrorSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.red.withOpacity(0.9),
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
    );
  }

  static void showInfoSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.blue.withOpacity(0.9),
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  static void showWarningSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.orange.withOpacity(0.9),
      colorText: AppColors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
    );
  }
}



