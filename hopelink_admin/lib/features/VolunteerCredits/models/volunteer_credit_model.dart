import 'package:hopelink_admin/features/Event/models/org_event_model.dart';
import 'package:hopelink_admin/features/Jobs/models/job_model.dart';
import 'package:intl/intl.dart';

enum VolunteerCreditSource { job, event }

extension VolunteerCreditSourceX on VolunteerCreditSource {
  String get value => this == VolunteerCreditSource.job ? 'job' : 'event';
  String get label => this == VolunteerCreditSource.job
      ? 'Job Volunteers'
      : 'Event Participants';
}

class VolunteerCreditUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final List<String> skills;
  final int totalVolunteerHours;
  final double rating;

  const VolunteerCreditUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.skills,
    required this.totalVolunteerHours,
    required this.rating,
  });

  factory VolunteerCreditUser.fromJson(Map<String, dynamic> json) {
    return VolunteerCreditUser(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      profileImage:
          json['profileImage'] as String? ?? json['profilePicture'] as String?,
      skills: (json['skills'] as List? ?? []).map((e) => e.toString()).toList(),
      totalVolunteerHours: (json['totalVolunteerHours'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final list = parts.toList();
    if (list.length >= 2) {
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class VolunteerCreditEntry {
  final String id;
  final VolunteerCreditSource source;
  final String parentId;
  final VolunteerCreditUser user;
  final String status;
  final int creditHoursGranted;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? enrollmentDate;
  final DateTime? creditGrantedAt;
  final bool? attendance;

  const VolunteerCreditEntry({
    required this.id,
    required this.source,
    required this.parentId,
    required this.user,
    required this.status,
    required this.creditHoursGranted,
    this.approvedAt,
    required this.createdAt,
    this.enrollmentDate,
    this.creditGrantedAt,
    this.attendance,
  });

  factory VolunteerCreditEntry.fromJobJson(Map<String, dynamic> json) {
    return VolunteerCreditEntry(
      id: json['_id'] as String? ?? '',
      source: VolunteerCreditSource.job,
      parentId: json['job'] as String? ?? '',
      user: VolunteerCreditUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      status: json['status'] as String? ?? 'approved',
      creditHoursGranted: (json['creditHoursGranted'] as num?)?.toInt() ?? 0,
      approvedAt: _parseDate(json['approvedAt'] as String?),
      createdAt: _parseDate(json['createdAt'] as String?) ?? DateTime.now(),
      creditGrantedAt: _parseDate(json['creditGrantedAt'] as String?),
    );
  }

  factory VolunteerCreditEntry.fromEventJson(Map<String, dynamic> json) {
    return VolunteerCreditEntry(
      id: json['_id'] as String? ?? '',
      source: VolunteerCreditSource.event,
      parentId: json['event'] as String? ?? '',
      user: VolunteerCreditUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      status: json['status'] as String? ?? 'approved',
      creditHoursGranted: (json['creditHoursGranted'] as num?)?.toInt() ?? 0,
      approvedAt: _parseDate(json['approvedAt'] as String?),
      createdAt: _parseDate(json['createdAt'] as String?) ?? DateTime.now(),
      enrollmentDate: _parseDate(json['enrollmentDate'] as String?),
      creditGrantedAt: _parseDate(json['creditGrantedAt'] as String?),
      attendance: json['attendance'] as bool?,
    );
  }

  VolunteerCreditEntry copyWith({
    int? creditHoursGranted,
    DateTime? creditGrantedAt,
    bool? attendance,
  }) {
    return VolunteerCreditEntry(
      id: id,
      source: source,
      parentId: parentId,
      user: user,
      status: status,
      creditHoursGranted: creditHoursGranted ?? this.creditHoursGranted,
      approvedAt: approvedAt,
      createdAt: createdAt,
      enrollmentDate: enrollmentDate,
      creditGrantedAt: creditGrantedAt ?? this.creditGrantedAt,
      attendance: attendance ?? this.attendance,
    );
  }

  bool get creditsGranted => creditHoursGranted > 0;

  String get timelineLabel {
    final dt = enrollmentDate ?? approvedAt ?? createdAt;
    return DateFormat('MMM dd, yyyy').format(dt);
  }
}

class VolunteerCreditSourceOption {
  final String id;
  final String title;
  final String subtitle;
  final int? creditHours;
  final VolunteerCreditSource source;

  const VolunteerCreditSourceOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.source,
    this.creditHours,
  });

  factory VolunteerCreditSourceOption.fromJob(VolunteerJob job) {
    return VolunteerCreditSourceOption(
      id: job.id,
      title: job.title,
      subtitle: '${job.category} - ${job.location.displayCity}',
      creditHours: job.creditHours,
      source: VolunteerCreditSource.job,
    );
  }

  factory VolunteerCreditSourceOption.fromEvent(OrgEvent event) {
    return VolunteerCreditSourceOption(
      id: event.id,
      title: event.title,
      subtitle: '${event.category} - ${event.location.displayCity}',
      creditHours: event.creditHours,
      source: VolunteerCreditSource.event,
    );
  }
}

class VolunteerCreditListResponse {
  final bool success;
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<VolunteerCreditEntry> data;

  const VolunteerCreditListResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory VolunteerCreditListResponse.fromJobJson(Map<String, dynamic> json) {
    final list = (json['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(VolunteerCreditEntry.fromJobJson)
        .toList();
    return VolunteerCreditListResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? list.length,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      data: list,
    );
  }

  factory VolunteerCreditListResponse.fromEventJson(Map<String, dynamic> json) {
    final list = (json['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(VolunteerCreditEntry.fromEventJson)
        .toList();
    return VolunteerCreditListResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? list.length,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      data: list,
    );
  }
}

class GrantCreditHoursResponse {
  final bool success;
  final String message;
  final int creditHoursGranted;
  final DateTime? creditGrantedAt;

  const GrantCreditHoursResponse({
    required this.success,
    required this.message,
    required this.creditHoursGranted,
    this.creditGrantedAt,
  });

  factory GrantCreditHoursResponse.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return GrantCreditHoursResponse(
      success: json['success'] as bool? ?? false,
      message:
          json['message'] as String? ?? 'Credit hours granted successfully',
      creditHoursGranted: (data['creditHoursGranted'] as num?)?.toInt() ?? 0,
      creditGrantedAt: _parseDate(data['creditGrantedAt'] as String?),
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
