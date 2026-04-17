enum EventCategory {
  education('education', 'Education'),
  health('health', 'Health'),
  environment('environment', 'Environment'),
  humanRights('human-rights', 'Human Rights'),
  disasterRelief('disaster-relief', 'Disaster Relief'),
  womenEmpowerment('women-empowerment', 'Women Empowerment'),
  youthDevelopment('youth-development', 'Youth Development'),
  animalWelfare('animal-welfare', 'Animal Welfare'),
  communityService('community-service', 'Community Service'),
  other('other', 'Other');

  final String value;
  final String label;
  const EventCategory(this.value, this.label);

  static EventCategory fromValue(String v) => EventCategory.values.firstWhere(
    (e) => e.value == v,
    orElse: () => EventCategory.other,
  );
}

enum EventType {
  oneDay('one-day', 'One Day'),
  multiDay('multi-day', 'Multi Day'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  ongoing('ongoing', 'Ongoing');

  final String value;
  final String label;
  const EventType(this.value, this.label);

  static EventType fromValue(String v) => EventType.values.firstWhere(
    (e) => e.value == v,
    orElse: () => EventType.oneDay,
  );
}

// ── Create Event Request ──────────────────────────────────────
class CreateEventRequest {
  final String title;
  final String description;
  final String category;
  final String eventType;
  final String address;
  final String city;
  final String state;
  final String coordinates; // "lng,lat"
  final String startDate;
  final String endDate;
  final int maxVolunteers;
  final int creditHours;
  final String eligibility;
  final String requiredSkills; // comma-separated

  const CreateEventRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.address,
    required this.city,
    required this.state,
    required this.coordinates,
    required this.startDate,
    required this.endDate,
    required this.maxVolunteers,
    required this.creditHours,
    required this.eligibility,
    required this.requiredSkills,
  });

  Map<String, String> toFormFields() => {
    'title': title,
    'description': description,
    'category': category,
    'eventType': eventType,
    'address': address,
    'city': city,
    'state': state,
    'coordinates': coordinates,
    'startDate': startDate,
    'endDate': endDate,
    'maxVolunteers': maxVolunteers.toString(),
    'creditHours': creditHours.toString(),
    'eligibility': eligibility,
    'requiredSkills': requiredSkills,
  };
}

// ── Event Location ────────────────────────────────────────────
class EventLocation {
  final String address;
  final String city;
  final String state;
  final List<double> coordinates; // [lng, lat]

  const EventLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.coordinates,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final coordList =
        (coords?['coordinates'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [0.0, 0.0];
    return EventLocation(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      coordinates: coordList,
    );
  }
}

// ── Creator Info ──────────────────────────────────────────────
class CreatorInfo {
  final String id;
  final String type;

  const CreatorInfo({required this.id, required this.type});

  factory CreatorInfo.fromJson(Map<String, dynamic> json) {
    return CreatorInfo(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

// ── Event Model ───────────────────────────────────────────────
class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final String eventType;
  final EventLocation location;
  final String startDate;
  final String endDate;
  final List<String> images;
  final String status;
  final int maxVolunteers;
  final List<String> requiredSkills;
  final String eligibility;
  final String organizerType;
  final bool isFeatured;
  final List<String> tags;
  final String createdAt;
  final String updatedAt;
  final CreatorInfo? creatorInfo;

  const Event({
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
    required this.isFeatured,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.creatorInfo,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      location: EventLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'ongoing',
      maxVolunteers: (json['maxVolunteers'] as num?)?.toInt() ?? 0,
      requiredSkills:
          (json['requiredSkills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      eligibility: json['eligibility'] as String? ?? '',
      organizerType: json['organizerType'] as String? ?? 'Organization',
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      creatorInfo: json['creatorInfo'] != null
          ? CreatorInfo.fromJson(json['creatorInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Create Event Response ─────────────────────────────────────
class CreateEventResponse {
  final bool success;
  final Event data;

  const CreateEventResponse({required this.success, required this.data});

  factory CreateEventResponse.fromJson(Map<String, dynamic> json) {
    return CreateEventResponse(
      success: json['success'] as bool,
      data: Event.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

// ── Predefined skill suggestions ─────────────────────────────
const kSkillSuggestions = [
  'cleaning',
  'teamwork',
  'communication',
  'leadership',
  'first-aid',
  'teaching',
  'cooking',
  'driving',
  'photography',
  'fundraising',
  'legal',
  'medical',
  'carpentry',
  'IT support',
];

// ── Predefined eligibility options ───────────────────────────
const kEligibilityOptions = [
  'Anyone',
  '18+ years',
  '16+ years',
  'Students only',
  'Professionals only',
  'Females only',
  'Males only',
  'Local residents only',
];
