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
  final String title;
  final String description;
  final DateTime date;

  const CampaignListUpdate({
    required this.title,
    required this.description,
    required this.date,
  });

  factory CampaignListUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignListUpdate(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// ── Campaign FAQ ──────────────────────────────────────────────
class CampaignListFaq {
  final String question;
  final String answer;

  const CampaignListFaq({required this.question, required this.answer});

  factory CampaignListFaq.fromJson(Map<String, dynamic> json) {
    return CampaignListFaq(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
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
  final List<CampaignListUpdate> updates;
  final List<CampaignListFaq> faqs;
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
    required this.updates,
    required this.faqs,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
    required this.isActive,
  });

  factory CampaignListItem.fromJson(Map<String, dynamic> json) {
    DateTime _dt(String? s) =>
        s != null ? (DateTime.tryParse(s) ?? DateTime.now()) : DateTime.now();

    return CampaignListItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      organization: json['organization'] != null
          ? CampaignOrganization.fromJson(
              json['organization'] as Map<String, dynamic>)
          : null,
      categoryId: json['category'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      startDate: _dt(json['startDate'] as String?),
      endDate: _dt(json['endDate'] as String?),
      status: json['status'] as String? ?? 'active',
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      images:
          (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      updates: (json['updates'] as List? ?? [])
          .map((e) => CampaignListUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      faqs: (json['faqs'] as List? ?? [])
          .map((e) => CampaignListFaq.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  int get daysLeft {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
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
