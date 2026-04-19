import 'package:get/get.dart';

import '../models/volunteer_credit_model.dart';
import '../services/volunteer_credit_service.dart';

class VolunteerCreditController extends GetxController {
  VolunteerCreditController(this.token);

  final String token;

  final isLoading = false.obs;
  final credits = Rxn<VolunteerCreditSummary>();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCredits();
  }

  Future<void> fetchCredits() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      credits.value = await VolunteerCreditService.getVolunteerCredits(token);
    } catch (_) {
      errorMessage.value = 'Unable to load points right now';
    } finally {
      isLoading.value = false;
    }
  }
}
