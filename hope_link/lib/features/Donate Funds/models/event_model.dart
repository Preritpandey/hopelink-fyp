// lib/features/events/models/event_model.dart

import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 10)
class Event {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String eventType;

  @HiveField(5)
  final EventLocation location;

  @HiveField(6)
  final DateTime startDate;

  @HiveField(7)
  final DateTime endDate;

  @HiveField(8)
  final List<EventImage> images;

  @HiveField(9)
  final String status;

  @HiveField(10)
  final int maxVolunteers;

  @HiveField(11)
  final List<String> requiredSkills;

  @HiveField(12)
  final String eligibility;

  @HiveField(13)
  final String organizerType;

  @HiveField(14)
  final EventOrganizer organizer;

  @HiveField(15)
  final List<String> volunteers;

  @HiveField(16)
  final bool isFeatured;

  @HiveField(17)
  final List<String> tags;

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.images,
    required this.status,
    required this.maxVolunteers,
    required this.requiredSkills,
    required this.eligibility,
    required this.organizerType,
    required this.organizer,
    required this.volunteers,
    required this.isFeatured,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      eventType: json['eventType'] ?? '',
      location: EventLocation.fromJson(json['location'] ?? {}),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      images:
          (json['images'] as List?)
              ?.map((img) => EventImage.fromJson(img))
              .toList() ??
          [],
      status: json['status'] ?? '',
      maxVolunteers: json['maxVolunteers'] ?? 0,
      requiredSkills:
          (json['requiredSkills'] as List?)
              ?.map((skill) => skill.toString())
              .toList() ??
          [],
      eligibility: json['eligibility'] ?? '',
      organizerType: json['organizerType'] ?? '',
      organizer: json['organizer'] is String
          ? EventOrganizer(
              id: json['organizer'],
              organizationName: '',
              officialEmail: '',
            )
          : EventOrganizer.fromJson(json['organizer'] ?? {}),
      volunteers:
          (json['volunteers'] as List?)?.map((v) => v.toString()).toList() ??
          [],
      isFeatured: json['isFeatured'] ?? false,
      tags:
          (json['tags'] as List?)?.map((tag) => tag.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      'eventType': eventType,
      'location': location.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'images': images.map((img) => img.toJson()).toList(),
      'status': status,
      'maxVolunteers': maxVolunteers,
      'requiredSkills': requiredSkills,
      'eligibility': eligibility,
      'organizerType': organizerType,
      'organizer': organizer.toJson(),
      'volunteers': volunteers,
      'isFeatured': isFeatured,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get primaryImageUrl {
    final primary = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.isNotEmpty ? images.first : EventImage.empty(),
    );
    return primary.url;
  }

  int get volunteersCount => volunteers.length;
  int get spotsLeft => maxVolunteers - volunteersCount;
  double get progressPercentage =>
      maxVolunteers > 0 ? (volunteersCount / maxVolunteers) * 100 : 0;
}

@HiveType(typeId: 11)
class EventLocation {
  @HiveField(0)
  final String address;

  @HiveField(1)
  final String city;

  @HiveField(2)
  final String state;

  @HiveField(3)
  final EventCoordinates coordinates;

  EventLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.coordinates,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      coordinates: EventCoordinates.fromJson(json['coordinates'] ?? {}),
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

@HiveType(typeId: 12)
class EventCoordinates {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final List<double> coordinates;

  EventCoordinates({required this.type, required this.coordinates});

  factory EventCoordinates.fromJson(Map<String, dynamic> json) {
    return EventCoordinates(
      type: json['type'] ?? 'Point',
      coordinates:
          (json['coordinates'] as List?)
              ?.map((coord) => (coord as num).toDouble())
              .toList() ??
          [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
}

@HiveType(typeId: 13)
class EventImage {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String publicId;

  @HiveField(2)
  final bool isPrimary;

  EventImage({
    required this.url,
    required this.publicId,
    required this.isPrimary,
  });

  factory EventImage.fromJson(Map<String, dynamic> json) {
    return EventImage(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'publicId': publicId, 'isPrimary': isPrimary};
  }

  factory EventImage.empty() {
    return EventImage(url: '', publicId: '', isPrimary: false);
  }
}

@HiveType(typeId: 14)
class EventOrganizer {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String organizationName;

  @HiveField(2)
  final String officialEmail;

  @HiveField(3)
  final String? logo;

  EventOrganizer({
    required this.id,
    required this.organizationName,
    required this.officialEmail,
    this.logo,
  });

  factory EventOrganizer.fromJson(Map<String, dynamic> json) {
    return EventOrganizer(
      id: json['_id'] ?? '',
      organizationName: json['organizationName'] ?? '',
      officialEmail: json['officialEmail'] ?? '',
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organizationName': organizationName,
      'officialEmail': officialEmail,
      'logo': logo,
    };
  }
}

// Response wrapper
class EventResponse {
  final bool success;
  final int count;
  final int total;
  final int page;
  final int pages;
  final List<Event> data;

  EventResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      data:
          (json['data'] as List?)
              ?.map((event) => Event.fromJson(event))
              .toList() ??
          [],
    );
  }
}
