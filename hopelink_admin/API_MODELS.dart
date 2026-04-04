// ─────────────────────────────────────────────────────────────
// HOPELINK - API Response Structures & Data Models
// ─────────────────────────────────────────────────────────────
// Complete JSON response examples and Dart models
// ─────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════
// 1. LOGIN RESPONSE
// ═══════════════════════════════════════════════════════════════

/*
POST /api/v1/auth/login
Body: {
  "email": "org@example.com",
  "password": "password123"
}

Response (200 OK):
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY2OWMzZjQ1YzEzMzJhMDAxNTAwMDAwMSIsImlhdCI6MTcyMTI3Njc0M30.abcdef1234567890",
  "user": {
    "_id": "669c3f45c133a001500001",
    "name": "John Organization",
    "email": "org@example.com",
    "role": "organization",
    "isVerified": true,
    "isActive": true,
    "organization": {
      "_id": "669def77bcf86cd799439011",     // ← USE THIS FOR API CALLS
      "name": "Hope NGO Foundation",
      "type": "ngo",
      "status": "approved"
    }
  }
}

Response (401 Unauthorized):
{
  "success": false,
  "message": "Invalid credentials"
}
*/

class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponseModel {
  final bool success;
  final String token;
  final UserModel user;

  LoginResponseModel({
    required this.success,
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] as bool,
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "organization", "user", "admin"
  final bool isVerified;
  final bool isActive;
  final OrganizationModel organization;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.organization,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
      organization: OrganizationModel.fromJson(
        json['organization'] as Map<String, dynamic>,
      ),
    );
  }
}

class OrganizationModel {
  final String id; // ← ORGANIZATION ID - USE THIS
  final String name;
  final String type; // "ngo", "charity", "foundation", etc.
  final String status; // "approved", "pending", "rejected"

  OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'type': type,
    'status': status,
  };
}

// ═══════════════════════════════════════════════════════════════
// 2. GET ORGANIZATION EVENTS RESPONSE
// ═══════════════════════════════════════════════════════════════

/*
GET /api/v1/events/organization/669def77bcf86cd799439011?page=1&limit=10

Response (200 OK):
{
  "success": true,
  "count": 3,
  "total": 3,
  "page": 1,
  "pages": 1,
  "organizationId": "669def77bcf86cd799439011",
  "data": [
    {
      "_id": "66a1b2c3d4e5f6g7h8i9j0k1",
      "title": "Community Cleanup Drive",
      "description": "Join us for a community cleanup event",
      "category": "Environment",
      "eventType": "one-day",
      "location": {
        "address": "Main Street",
        "city": "Kathmandu",
        "state": "Bagmati",
        "coordinates": {
          "type": "Point",
          "coordinates": [85.3240, 27.7172]
        }
      },
      "startDate": "2024-05-15T09:00:00.000Z",
      "endDate": "2024-05-15T17:00:00.000Z",
      "maxVolunteers": 50,
      "requiredSkills": ["cleaning", "leadership"],
      "eligibility": "Anyone",
      "organizerType": "Organization",
      "organizer": {
        "_id": "669def77bcf86cd799439011",
        "organizationName": "Hope NGO Foundation",
        "officialEmail": "org@hopengofoundation.com",
        "logo": "https://cdn.example.com/logo.png"
      },
      "images": [
        {
          "url": "https://cdn.example.com/event-1.jpg",
          "publicId": "events/event1_abc123",
          "isPrimary": true
        }
      ],
      "status": "published",
      "createdAt": "2024-05-01T10:00:00.000Z",
      "updatedAt": "2024-05-01T10:00:00.000Z"
    },
    // ... more events
  ]
}
*/

class EventsResponseModel {
  final bool success;
  final int count;
  final int total;
  final int page;
  final int pages;
  final String organizationId;
  final List<EventModel> data;

  EventsResponseModel({
    required this.success,
    required this.count,
    required this.total,
    required this.page,
    required this.pages,
    required this.organizationId,
    required this.data,
  });

