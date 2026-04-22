import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';

import '../controllers/campaign_report_summary_controller.dart';
import '../models/campaign_report_model.dart';

class CampaignReportInsightsSection extends StatelessWidget {
  const CampaignReportInsightsSection({
    super.key,
    required this.campaignReport,
    required this.isReportLoading,
    required this.reportMessage,
    required this.summaryController,
    required this.onOpenReport,
    required this.formatDate,
    required this.formatFileSize,
  });

  final CampaignReport? campaignReport;
  final bool isReportLoading;
  final String? reportMessage;
  final CampaignReportSummaryController summaryController;
  final VoidCallback onOpenReport;
  final String Function(DateTime date) formatDate;
  final String Function(int bytes) formatFileSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportCard(),
        if (campaignReport != null) ...[16.verticalSpace, _buildSummaryCard()],
      ],
    );
  }

  Widget _buildReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColorToken.primary.color.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColorToken.primary.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColorToken.primary.color,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation report',
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      'See the approved report file for this campaign.',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          if (isReportLoading)
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColorToken.primary.color,
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Text(
                    'Loading campaign report...',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            )
          else if (campaignReport != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaignReport!.reportFile.originalName,
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                12.verticalSpace,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      Icons.sd_storage_rounded,
                      formatFileSize(campaignReport!.reportFile.size),
                    ),

                    if (campaignReport!.approvedAt != null)
                      _buildMetaChip(
                        Icons.verified_rounded,
                        'Approved ${formatDate(campaignReport!.approvedAt!)}',
                      ),
                  ],
                ),
                16.verticalSpace,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    title: 'View Report',
                    backgroundColor: AppColorToken.primary.color,
                    onPressed: onOpenReport,
                    radius: 14,
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                reportMessage ??
                    'Campaign report has not been uploaded or approved yet.',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final summary = summaryController.summary.value;
      final isLoading = summaryController.isLoading.value;
      final errorMessage = summaryController.errorMessage.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF4FBF6),
              Colors.white,
              AppColorToken.primary.color.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColorToken.primary.color.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColorToken.primary.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColorToken.primary.color,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI summary',
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        'A quick, readable overview generated from the approved campaign report.',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.grey[600],
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            18.verticalSpace,
            if (isLoading)
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColorToken.primary.color,
                      ),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Generating an easy-to-read summary...',
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              )
            else if (summary != null && summary.summary.trim().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      summary.summary,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: Colors.grey[800],
                        height: 1.7,
                      ),
                    ),
                  ),
                  14.verticalSpace,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (summary.generatedAt != null)
                        _buildMetaChip(
                          Icons.schedule_rounded,
                          'Generated ${formatDate(summary.generatedAt!)}',
                        ),
                    ],
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  errorMessage ??
                      'AI summary is not available for this report yet.',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColorToken.primary.color),
          6.horizontalSpace,
          Flexible(
            child: Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
