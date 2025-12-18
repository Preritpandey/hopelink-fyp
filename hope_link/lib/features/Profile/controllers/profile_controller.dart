// import 'package:get/get.dart';
// import '../models/user_model.dart';
// import '../services/profile_service.dart';

// class ProfileController extends GetxController {
//   final String token;
//   ProfileController(this.token);

//   var isLoading = false.obs;
//   var isEditMode = false.obs;
//   Rx<UserModel?> user = Rx<UserModel?>(null);

//   @override
//   void onInit() {
//     fetchProfile();
//     super.onInit();
//   }

//   Future<void> fetchProfile() async {
//     try {
//       isLoading.value = true;
//       final res = await ProfileService.getProfile(token);
//       user.value = UserModel.fromJson(res['user']);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to fetch profile data');
//       rethrow;
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void updateProfile(Map<String, dynamic> body) async {
//     await ProfileService.updateProfile(token, body);
//     fetchProfile();
//     isEditMode.value = false;
//   }
// }
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  final String token;
  ProfileController(this.token);

  final isLoading = false.obs;
  final isEditMode = false.obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final res = await ProfileService.getProfile(token);
      user.value = UserModel.fromJson(res['user']);
    } catch (_) {
      Get.snackbar('Error', 'Failed to fetch profile data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    try {
      isLoading.value = true;
      await ProfileService.updateProfile(token, body);
      await fetchProfile();
      isEditMode.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  void updateInterests(List<String> interests) {
    if (user.value == null) return;

    user.value = user.value!.copyWith(interest: interests);
  }

  void toggleEdit() => isEditMode.toggle();
}
