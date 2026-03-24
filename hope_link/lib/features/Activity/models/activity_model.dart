class ActivityModel {
  final String id;
  final String user;
  final String activityType;
  final String resourceType;
  final String resourceId;
  final ActivityMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActivityModel({
    required this.id,
    required this.user,
    required this.activityType,
    required this.resourceType,
    required this.resourceId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] as String? ?? '',
      user: json['user'] as String? ?? '',
      activityType: json['activityType'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String? ?? '',
      metadata: ActivityMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? {},
        json['activityType'] as String? ?? '',
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'user': user,
    'activityType': activityType,
    'resourceType': resourceType,
    'resourceId': resourceId,
    'metadata': metadata.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Polymorphic metadata — covers all known activityType variants
// ---------------------------------------------------------------------------

class ActivityMetadata {
  // donation
  final double? amount;
  final String? campaignId;
  final String? campaignTitle;
  final String? organizationId;
  final String? paymentMethod;
  final bool? isAnonymous;

  // event_registration
  final String? eventId;
  final String? eventTitle;

  // volunteer_job_enrollment
  final String? jobId;
  final String? jobTitle;

  // shared
  final String? status;

  const ActivityMetadata({
    this.amount,
    this.campaignId,
    this.campaignTitle,
    this.organizationId,
    this.paymentMethod,
    this.isAnonymous,
    this.eventId,
    this.eventTitle,
    this.jobId,
    this.jobTitle,
    this.status,
  });

  factory ActivityMetadata.fromJson(
    Map<String, dynamic> json,
    String activityType,
  ) {
    return ActivityMetadata(
      // donation fields
      amount: (json['amount'] as num?)?.toDouble(),
      campaignId: json['campaignId'] as String?,
      campaignTitle: json['campaignTitle'] as String?,
      organizationId: json['organizationId'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      isAnonymous: json['isAnonymous'] as bool?,

      // event fields
      eventId: json['eventId'] as String?,
      eventTitle: json['eventTitle'] as String?,

      // volunteer fields
      jobId: json['jobId'] as String?,
      jobTitle: json['jobTitle'] as String?,

      // shared
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (amount != null) 'amount': amount,
    if (campaignId != null) 'campaignId': campaignId,
    if (campaignTitle != null) 'campaignTitle': campaignTitle,
    if (organizationId != null) 'organizationId': organizationId,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (isAnonymous != null) 'isAnonymous': isAnonymous,
    if (eventId != null) 'eventId': eventId,
    if (eventTitle != null) 'eventTitle': eventTitle,
    if (jobId != null) 'jobId': jobId,
    if (jobTitle != null) 'jobTitle': jobTitle,
    if (status != null) 'status': status,
  };

  /// Human-readable title for any activity type
  String get displayTitle {
    if (campaignTitle != null) return campaignTitle!;
    if (eventTitle != null) return eventTitle!;
    if (jobTitle != null) return jobTitle!;
    return 'Activity';
  }
}

// ---------------------------------------------------------------------------
// Pagination wrapper
// ---------------------------------------------------------------------------

class ActivitiesResponse {
  final bool success;
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<ActivityModel> data;

  const ActivitiesResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory ActivitiesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    return ActivitiesResponse(
      success: json['success'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
      data: rawList
          .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
