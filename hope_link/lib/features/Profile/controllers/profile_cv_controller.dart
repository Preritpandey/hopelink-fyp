import 'dart:io';
import 'package:get/get.dart';
import '../services/profile_service.dart';

class ProfileCVController extends GetxController {
  final String token;
  ProfileCVController(this.token);

  var uploading = false.obs;

  Future<void> upload(File file) async {
    uploading.value = true;
    await ProfileService.uploadCV(token, file);
    uploading.value = false;
  }
}
