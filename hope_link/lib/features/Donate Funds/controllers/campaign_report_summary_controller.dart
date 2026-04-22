import 'package:get/get.dart';

import '../models/campaign_report_summary_model.dart';
import '../services/campaign_service.dart';

class CampaignReportSummaryController extends GetxController {
  CampaignReportSummaryController({CampaignService? service})
      : _service = service ?? CampaignService();

  final CampaignService _service;

  final Rxn<CampaignReportSummary> summary = Rxn<CampaignReportSummary>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  Future<void> loadSummary(String campaignId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await _service.getCampaignReportSummary(campaignId);
      summary.value = response;
    } catch (e) {
      summary.value = null;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void clear() {
    summary.value = null;
    errorMessage.value = null;
    isLoading.value = false;
  }
}
