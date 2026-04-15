class CampaignReportFile {
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime uploadedAt;

  const CampaignReportFile({
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.uploadedAt,
  });

  factory CampaignReportFile.fromJson(Map<String, dynamic> json) {
    return CampaignReportFile(
      originalName: json['originalName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CampaignReport {
  final String campaignId;
  final CampaignReportFile reportFile;
  final String downloadEndpoint;
  final DateTime? approvedAt;

  const CampaignReport({
    required this.campaignId,
    required this.reportFile,
    required this.downloadEndpoint,
    required this.approvedAt,
  });

  factory CampaignReport.fromJson(Map<String, dynamic> json) {
    return CampaignReport(
      campaignId: json['campaign']?.toString() ?? '',
      reportFile: CampaignReportFile.fromJson(
        Map<String, dynamic>.from(json['reportFile'] ?? {}),
      ),
      downloadEndpoint: json['downloadEndpoint']?.toString() ?? '',
      approvedAt: DateTime.tryParse(json['approvedAt']?.toString() ?? ''),
    );
  }
}
