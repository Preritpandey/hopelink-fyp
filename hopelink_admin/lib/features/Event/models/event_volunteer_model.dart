// ─────────────────────────────────────────────────────────────
//  MODEL  —  event_volunteer_model.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Volunteer User Info (embedded) ────────────────────────────
class VolunteerUserInfo {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  final String? phoneNumber;
  final String? gender;
  final String? status;
  final String? description;
  final String? bio;
  final List<String> interests;
  final List<String> skills;
  final Map<String, dynamic>? location;
  final String? cv;
  final int? age;
  final int totalVolunteerHours;
  final int totalPoints;
  final double rating;
  final bool isVerified;
  final DateTime? createdAt;

  const VolunteerUserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
    this.phoneNumber,
    this.gender,
    this.status,
    this.description,
    this.bio,
    this.interests = const [],
    this.skills = const [],
    this.location,
    this.cv,
    this.age,
    this.totalVolunteerHours = 0,
    this.totalPoints = 0,
    this.rating = 0,
    this.isVerified = false,
    this.createdAt,
  });

  factory VolunteerUserInfo.fromJson(Map<String, dynamic> json) {
    final location = json['location'];

    return VolunteerUserInfo(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePicture:
          json['profileImage'] as String? ?? json['profilePicture'] as String?,
      phone: json['phone'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      gender: json['gender'] as String?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interest'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: (json['skills'] as List? ?? []).map((e) => e.toString()).toList(),
      location: location is Map ? Map<String, dynamic>.from(location) : null,
      cv: json['cv'] as String?,
      age: (json['age'] as num?)?.toInt(),
      totalVolunteerHours:
          (json['totalVolunteerHours'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'profilePicture': profilePicture,
    'phone': phone,
    'phoneNumber': phoneNumber,
    'gender': gender,
    'status': status,
    'description': description,
    'bio': bio,
    'interest': interests,
    'skills': skills,
    'location': location,
    'cv': cv,
    'age': age,
    'totalVolunteerHours': totalVolunteerHours,
    'totalPoints': totalPoints,
    'rating': rating,
    'isVerified': isVerified,
    'createdAt': createdAt?.toIso8601String(),
  };

  String? get primaryPhone =>
      (phone != null && phone!.trim().isNotEmpty) ? phone : phoneNumber;

  String get locationLabel {
    final loc = location;
    if (loc == null) return '';
    final parts = [
      loc['address']?.toString(),
      loc['city']?.toString(),
      loc['country']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

// ── Event Volunteer Enrollment ───────────────────────────────
class EventVolunteer {
  final String id;
  final String eventId;
  final VolunteerUserInfo userId;
  final String status; // pending, approved, rejected, attended
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final String? approverNotes;
  final bool attendance;
  final int creditHoursGranted;
  final DateTime? enrollmentDate;
  final DateTime? creditGrantedAt;

  const EventVolunteer({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.approvedAt,
    this.approverNotes,
    this.attendance = false,
    this.creditHoursGranted = 0,
    this.enrollmentDate,
    this.creditGrantedAt,
  });

  factory EventVolunteer.fromJson(Map<String, dynamic> json) {
    DateTime _parse(String? s) {
      if (s == null) return DateTime.now();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    DateTime? _parseNullable(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return EventVolunteer(
      id: json['_id'] as String? ?? '',
      eventId: json['event'] as String? ?? json['eventId'] as String? ?? '',
      userId: VolunteerUserInfo.fromJson(
        json['user'] as Map<String, dynamic>? ??
            json['userId'] as Map<String, dynamic>? ??
            {},
      ),
      status: json['status'] as String? ?? 'pending',
      appliedAt: _parse(
        json['enrollmentDate'] as String? ??
            json['createdAt'] as String? ??
            json['CreatedAt'] as String?,
      ),
      approvedAt: _parseNullable(json['approvedAt'] as String?),
      approverNotes: json['approverNotes'] as String?,
      attendance: json['attendance'] as bool? ?? false,
      creditHoursGranted: (json['creditHoursGranted'] as num?)?.toInt() ?? 0,
      enrollmentDate: _parseNullable(json['enrollmentDate'] as String?),
      creditGrantedAt: _parseNullable(json['creditGrantedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'event': eventId,
    'user': userId.toJson(),
    'status': status,
    'enrollmentDate': appliedAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'approverNotes': approverNotes,
    'attendance': attendance,
    'creditHoursGranted': creditHoursGranted,
    'creditGrantedAt': creditGrantedAt?.toIso8601String(),
  };

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isAttended => status == 'attended';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'attended':
        return 'Attended';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'approved':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'attended':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

// ── API Response for Volunteer List ──────────────────────────
class EventVolunteersResponse {
  final bool success;
  final int count;
  final List<EventVolunteer> enrollments;

  const EventVolunteersResponse({
    required this.success,
    required this.count,
    required this.enrollments,
  });

  factory EventVolunteersResponse.fromJson(Map<String, dynamic> json) {
    return EventVolunteersResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      enrollments: (json['data'] as List? ?? json['enrollments'] as List? ?? [])
          .map((e) => EventVolunteer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Request to update volunteer status ────────────────────────
class UpdateVolunteerStatusRequest {
  final String status; // approved, rejected, attended
  final String? approverNotes;

  const UpdateVolunteerStatusRequest({
    required this.status,
    this.approverNotes,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    if (approverNotes != null) 'approverNotes': approverNotes,
  };
}

// ── Request to update event ──────────────────────────────────
class UpdateEventRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? eventType;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxVolunteers;
  final int? creditHours;
  final List<String>? requiredSkills;
  final String? eligibility;
  final Map<String, dynamic>? location;

  const UpdateEventRequest({
    this.title,
    this.description,
    this.category,
    this.eventType,
    this.status,
    this.startDate,
    this.endDate,
    this.maxVolunteers,
    this.creditHours,
    this.requiredSkills,
    this.eligibility,
    this.location,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (category != null) map['category'] = category;
    if (eventType != null) map['eventType'] = eventType;
    if (status != null) map['status'] = status;
    if (startDate != null) map['startDate'] = startDate!.toIso8601String();
    if (endDate != null) map['endDate'] = endDate!.toIso8601String();
    if (maxVolunteers != null) map['maxVolunteers'] = maxVolunteers;
    if (creditHours != null) map['creditHours'] = creditHours;
    if (requiredSkills != null) map['requiredSkills'] = requiredSkills;
    if (eligibility != null) map['eligibility'] = eligibility;
    if (location != null) map['location'] = location;
    return map;
  }
}

extension EventVolunteerStatusX on String {
  Color statusColor() {
    switch (toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'approved':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'attended':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String statusLabel() {
    switch (toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'attended':
        return 'Attended';
      default:
        return this;
    }
  }
}
