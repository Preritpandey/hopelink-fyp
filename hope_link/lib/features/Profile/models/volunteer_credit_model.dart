class VolunteerCreditBreakdown {
  final String id;
  final String source;
  final String sourceId;
  final String sourceModel;
  final String description;
  final int creditHours;
  final bool isApplied;
  final DateTime? appliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VolunteerCreditBreakdown({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.sourceModel,
    required this.description,
    required this.creditHours,
    required this.isApplied,
    required this.appliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VolunteerCreditBreakdown.fromJson(Map<String, dynamic> json) {
    return VolunteerCreditBreakdown(
      id: json['_id']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      sourceModel: json['sourceModel']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creditHours: (json['creditHours'] as num?)?.toInt() ?? 0,
      isApplied: json['isApplied'] == true,
      appliedAt: _parseDate(json['appliedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class VolunteerCreditSummary {
  final String userId;
  final String userName;
  final String userEmail;
  final int totalCreditHours;
  final int totalPoints;
  final int pointsPerHour;
  final List<VolunteerCreditBreakdown> creditBreakdown;

  const VolunteerCreditSummary({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.totalCreditHours,
    required this.totalPoints,
    required this.pointsPerHour,
    required this.creditBreakdown,
  });

  factory VolunteerCreditSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = json['creditBreakdown'] as List? ?? const [];
    return VolunteerCreditSummary(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      totalCreditHours: (json['totalCreditHours'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      pointsPerHour: (json['pointsPerHour'] as num?)?.toInt() ?? 0,
      creditBreakdown: breakdown
          .whereType<Map<String, dynamic>>()
          .map(VolunteerCreditBreakdown.fromJson)
          .toList(),
    );
  }
}
