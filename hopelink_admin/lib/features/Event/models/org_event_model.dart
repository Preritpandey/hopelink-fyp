// ─────────────────────────────────────────────────────────────
//  MODEL  —  org_event_model.dart
// ─────────────────────────────────────────────────────────────

// ── Image ─────────────────────────────────────────────────────
class OrgEventImage {
  final String url;
  final String publicId;
  final bool isPrimary;
  final String id;

  const OrgEventImage({
    required this.url,
    required this.publicId,
    required this.isPrimary,
    required this.id,
  });

  factory OrgEventImage.fromJson(Map<String, dynamic> json) {
    return OrgEventImage(
      url:       json['url']       as String? ?? '',
      publicId:  json['publicId']  as String? ?? '',
      isPrimary: json['isPrimary'] as bool?   ?? false,
      id:        json['_id']       as String? ?? '',
    );
  }
}

// ── Organizer (embedded) ──────────────────────────────────────
class OrgEventOrganizer {
  final String id;
  final String organizationName;
  final String officialEmail;
  final String? logo;

  const OrgEventOrganizer({
    required this.id,
    required this.organizationName,
    required this.officialEmail,
    this.logo,
  });

  factory OrgEventOrganizer.fromJson(Map<String, dynamic> json) {
    return OrgEventOrganizer(
      id:               json['_id']              as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      officialEmail:    json['officialEmail']    as String? ?? '',
      logo:             json['logo']             as String?,
    );
  }
}

// ── Location ─────────────────────────────────────────────────
class OrgEventLocation {
  final String address;
  final String city;
  final String state;
  final double lng;
  final double lat;

  const OrgEventLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.lng,
    required this.lat,
  });

  factory OrgEventLocation.fromJson(Map<String, dynamic> json) {
    final coords =
        (json['coordinates']?['coordinates'] as List?) ?? [0.0, 0.0];
    return OrgEventLocation(
      address: json['address'] as String? ?? '',
      city:    json['city']    as String? ?? '',
      state:   json['state']   as String? ?? '',
      lng:     (coords[0] as num).toDouble(),
      lat:     (coords[1] as num).toDouble(),
    );
  }

  String get displayCity => '$city, $state';
}

// ── Org Event ────────────────────────────────────────────────
class OrgEvent {
  final String id;
  final String title;
  final String description;
  final String category;
  final String eventType;
  final OrgEventLocation location;
  final DateTime startDate;
  final DateTime endDate;
  final List<OrgEventImage> images;
  final String status;
  final int maxVolunteers;
  final List<String> requiredSkills;
  final String eligibility;
  final String organizerType;
  final OrgEventOrganizer organizer;
  final List<String> volunteers;
  final bool isFeatured;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrgEvent({
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

  factory OrgEvent.fromJson(Map<String, dynamic> json) {
    DateTime _parse(String? s) {
      if (s == null) return DateTime.now();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    return OrgEvent(
      id:          json['_id']          as String? ?? '',
      title:       json['title']        as String? ?? '',
      description: json['description']  as String? ?? '',
      category:    json['category']     as String? ?? '',
      eventType:   json['eventType']    as String? ?? '',
      location:    OrgEventLocation.fromJson(
          json['location'] as Map<String, dynamic>? ?? {}),
      startDate:   _parse(json['startDate'] as String?),
      endDate:     _parse(json['endDate']   as String?),
      images: (json['images'] as List? ?? [])
          .map((e) => OrgEventImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      status:        json['status']        as String? ?? 'published',
      maxVolunteers: (json['maxVolunteers'] as num?)?.toInt() ?? 0,
      requiredSkills: (json['requiredSkills'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      eligibility:  json['eligibility']  as String? ?? '',
      organizerType: json['organizerType'] as String? ?? 'Organization',
      organizer: OrgEventOrganizer.fromJson(
          json['organizer'] as Map<String, dynamic>? ?? {}),
      volunteers: (json['volunteers'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: _parse(json['createdAt'] as String?),
      updatedAt: _parse(json['updatedAt'] as String?),
    );
  }

  // ── Computed ─────────────────────────────────────────────
  OrgEventImage? get primaryImage {
    if (images.isEmpty) return null;
    return images.firstWhere((i) => i.isPrimary, orElse: () => images.first);
  }

  bool get hasImages => images.isNotEmpty;
  int get volunteerCount => volunteers.length;

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isPast     => DateTime.now().isAfter(endDate);

  List<String> get parsedSkills {
    final all = <String>[];
    for (final s in requiredSkills) {
      all.addAll(s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    return all;
  }
}

// ── API List Response ────────────────────────────────────────
class OrgEventsResponse {
  final bool success;
  final int count;
  final int total;
  final int page;
  final int pages;
  final String organizationId;
  final List<OrgEvent> data;

  const OrgEventsResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.organizationId,
    required this.data,
  });

  factory OrgEventsResponse.fromJson(Map<String, dynamic> json) {
    return OrgEventsResponse(
      success:        json['success']        as bool?   ?? false,
      count:          (json['count']          as num?)?.toInt() ?? 0,
      total:          (json['total']          as num?)?.toInt() ?? 0,
      page:           (json['page']           as num?)?.toInt() ?? 1,
      pages:          (json['pages']          as num?)?.toInt() ?? 1,
      organizationId: json['organizationId'] as String? ?? '',
      data: (json['data'] as List? ?? [])
          .map((e) => OrgEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Status helpers ────────────────────────────────────────────
extension OrgEventStatusX on String {
  String get statusLabel {
    switch (toLowerCase()) {
      case 'published': return 'Published';
      case 'ongoing':   return 'Ongoing';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'draft':     return 'Draft';
      default:          return this;
    }
  }
}

// ── Filter options ────────────────────────────────────────────
enum OrgEventFilter { all, published, ongoing, completed, cancelled }

extension OrgEventFilterX on OrgEventFilter {
  String get label {
    switch (this) {
      case OrgEventFilter.all:       return 'All';
      case OrgEventFilter.published: return 'Published';
      case OrgEventFilter.ongoing:   return 'Ongoing';
      case OrgEventFilter.completed: return 'Completed';
      case OrgEventFilter.cancelled: return 'Cancelled';
    }
  }

  String? get statusValue {
    if (this == OrgEventFilter.all) return null;
    return name;
  }
}

// ── View mode ─────────────────────────────────────────────────
enum EventViewMode { grid, list }
