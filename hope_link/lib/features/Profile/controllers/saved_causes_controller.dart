import 'package:get/get.dart';
import 'package:hope_link/features/Donate%20Funds/controllers/campaign_controller.dart';
import 'package:hope_link/features/Donate%20Funds/controllers/event_controller.dart';
import 'package:hope_link/features/Donate%20Funds/controllers/volunteer_job_controller.dart';

import '../models/saved_cause_model.dart';
import '../services/saved_causes_service.dart';

class SavedCausesController extends GetxController {
  final SavedCausesService _service = SavedCausesService();

  final RxList<SavedCauseEntry> savedCauses = <SavedCauseEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxSet<String> busyPostIds = <String>{}.obs;

  Future<void> fetchSavedCauses({bool showLoader = true}) async {
    try {
      if (showLoader) {
        isLoading.value = true;
      }
      errorMessage.value = '';
      final results = await _service.fetchSavedCauses();
      savedCauses.value = results;
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  bool isBusy(String postId) => busyPostIds.contains(postId);

  Future<bool> toggleSaved({
    required String postType,
    required String postId,
    required bool currentlySaved,
  }) async {
    busyPostIds.add(postId);
    busyPostIds.refresh();

    try {
      if (currentlySaved) {
        await _service.unsaveCause(postId);
      } else {
        await _service.saveCause(postId);
      }

      final nextState = !currentlySaved;
      _syncSavedState(postType, postId, nextState);

      if (currentlySaved) {
        savedCauses.removeWhere((item) => item.postId == postId);
      } else if (savedCauses.isNotEmpty) {
        await fetchSavedCauses(showLoader: false);
      }

      return nextState;
    } catch (error) {
      Get.snackbar(
        'Save failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return currentlySaved;
    } finally {
      busyPostIds.remove(postId);
      busyPostIds.refresh();
    }
  }

  void _syncSavedState(String postType, String postId, bool isSaved) {
    switch (postType) {
      case 'campaign':
        if (Get.isRegistered<CampaignController>()) {
          Get.find<CampaignController>().updateCampaignSavedState(postId, isSaved);
        }
        break;
      case 'event':
        if (Get.isRegistered<EventController>()) {
          Get.find<EventController>().updateEventSavedState(postId, isSaved);
        }
        break;
      case 'volunteerJob':
        if (Get.isRegistered<VolunteerJobController>()) {
          Get.find<VolunteerJobController>().updateJobSavedState(postId, isSaved);
        }
        break;
    }
  }
}
