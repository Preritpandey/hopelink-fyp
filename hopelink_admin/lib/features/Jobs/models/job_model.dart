// ─────────────────────────────────────────────────────────────
//  MODEL  —  job_model.dart
// ─────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

// ── Job Type Enum ────────────────────────────────────────────
enum JobType {
  remote('remote', 'Remote'),
  onsite('onsite', 'On-site'),
  hybrid('hybrid', 'Hybrid');

  final String value;
  final String label;
  const JobType(this.value, this.label);

  static JobType fromString(String s) =>
      JobType.values.firstWhere((e) => e.value == s.toLowerCase(),
          orElse: () => JobType.onsite);
}

// ── Job Status Enum ──────────────────────────────────────────
enum JobStatus {
  open('open', 'Open'),
  closed('closed', 'Closed'),
  paused('paused', 'Paused');

  final String value;
  final String label;
  const JobStatus(this.value, this.label);

  static JobStatus fromString(String s) =>
      JobStatus.values.firstWhere((e) => e.value == s.toLowerCase(),
          orElse: () => JobStatus.open);
}

// ── Application Status Enum ──────────────────────────────────
enum ApplicationStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  final String value;
  final String label;
  const ApplicationStatus(this.value, this.label);

  static ApplicationStatus fromString(String s) =>
      ApplicationStatus.values.firstWhere((e) => e.value == s.toLowerCase(),
          orElse: () => ApplicationStatus.pending);
}

// ── Location ─────────────────────────────────────────────────
class JobLocation {
  final String address;
  final String city;
  final String state;
  final double lat;
  final double lng;

  const JobLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
  });

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    final coords =
        (json['coordinates']?['coordinates'] as List?) ?? [0.0, 0.0];
    return JobLocation(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      lat: (coords[0] as num).toDouble(),
      lng: (coords[1] as num).toDouble(),
    );
  }

  String get displayCity => '$city, $state';
}

