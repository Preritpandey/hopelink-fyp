class CampaignReportSummary {
  final String campaignId;
  final String reportId;
  final String summary;
  final DateTime? generatedAt;
  final String model;
  final bool cached;
  final DateTime? approvedAt;

  const CampaignReportSummary({
    required this.campaignId,
    required this.reportId,
    required this.summary,
    required this.generatedAt,
    required this.model,
    required this.cached,
    required this.approvedAt,
  });

  factory CampaignReportSummary.fromJson(Map<String, dynamic> json) {
    return CampaignReportSummary(
      campaignId: json['campaignId']?.toString() ?? '',
      reportId: json['reportId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      model: json['model']?.toString() ?? '',
      cached: json['cached'] == true,
      approvedAt: DateTime.tryParse(json['approvedAt']?.toString() ?? ''),
    );
  }
}
