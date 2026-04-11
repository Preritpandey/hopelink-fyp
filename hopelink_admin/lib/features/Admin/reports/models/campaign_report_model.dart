// ─────────────────────────────────────────────────────────────
//  MODEL  —  campaign_report_model.dart
// ─────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

// ── Report Status ─────────────────────────────────────────────
enum ReportStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  final String value;
  final String label;
  const ReportStatus(this.value, this.label);

  static ReportStatus fromString(String s) => ReportStatus.values.firstWhere(
        (e) => e.value == s.toLowerCase(),
        orElse: () => ReportStatus.pending,
      );
}

// ── Campaign (embedded) ───────────────────────────────────────
class ReportCampaign {
  final String id;
  final String title;
  final double? progress;
  final bool isActive;

  const ReportCampaign({
    required this.id,
    required this.title,
    this.progress,
    required this.isActive,
  });

  factory ReportCampaign.fromJson(Map<String, dynamic> json) {
    return ReportCampaign(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

// ── Organization (embedded) ───────────────────────────────────
class ReportOrganization {
  final String id;
  final String organizationName;

  const ReportOrganization({required this.id, required this.organizationName});

  factory ReportOrganization.fromJson(Map<String, dynamic> json) {
    return ReportOrganization(
      id: json['_id'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? 'Unknown',
    );
  }
}

// ── Report File ───────────────────────────────────────────────
class ReportFile {
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime uploadedAt;
  final String url;
  final String publicId;

  const ReportFile({
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.uploadedAt,
    required this.url,
    required this.publicId,
  });

  factory ReportFile.fromJson(Map<String, dynamic> json) {
    return ReportFile(
      originalName: json['originalName'] as String? ?? 'report.pdf',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      url: json['url'] as String? ?? '',
      publicId: json['publicId'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isPdf => mimeType.contains('pdf');
}

// ── Campaign Report ───────────────────────────────────────────
class CampaignReport {
  final String id;
  final ReportCampaign campaign;
  final ReportOrganization organization;
  final ReportStatus status;
  final DateTime submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final ReportFile reportFile;
  final String downloadEndpoint;

  const CampaignReport({
    required this.id,
    required this.campaign,
    required this.organization,
    required this.status,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.reportFile,
    required this.downloadEndpoint,
  });

  factory CampaignReport.fromJson(Map<String, dynamic> json) {
    DateTime? maybeDate(String? s) =>
        s != null ? DateTime.tryParse(s) : null;

    return CampaignReport(
      id: json['id'] as String? ?? '',
      campaign:
          ReportCampaign.fromJson(json['campaign'] as Map<String, dynamic>? ?? {}),
      organization: ReportOrganization.fromJson(
          json['organization'] as Map<String, dynamic>? ?? {}),
      status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: maybeDate(json['reviewedAt'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      reportFile:
          ReportFile.fromJson(json['reportFile'] as Map<String, dynamic>? ?? {}),
      downloadEndpoint: json['downloadEndpoint'] as String? ?? '',
    );
  }

  // Convenience
  String get submittedFormatted =>
      DateFormat('MMM dd, yyyy · h:mm a').format(submittedAt);

  String get reviewedFormatted => reviewedAt != null
      ? DateFormat('MMM dd, yyyy · h:mm a').format(reviewedAt!)
      : '—';

  Duration get pendingDuration => DateTime.now().difference(submittedAt);

  String get pendingLabel {
    final d = pendingDuration;
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }
}

// ── List Response ─────────────────────────────────────────────
class CampaignReportsResponse {
  final bool success;
  final int count;
  final List<CampaignReport> data;

  const CampaignReportsResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory CampaignReportsResponse.fromJson(Map<String, dynamic> json) {
    return CampaignReportsResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => CampaignReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Action Response ───────────────────────────────────────────
class ReportActionResponse {
  final bool success;
  final String message;
  final String reportId;
  final String newStatus;

  const ReportActionResponse({
    required this.success,
    required this.message,
    required this.reportId,
    required this.newStatus,
  });

  factory ReportActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ReportActionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      reportId: data['id'] as String? ?? '',
      newStatus: data['status'] as String? ?? '',
    );
  }
}