// ── Volunteer Job ─────────────────────────────────────────────
class VolunteerJob {
  final String id;
  final String organizationId;
  final String organizationName;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final int positionsAvailable;
  final int positionsFilled;
  final DateTime applicationDeadline;
  final JobType jobType;
  final bool certificateProvided;
  final int creditHours;
  final JobStatus status;
  final JobLocation location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VolunteerJob({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.positionsAvailable,
    required this.positionsFilled,
    required this.applicationDeadline,
    required this.jobType,
    required this.certificateProvided,
    required this.creditHours,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VolunteerJob.fromJson(Map<String, dynamic> json) {
    DateTime dt(String? s) =>
        s != null ? DateTime.tryParse(s) ?? DateTime.now() : DateTime.now();

    return VolunteerJob(
      id: json['_id'] as String? ?? '',
      organizationId: json['organization'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      requiredSkills: (json['requiredSkills'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      positionsAvailable:
          (json['positionsAvailable'] as num?)?.toInt() ?? 0,
      positionsFilled:
          (json['positionsFilled'] as num?)?.toInt() ?? 0,
      applicationDeadline: dt(json['applicationDeadline'] as String?),
      jobType: JobType.fromString(json['jobType'] as String? ?? 'onsite'),
      certificateProvided: json['certificateProvided'] as bool? ?? false,
      creditHours: (json['creditHours'] as num?)?.toInt() ?? 0,
      status: JobStatus.fromString(json['status'] as String? ?? 'open'),
      location: JobLocation.fromJson(
          json['location'] as Map<String, dynamic>? ?? {}),
      createdAt: dt(json['createdAt'] as String?),
      updatedAt: dt(json['updatedAt'] as String?),
    );
  }

  // ── Computed ──────────────────────────────────────────────
  int get positionsLeft =>
      (positionsAvailable - positionsFilled).clamp(0, positionsAvailable);

  double get fillRate => positionsAvailable > 0
      ? (positionsFilled / positionsAvailable * 100).clamp(0, 100)
      : 0;

  bool get isExpired =>
      DateTime.now().isAfter(applicationDeadline);

  int get daysLeft {
    final diff = applicationDeadline.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get deadlineFormatted =>
      DateFormat('MMM dd, yyyy').format(applicationDeadline);
}

// ── Jobs API Response ─────────────────────────────────────────
class VolunteerJobsResponse {
  final bool success;
  final int count;
  final List<VolunteerJob> data;

  const VolunteerJobsResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory VolunteerJobsResponse.fromJson(Map<String, dynamic> json) {
    return VolunteerJobsResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => VolunteerJob.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Create Job Request ────────────────────────────────────────
class CreateJobRequest {
  final String title;
  final String description;
  final String category;
  final String requiredSkills; // comma-separated
  final String address;
  final String city;
  final String state;
  final String coordinates; // "lat,lng"
  final int positionsAvailable;
  final String applicationDeadline; // ISO string
  final String jobType;
  final bool certificateProvided;
  final int creditHours;

  const CreateJobRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.address,
    required this.city,
    required this.state,
    required this.coordinates,
    required this.positionsAvailable,
    required this.applicationDeadline,
    required this.jobType,
    required this.certificateProvided,
    required this.creditHours,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'requiredSkills': requiredSkills,
        'address': address,
        'city': city,
        'state': state,
        'coordinates': coordinates,
        'positionsAvailable': positionsAvailable,
        'applicationDeadline': applicationDeadline,
        'jobType': jobType,
        'certificateProvided': certificateProvided,
        'creditHours': creditHours,
      };
}

// ── Applicant Snapshot ────────────────────────────────────────
class ApplicantSnapshot {
  final String fullName;
  final String email;
  final String? profileImage;
  final String bio;
  final List<String> skills;
  final double rating;
  final int totalVolunteerHours;

  const ApplicantSnapshot({
    required this.fullName,
    required this.email,
    this.profileImage,
    required this.bio,
    required this.skills,
    required this.rating,
    required this.totalVolunteerHours,
  });

  factory ApplicantSnapshot.fromJson(Map<String, dynamic> json) {
    return ApplicantSnapshot(
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      bio: json['bio'] as String? ?? '',
      skills: (json['skills'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalVolunteerHours:
          (json['totalVolunteerHours'] as num?)?.toInt() ?? 0,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ── Job Application ───────────────────────────────────────────
class JobApplication {
  final String id;
  final String jobId;
  final String organizationId;
  final String userId;
  final ApplicationStatus status;
  final String? resumePath;
  final String? resumeOriginalName;
  final String whyHire;
  final List<String> skills;
  final String experience;
  final ApplicantSnapshot applicantSnapshot;
  final int creditHoursGranted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.organizationId,
    required this.userId,
    required this.status,
    this.resumePath,
    this.resumeOriginalName,
    required this.whyHire,
    required this.skills,
    required this.experience,
    required this.applicantSnapshot,
    required this.creditHoursGranted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    DateTime dt(String? s) =>
        s != null ? DateTime.tryParse(s) ?? DateTime.now() : DateTime.now();

    return JobApplication(
      id: json['_id'] as String? ?? '',
      jobId: json['job'] as String? ?? '',
      organizationId: json['organization'] as String? ?? '',
      userId: json['user'] as String? ?? '',
      status: ApplicationStatus.fromString(
          json['status'] as String? ?? 'pending'),
      resumePath: json['resumePath'] as String?,
      resumeOriginalName: json['resumeOriginalName'] as String?,
      whyHire: json['whyHire'] as String? ?? '',
      skills: (json['skills'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      experience: json['experience'] as String? ?? '',
      applicantSnapshot: ApplicantSnapshot.fromJson(
          json['applicantSnapshot'] as Map<String, dynamic>? ?? {}),
      creditHoursGranted:
          (json['creditHoursGranted'] as num?)?.toInt() ?? 0,
      createdAt: dt(json['createdAt'] as String?),
      updatedAt: dt(json['updatedAt'] as String?),
    );
  }
}

// ── Applications API Response ─────────────────────────────────
class JobApplicationsResponse {
  final bool success;
  final int count;
  final List<JobApplication> data;

  const JobApplicationsResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory JobApplicationsResponse.fromJson(Map<String, dynamic> json) {
    return JobApplicationsResponse(
      success: json['success'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) =>
              JobApplication.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Predefined categories ─────────────────────────────────────
const kJobCategories = [
  'Technology', 'Marketing', 'Community Service', 'Education',
  'Health', 'Environment', 'Legal', 'Finance', 'Design',
  'Research', 'Administration', 'Other',
];

// ── Predefined skill suggestions ─────────────────────────────
const kJobSkillSuggestions = [
  'html', 'css', 'javascript', 'python', 'teaching', 'teamwork',
  'communication', 'canva', 'social media management',
  'content writing', 'physical stamina', 'patience', 'leadership',
  'first aid', 'photography', 'fundraising', 'data entry',
];
