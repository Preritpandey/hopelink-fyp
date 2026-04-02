// ─────────────────────────────────────────────────────────────
//  MODELS  —  campaign_model.dart
// ─────────────────────────────────────────────────────────────

// ── Create Campaign Request ───────────────────────────────────
class CreateCampaignRequest {
  final String title;
  final String description;
  final String category;
  final String startDate;
  final String endDate;
  final double targetAmount;

  const CreateCampaignRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.targetAmount,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'startDate': startDate,
    'endDate': endDate,
    'targetAmount': targetAmount,
  };
}

// ── Campaign Model ────────────────────────────────────────────
class Campaign {
  final String id;
  final String title;
  final String description;
  final String organization;
  final String category;
  final double targetAmount;
  final double currentAmount;
  final String startDate;
  final String endDate;
  final String status;
  final bool isFeatured;
  final List<String> tags;
  final List<String> images;
  final List<CampaignUpdate> updates;
  final List<CampaignFaq> faqs;
  final double progress;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.category,
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
    required this.progress,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String? ?? json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      organization: json['organization'] as String? ?? '',
      category: json['category'] is Map
          ? (json['category'] as Map)['_id'] as String
          : json['category'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num? ?? 0).toDouble(),
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      status: json['status'] as String? ?? 'active',
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      updates:
          (json['updates'] as List?)
              ?.map((e) => CampaignUpdate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      faqs:
          (json['faqs'] as List?)
              ?.map((e) => CampaignFaq.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      progress: (json['progress'] as num? ?? 0).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
}

// ── Campaign Update ───────────────────────────────────────────
class CampaignUpdate {
  final String id;
  final String title;
  final String description;
  final String createdAt;

  const CampaignUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignUpdate(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'description': description};
}

// ── Campaign FAQ ──────────────────────────────────────────────
class CampaignFaq {
  final String id;
  final String question;
  final String answer;

  const CampaignFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory CampaignFaq.fromJson(Map<String, dynamic> json) {
    return CampaignFaq(
      id: json['_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

// ── Category ──────────────────────────────────────────────────
class CampaignCategory {
  final String id;
  final String name;

  const CampaignCategory({required this.id, required this.name});

  factory CampaignCategory.fromJson(Map<String, dynamic> json) {
    return CampaignCategory(
      id: json['_id'] as String,
      name: json['name'] as String,
    );
  }
}

// ── Dashboard Stats ───────────────────────────────────────────
class DashboardStats {
  final int totalCampaigns;
  final int activeCampaigns;
  final double totalRaised;
  final double totalTarget;
  final int totalUpdates;
  final int totalFaqs;

  const DashboardStats({
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.totalRaised,
    required this.totalTarget,
    required this.totalUpdates,
    required this.totalFaqs,
  });

  factory DashboardStats.fromCampaigns(List<Campaign> campaigns) {
    return DashboardStats(
      totalCampaigns: campaigns.length,
      activeCampaigns: campaigns.where((c) => c.isActive).length,
      totalRaised: campaigns.fold(0, (sum, c) => sum + c.currentAmount),
      totalTarget: campaigns.fold(0, (sum, c) => sum + c.targetAmount),
      totalUpdates: campaigns.fold(0, (sum, c) => sum + c.updates.length),
      totalFaqs: campaigns.fold(0, (sum, c) => sum + c.faqs.length),
    );
  }
}
