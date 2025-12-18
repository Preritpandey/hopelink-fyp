import 'dart:io';
import 'package:get/get.dart';
import '../services/profile_service.dart';
import './profile_controller.dart';

class ProfileImageController extends GetxController {
  final String token;
  ProfileImageController(this.token);

  final profileController = Get.find<ProfileController>();
  var uploading = false.obs;

  Future<void> upload(File image) async {
    try {
      uploading.value = true;
      await ProfileService.uploadImage(token, image);
      // Refresh the profile data to get the new image URL
      await profileController.fetchProfile();
      Get.snackbar('Success', 'Profile photo updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile photo');
      rethrow;
    } finally {
      uploading.value = false;
    }
  }
}