  factory EventsResponseModel.fromJson(Map<String, dynamic> json) {
    return EventsResponseModel(
      success: json['success'] as bool,
      count: json['count'] as int,
      total: json['total'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
      organizationId: json['organizationId'] as String,
      data: (json['data'] as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String eventType;
  final LocationModel location;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxVolunteers;
  final List<String> requiredSkills;
  final String eligibility;
  final String organizerType;
  final OrganizerModel organizer;
  final List<ImageModel> images;
  final String status;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.maxVolunteers,
    required this.requiredSkills,
    required this.eligibility,
    required this.organizerType,
    required this.organizer,
    required this.images,
    required this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      eventType: json['eventType'] as String,
      location: LocationModel.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      maxVolunteers: json['maxVolunteers'] as int?,
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      eligibility: json['eligibility'] as String,
      organizerType: json['organizerType'] as String,
      organizer: OrganizerModel.fromJson(
        json['organizer'] as Map<String, dynamic>,
      ),
      images:
          (json['images'] as List?)
              ?.map((e) => ImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String,
    );
  }
}

class LocationModel {
  final String address;
  final String city;
  final String state;

  LocationModel({
    required this.address,
    required this.city,
    required this.state,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }
}

class OrganizerModel {
  final String id;
  final String organizationName;
  final String officialEmail;
  final String? logo;

  OrganizerModel({
    required this.id,
    required this.organizationName,
    required this.officialEmail,
    this.logo,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['_id'] as String,
      organizationName: json['organizationName'] as String? ?? '',
      officialEmail: json['officialEmail'] as String? ?? '',
      logo: json['logo'] as String?,
    );
  }
}

class ImageModel {
  final String url;
  final String publicId;
  final bool isPrimary;

  ImageModel({
    required this.url,
    required this.publicId,
    required this.isPrimary,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      url: json['url'] as String,
      publicId: json['publicId'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. CREATE EVENT REQUEST/RESPONSE
// ═══════════════════════════════════════════════════════════════

/*
POST /api/v1/events
Headers: {
  'Authorization': 'Bearer {token}',
  'Content-Type': 'multipart/form-data'
}

Body (multipart form-data):
- title: "Community Cleanup"
- description: "Help clean the streets..."
- category: "Environment"
- eventType: "one-day"
- address: "Main Street"
- city: "Kathmandu"
- state: "Bagmati"
- coordinates: "85.3240,27.7172"  // lng,lat
- startDate: "2024-05-15T09:00:00.000Z"
- endDate: "2024-05-15T17:00:00.000Z"
- maxVolunteers: "50"
- eligibility: "Anyone"
- requiredSkills: "cleaning,leadership"
- images: [file1.jpg, file2.jpg]

Response (201 Created):
{
  "success": true,
  "data": {
    "_id": "66a1b2c3d4e5f6g7h8i9j0k1",
    "title": "Community Cleanup",
    "description": "Help clean the streets...",
    "category": "Environment",
    // ... all event fields
  }
}
*/

class CreateEventRequestModel {
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
  final String eligibility;
  final String requiredSkills; // comma-separated

  CreateEventRequestModel({
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
    'eligibility': eligibility,
    'requiredSkills': requiredSkills,
  };
}

// ═══════════════════════════════════════════════════════════════
// 4. GET EVENT VOLUNTEERS RESPONSE
// ═══════════════════════════════════════════════════════════════

/*
GET /api/v1/events/{eventId}/volunteers

Response (200 OK):
{
  "success": true,
  "count": 5,
  "total": 10,
  "page": 1,
  "pages": 2,
  "data": [
    {
      "_id": "66a1b2c3d4e5f6g7h8i9j0k2",
      "user": {
        "_id": "66a1b2c3d4e5f6g7h8i9j0k3",
        "name": "John Volunteer",
        "email": "john@example.com",
        "phone": "+977981234567",
        "skills": ["cleaning", "leadership"]
      },
      "event": "66a1b2c3d4e5f6g7h8i9j0k1",
      "status": "pending",  // pending, approved, rejected
      "enrollmentDate": "2024-05-10T10:00:00.000Z",
      "response": "I want to help!"
    }
  ]
}
*/

class VolunteerModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<String> userSkills;
  final String status; // pending, approved, rejected
  final DateTime enrollmentDate;
  final String? response;

  VolunteerModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userSkills,
    required this.status,
    required this.enrollmentDate,
    this.response,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return VolunteerModel(
      id: json['_id'] as String,
      userId: user['_id'] as String,
      userName: user['name'] as String,
      userEmail: user['email'] as String,
      userPhone: user['phone'] as String? ?? '',
      userSkills: List<String>.from(user['skills'] ?? []),
      status: json['status'] as String,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      response: json['response'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK JSON RESPONSE EXAMPLES
// ═══════════════════════════════════════════════════════════════

/*

ERROR RESPONSE (401 Unauthorized):
{
  "success": false,
  "error": {
    "message": "Unauthorized",
    "code": 401,
    "timestamp": "2024-05-15T10:00:00.000Z"
  }
}

ERROR RESPONSE (404 Not Found):
{
  "success": false,
  "error": {
    "message": "Event not found",
    "code": 404,
    "timestamp": "2024-05-15T10:00:00.000Z"
  }
}

ERROR RESPONSE (400 Bad Request):
{
  "success": false,
  "error": {
    "message": "Please provide all required fields",
    "code": 400,
    "timestamp": "2024-05-15T10:00:00.000Z"
  }
}

PAGINATION EXAMPLE:
?page=1&limit=10  → Returns items 1-10
?page=2&limit=10  → Returns items 11-20

STATUS FILTERING:
?status=upcoming  → Events with startDate >= now
?status=ongoing   → Events where startDate <= now AND endDate >= now
?status=past      → Events with endDate < now

*/
