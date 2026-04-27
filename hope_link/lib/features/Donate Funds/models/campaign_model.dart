import 'package:hive/hive.dart';
import 'post_interaction_models.dart';

part 'campaign_model.g.dart';

@HiveType(typeId: 0)
class Campaign extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final Organization organization;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final double targetAmount;

  @HiveField(6)
  final double currentAmount;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime endDate;

  @HiveField(9)
  final String status;

  @HiveField(10)
  final bool isFeatured;

  @HiveField(11)
  final List<String> tags;

  @HiveField(12)
  final List<String> images;

  @HiveField(13)
  final List<CampaignUpdate> updates;

  @HiveField(14)
  final List<FAQ> faqs;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime updatedAt;

  @HiveField(17)
  final double progress;

  @HiveField(18)
  final bool isActive;

  @HiveField(19)
  final List<String> evidencePhotos;

  final int totalLikes;

  final bool isLikedByCurrentUser;

  final int commentsCount;

  final bool isSavedByCurrentUser;

  Campaign({
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
    required this.evidencePhotos,
    required this.updates,
    required this.faqs,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
    required this.isActive,
    this.totalLikes = 0,
    this.isLikedByCurrentUser = false,
    this.commentsCount = 0,
    this.isSavedByCurrentUser = false,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? json['_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      organization: Organization.fromJson(json['organization'] ?? {}),
      category: json['category'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      images:
          (json['images'] as List?)?.map((img) {
            if (img is String) return img;
            if (img is Map && img['url'] != null) {
              return img['url'].toString();
            }
            return img.toString();
          }).toList() ??
          [],
      evidencePhotos:
          (json['evidencePhotos'] as List?)?.map((img) {
            if (img is String) return img;
            if (img is Map && img['url'] != null) {
              return img['url'].toString();
            }
            return img.toString();
          }).toList() ??
          [],
      updates:
          (json['updates'] as List?)
              ?.map((u) => CampaignUpdate.fromJson(u))
              .toList() ??
          [],
      faqs: (json['faqs'] as List?)?.map((f) => FAQ.fromJson(f)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      progress: (json['progress'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? false,
      totalLikes: (json['totalLikes'] ?? 0) is num
          ? (json['totalLikes'] as num).toInt()
          : 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] == true,
      commentsCount: (json['commentsCount'] ?? 0) is num
          ? (json['commentsCount'] as num).toInt()
          : 0,
      isSavedByCurrentUser: json['isSavedByCurrentUser'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organization': organization.toJson(),
      'category': category,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'isFeatured': isFeatured,
      'tags': tags,
      'images': images,
      'evidencePhotos': evidencePhotos,
      'updates': updates.map((u) => u.toJson()).toList(),
      'faqs': faqs.map((f) => f.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'progress': progress,
      'isActive': isActive,
      'totalLikes': totalLikes,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'commentsCount': commentsCount,
      'isSavedByCurrentUser': isSavedByCurrentUser,
    };
  }

  PostInteractionState get interactionState => PostInteractionState(
    totalLikes: totalLikes,
    isLikedByCurrentUser: isLikedByCurrentUser,
    commentsCount: commentsCount,
  );

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    Organization? organization,
    String? category,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isFeatured,
    List<String>? tags,
    List<String>? images,
    List<String>? evidencePhotos,
    List<CampaignUpdate>? updates,
    List<FAQ>? faqs,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progress,
    bool? isActive,
    int? totalLikes,
    bool? isLikedByCurrentUser,
    int? commentsCount,
    bool? isSavedByCurrentUser,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organization: organization ?? this.organization,
      category: category ?? this.category,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCurrentUser:
          isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsCount: commentsCount ?? this.commentsCount,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
    );
  }
}

@HiveType(typeId: 1)
class Organization {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String organizationName;

  Organization({required this.id, required this.organizationName});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id'] ?? '',
      organizationName: json['organizationName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'organizationName': organizationName};
  }
}

@HiveType(typeId: 2)
class CampaignUpdate {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final DateTime date;

  CampaignUpdate({
    required this.title,
    required this.description,
    required this.date,
  });

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignUpdate(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}

@HiveType(typeId: 3)
class FAQ {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String answer;

  FAQ({required this.question, required this.answer});

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(question: json['question'] ?? '', answer: json['answer'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'question': question, 'answer': answer};
  }
}
