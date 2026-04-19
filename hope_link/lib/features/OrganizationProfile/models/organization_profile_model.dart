class OrganizationProfile {
  final String id;
  final String name;
  final String description;
  final String? profileImage;
  final String location;
  final String website;
  final int campaignsCount;
  final int eventsCount;
  final int volunteerJobsCount;
  final int totalPosts;

  const OrganizationProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.profileImage,
    required this.location,
    required this.website,
    required this.campaignsCount,
    required this.eventsCount,
    required this.volunteerJobsCount,
    required this.totalPosts,
  });

  factory OrganizationProfile.fromJson(Map<String, dynamic> json) {
    final counts = Map<String, dynamic>.from(json['counts'] ?? {});

    return OrganizationProfile(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['organizationName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
      location: (json['location'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      campaignsCount: (counts['campaigns'] as num?)?.toInt() ?? 0,
      eventsCount: (counts['events'] as num?)?.toInt() ?? 0,
      volunteerJobsCount: (counts['volunteerJobs'] as num?)?.toInt() ?? 0,
      totalPosts: (counts['totalPosts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'profileImage': profileImage,
      'location': location,
      'website': website,
      'counts': {
        'campaigns': campaignsCount,
        'events': eventsCount,
        'volunteerJobs': volunteerJobsCount,
        'totalPosts': totalPosts,
      },
    };
  }
}

class OrganizationPost {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime createdAt;
  final String? image;

  const OrganizationPost({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.image,
  });

  factory OrganizationPost.fromJson(Map<String, dynamic> json) {
    return OrganizationPost(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'image': image,
    };
  }

  bool get isCampaign => type == 'campaign';
  bool get isEvent => type == 'event';
  bool get isVolunteer => type == 'volunteer';
}
