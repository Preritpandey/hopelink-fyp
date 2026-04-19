import 'post_interaction_models.dart';

class VolunteerJob {
  final String id;
  final String organization;
  final String organizationName;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final int positionsAvailable;
  final int positionsFilled;
  final DateTime applicationDeadline;
  final String jobType; // remote, onsite, hybrid
  final bool certificateProvided;
  final int creditHours;
  final String status; // open, closed
  final JobLocation location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalLikes;
  final bool isLikedByCurrentUser;
  final int commentsCount;

  VolunteerJob({
    required this.id,
    required this.organization,
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
    this.totalLikes = 0,
    this.isLikedByCurrentUser = false,
    this.commentsCount = 0,
  });

  factory VolunteerJob.fromJson(Map<String, dynamic> json) {
    return VolunteerJob(
      id: json['_id'] ?? '',
      organization: json['organization'] ?? '',
      organizationName: json['organizationName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      positionsAvailable: json['positionsAvailable'] ?? 0,
      positionsFilled: json['positionsFilled'] ?? 0,
      applicationDeadline: DateTime.parse(json['applicationDeadline']),
      jobType: json['jobType'] ?? '',
      certificateProvided: json['certificateProvided'] ?? false,
      creditHours: json['creditHours'] ?? 0,
      status: json['status'] ?? '',
      location: JobLocation.fromJson(json['location'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      totalLikes: (json['totalLikes'] ?? 0) is num
          ? (json['totalLikes'] as num).toInt()
          : 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] == true,
      commentsCount: (json['commentsCount'] ?? 0) is num
          ? (json['commentsCount'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organization': organization,
      'organizationName': organizationName,
      'title': title,
      'description': description,
      'category': category,
      'requiredSkills': requiredSkills,
      'positionsAvailable': positionsAvailable,
      'positionsFilled': positionsFilled,
      'applicationDeadline': applicationDeadline.toIso8601String(),
      'jobType': jobType,
      'certificateProvided': certificateProvided,
      'creditHours': creditHours,
      'status': status,
      'location': location.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalLikes': totalLikes,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'commentsCount': commentsCount,
    };
  }

  PostInteractionState get interactionState => PostInteractionState(
    totalLikes: totalLikes,
    isLikedByCurrentUser: isLikedByCurrentUser,
    commentsCount: commentsCount,
  );

  VolunteerJob copyWith({
    String? id,
    String? organization,
    String? organizationName,
    String? title,
    String? description,
    String? category,
    List<String>? requiredSkills,
    int? positionsAvailable,
    int? positionsFilled,
    DateTime? applicationDeadline,
    String? jobType,
    bool? certificateProvided,
    int? creditHours,
    String? status,
    JobLocation? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalLikes,
    bool? isLikedByCurrentUser,
    int? commentsCount,
  }) {
    return VolunteerJob(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      organizationName: organizationName ?? this.organizationName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      positionsAvailable: positionsAvailable ?? this.positionsAvailable,
      positionsFilled: positionsFilled ?? this.positionsFilled,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      jobType: jobType ?? this.jobType,
      certificateProvided: certificateProvided ?? this.certificateProvided,
      creditHours: creditHours ?? this.creditHours,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCurrentUser:
          isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  bool get isOpen => status == 'open';
  bool get hasPositionsAvailable => positionsFilled < positionsAvailable;
  int get remainingPositions => positionsAvailable - positionsFilled;
  bool get isDeadlinePassed => DateTime.now().isAfter(applicationDeadline);
}

class JobLocation {
  final String address;
  final String city;
  final String state;
  final Coordinates coordinates;

  JobLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.coordinates,
  });

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'coordinates': coordinates.toJson(),
    };
  }

  String get fullAddress => '$address, $city, $state';
}

class Coordinates {
  final String type;
  final List<double> coordinates;

  Coordinates({
    required this.type,
    required this.coordinates,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      type: json['type'] ?? 'Point',
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'].map((x) => x.toDouble()))
          : [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
}
