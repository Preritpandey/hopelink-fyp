// ─────────────────────────────────────────────────────────────
//  MODEL  —  campaign_list_model.dart
// ─────────────────────────────────────────────────────────────

// ── Organisation (embedded) ───────────────────────────────────
class CampaignOrganization {
  final String id;
  final String organizationName;

  const CampaignOrganization({
    required this.id,
    required this.organizationName,
  });

  factory CampaignOrganization.fromJson(Map<String, dynamic> json) {
    return CampaignOrganization(
      id: json['_id'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? 'Unknown',
    );
  }
}

// ── Campaign Update ───────────────────────────────────────────
class CampaignListUpdate {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  const CampaignListUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  factory CampaignListUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignListUpdate(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: DateTime.tryParse(
            json['date'] as String? ?? json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

// ── Campaign FAQ ──────────────────────────────────────────────
class CampaignListFaq {
  final String id;
  final String question;
  final String answer;

  const CampaignListFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory CampaignListFaq.fromJson(Map<String, dynamic> json) {
    return CampaignListFaq(
      id: json['_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class CampaignReportFileSnapshot {
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime uploadedAt;
  final String url;

  const CampaignReportFileSnapshot({
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.uploadedAt,
    required this.url,
  });

  factory CampaignReportFileSnapshot.fromJson(Map<String, dynamic> json) {
    return CampaignReportFileSnapshot(
      originalName: json['originalName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
          DateTime.now(),
      url: json['url'] as String? ?? '',
    );
  }
}

class CampaignReportSnapshot {
  final String id;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final CampaignReportFileSnapshot? reportFile;

  const CampaignReportSnapshot({
    required this.id,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.reportFile,
  });

  factory CampaignReportSnapshot.fromJson(Map<String, dynamic> json) {
    return CampaignReportSnapshot(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      rejectionReason: json['rejectionReason'] as String?,
      reportFile: json['reportFile'] is Map<String, dynamic>
          ? CampaignReportFileSnapshot.fromJson(
              json['reportFile'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// ── Campaign (list item) ──────────────────────────────────────
class CampaignListItem {
  final String id;
  final String title;
  final String description;
  final CampaignOrganization? organization;
  final String categoryId;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isFeatured;
  final List<String> tags;
  final List<String> images;
  final List<String> evidencePhotos;
  final List<CampaignListUpdate> updates;
  final List<CampaignListFaq> faqs;
  final CampaignReportSnapshot? report;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double progress;
  final bool isActive;

  const CampaignListItem({
    required this.id,
    required this.title,
    required this.description,
    this.organization,
    required this.categoryId,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isFeatured,
    required this.tags,
    required this.images,
    required this.evidencePhotos,
    required this.updates,
    required this.faqs,
    required this.report,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
    required this.isActive,
  });

  factory CampaignListItem.fromJson(Map<String, dynamic> json) {
    DateTime _dt(String? s) =>
        s != null ? (DateTime.tryParse(s) ?? DateTime.now()) : DateTime.now();
    CampaignOrganization? _org(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        return CampaignOrganization.fromJson(raw);
      }
      if (raw is String) {
        return CampaignOrganization(
          id: raw,
          organizationName: 'Organization',
        );
      }
      return null;
    }

    List<String> _imgs(dynamic raw) {
      final list = raw as List? ?? [];
      return list
          .map((e) {
            if (e is String) return e;
            if (e is Map<String, dynamic>) return e['url'] as String? ?? '';
            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return CampaignListItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      organization: _org(json['organization']),
      categoryId: json['category'] is Map
          ? (json['category'] as Map)['_id'] as String? ?? ''
          : json['category'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      startDate: _dt(json['startDate'] as String?),
      endDate: _dt(json['endDate'] as String?),
      status: json['status'] as String? ?? 'active',
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      images: _imgs(json['images']),
      evidencePhotos: _imgs(json['evidencePhotos']),
      updates: (json['updates'] as List? ?? [])
          .map((e) => CampaignListUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      faqs: (json['faqs'] as List? ?? [])
          .map((e) => CampaignListFaq.fromJson(e as Map<String, dynamic>))
          .toList(),
      report: json['report'] is Map<String, dynamic>
          ? CampaignReportSnapshot.fromJson(
              json['report'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _dt(json['createdAt'] as String?),
      updatedAt: _dt(json['updatedAt'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // ── Computed ──────────────────────────────────────────────
  double get progressPercent => progress.clamp(0, 100);
  bool get hasImages => images.isNotEmpty;
  String? get primaryImage => images.isNotEmpty ? images.first : null;
  bool get hasEvidencePhotos => evidencePhotos.isNotEmpty;

  int get daysLeft {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  CampaignListItem copyWith({
    String? title,
    String? description,
    CampaignOrganization? organization,
    String? categoryId,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isFeatured,
    List<String>? tags,
    List<String>? images,
    List<String>? evidencePhotos,
    List<CampaignListUpdate>? updates,
    List<CampaignListFaq>? faqs,
    CampaignReportSnapshot? report,
    bool replaceReport = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progress,
    bool? isActive,
  }) {
    return CampaignListItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      organization: organization ?? this.organization,
      categoryId: categoryId ?? this.categoryId,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      updates: updates ?? this.updates,
      faqs: faqs ?? this.faqs,
      report: replaceReport ? report : this.report,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
    );
  }
}

// â”€â”€ Update Campaign Request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class UpdateCampaignRequest {
  final String? title;
  final String? description;
  final double? targetAmount;
  final String? startDate;
  final String? endDate;
  final List<String>? tags;
  final bool? isFeatured;
  final String? status;

  const UpdateCampaignRequest({
    this.title,
    this.description,
    this.targetAmount,
    this.startDate,
    this.endDate,
    this.tags,
    this.isFeatured,
    this.status,
  });

  bool get isEmpty {
    return title == null &&
        description == null &&
        targetAmount == null &&
        startDate == null &&
        endDate == null &&
        tags == null &&
        isFeatured == null &&
        status == null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (targetAmount != null) data['targetAmount'] = targetAmount;
    if (startDate != null) data['startDate'] = startDate;
    if (endDate != null) data['endDate'] = endDate;
    if (tags != null) data['tags'] = tags;
    if (isFeatured != null) data['isFeatured'] = isFeatured;
    if (status != null) data['status'] = status;
    return data;
  }
}

// â”€â”€ Donations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class CampaignDonationDonor {
  final String id;
  final String name;
  final String email;

  const CampaignDonationDonor({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CampaignDonationDonor.fromJson(Map<String, dynamic> json) {
    return CampaignDonationDonor(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anonymous',
      email: json['email'] as String? ?? '',
    );
  }
}

class CampaignDonation {
  final String id;
  final String campaignId;
  final CampaignDonationDonor? donor;
  final double amount;
  final String? message;
  final bool isAnonymous;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final DateTime createdAt;

  const CampaignDonation({
    required this.id,
    required this.campaignId,
    required this.donor,
    required this.amount,
    required this.message,
    required this.isAnonymous,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.createdAt,
  });

  factory CampaignDonation.fromJson(Map<String, dynamic> json) {
    return CampaignDonation(
      id: json['_id'] as String? ?? '',
      campaignId: json['campaign'] as String? ?? '',
      donor: json['donor'] is Map<String, dynamic>
          ? CampaignDonationDonor.fromJson(
              json['donor'] as Map<String, dynamic>,
            )
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      status: json['status'] as String? ?? 'completed',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

// ── API Response ──────────────────────────────────────────────
class CampaignListResponse {
  final bool success;
  final int count;
  final List<CampaignListItem> data;

  const CampaignListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory CampaignListResponse.fromJson(Map<String, dynamic> json) {
    return CampaignListResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) =>
              CampaignListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Filter & Sort ─────────────────────────────────────────────
enum CampaignStatusFilter { all, active, completed, paused, cancelled }

extension CampaignStatusFilterX on CampaignStatusFilter {
  String get label {
    switch (this) {
      case CampaignStatusFilter.all:       return 'All';
      case CampaignStatusFilter.active:    return 'Active';
      case CampaignStatusFilter.completed: return 'Completed';
      case CampaignStatusFilter.paused:    return 'Paused';
      case CampaignStatusFilter.cancelled: return 'Cancelled';
    }
  }

  String? get value => this == CampaignStatusFilter.all ? null : name;
}

enum CampaignSortOption { newest, oldest, progress, target }

extension CampaignSortOptionX on CampaignSortOption {
  String get label {
    switch (this) {
      case CampaignSortOption.newest:   return 'Newest First';
      case CampaignSortOption.oldest:   return 'Oldest First';
      case CampaignSortOption.progress: return 'Most Progress';
      case CampaignSortOption.target:   return 'Highest Goal';
    }
  }
}

enum CampaignViewMode { grid, list }
