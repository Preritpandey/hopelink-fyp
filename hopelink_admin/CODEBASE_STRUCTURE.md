# HopeLink Admin Codebase - Authentication & Organization Guide

## 📋 Project Structure

```
hopelink_admin/
├── lib/
│   ├── main.dart                    # App entry point - routes to login or dashboard
│   ├── core/
│   │   └── api_endpoints.dart       # API base URL and endpoint paths
│   └── features/
│       ├── Auth/                    # Authentication feature
│       │   ├── controller/
│       │   │   ├── login_controller.dart          # Login logic
│       │   │   └── organization_controller.dart   # Organization registration
│       │   ├── models/
│       │   │   ├── login_model.dart               # Login response models
│       │   │   └── organization_model.dart        # Organization models
│       │   ├── pages/               # Login/registration UI pages
│       │   └── widgets/             # Auth-related widgets
│       ├── Event/                   # Event management feature
│       │   ├── controllers/
│       │   │   └── event_controller.dart          # Event CRUD operations
│       │   ├── models/
│       │   │   └── event_model.dart               # Event data models
│       │   ├── pages/               # Event UI pages
│       │   └── widgets/             # Event-related widgets
│       ├── Dashboard/               # Dashboard feature
│       ├── Home/                    # Home feature
│       └── ...
└── pubspec.yaml                     # Dependencies (http, shared_preferences, get, etc.)
```

---

## 🔐 How Authentication Works

### 1. **Login Process** (`lib/features/Auth/controller/login_controller.dart`)

```dart
// The LoginController handles:
// 1. Email & password form validation
// 2. POST request to /auth/login endpoint
// 3. Token extraction from response
// 4. Saving token to SharedPreferences
// 5. Extracting organization details from response

// Key data returned from backend:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "user-id-here",
    "name": "John Doe",
    "email": "org@example.com",
    "role": "organization",
    "organization": {
      "_id": "organization-id-here",      // ← ORGANIZATION ID
      "name": "NGO Name",
      "type": "ngo",
      "status": "approved"
    }
  }
}
```

---

## 🔑 Key Components

### **A. Token Storage** (SharedPreferences)
```dart
// Keys used:
const String _tokenKey = 'auth_token';       // Stores JWT token
const String _emailKey = 'saved_email';      // Optional: remember email

// The token is stored as:
// prefs.setString('auth_token', result.token);
```

### **B. Organization ID Extraction**
```dart
// From login response, the organization ID is in:
// response['user']['organization']['_id']

// Example:
final loginResponse = LoginResponse.fromJson(json);
final organizationId = loginResponse.user.organization.id;
// organization.id = "507f1f77bcf86cd799439011"
```

### **C. Models Structure** (`lib/features/Auth/models/login_model.dart`)

```dart
class LoginUser {
  final String id;                    // User ID
  final String name;
  final String email;
  final String role;                  // "organization", "user", etc.
  final bool isVerified;
  final bool isActive;
  final LoginOrganization organization;  // ← Organization details
}

class LoginOrganization {
  final String id;        // ← ORGANIZATION ID (use this for API calls)
  final String name;
  final String type;      // "ngo", "charity", etc.
  final String status;    // "approved", "pending", etc.
}
```

---

## 📡 API Endpoints Reference

### Base URL
```
http://localhost:3008/api/v1
```

### Authentication Endpoints
```
POST   /auth/login                          # Login
POST   /auth/register                       # Register user
GET    /auth/me                             # Get current user profile
```

### Event Endpoints (Require Authorization)
```
GET    /events                              # Get all events
GET    /events/:id                          # Get event by ID
GET    /events/organization/:organizationId # Get events for organization ← NEW
POST   /events                              # Create event (multipart/form-data)
PUT    /events/:id                          # Update event
DELETE /events/:id                          # Delete event

GET    /events/:id/volunteers               # Get volunteers for event
GET    /events/:id/volunteers/approved      # Get approved volunteers
GET    /events/:id/volunteers/rejected      # Get rejected volunteers
PUT    /events/volunteers/:enrollmentId     # Approve/reject volunteer
```

---

## 📝 How to Use Token & Organization ID

### **Step 1: Get Token from Storage**
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
```

### **Step 2: Get Organization ID from Storage**
```dart
// After login, organization ID is available from LoginUser model
// You can save it or extract it from the user object

final prefs = await SharedPreferences.getInstance();
final orgId = prefs.getString('org_id'); // if saved

// Or retrieve from the user model after login
final organizationId = loginUser.organization.id;
```

### **Step 3: Build Auth Headers**
```dart
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};
```

### **Step 4: Make Authenticated Request**
```dart
// Example: Get events for organization
final uri = Uri.parse(
  'http://localhost:3008/api/v1/events/organization/$organizationId'
);

final response = await http.get(
  uri,
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

---

## 📊 Event Controller Example** (`lib/features/Event/controllers/event_controller.dart`)

### Creating an Event
```dart
// How the EventController creates events:

// 1. Load token from SharedPreferences
String _token = '';

@override
void onInit() {
  super.onInit();
  _loadToken();
}

Future<void> _loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString('auth_token') ?? '';
}

// 2. Build auth headers
Map<String, String> get _authHeaders => {
  'Authorization': 'Bearer $_token',
  'Content-Type': 'application/json',
};

// 3. Make the request
final uri = Uri.parse('$_base/events');
final req = http.MultipartRequest('POST', uri)
  ..headers['Authorization'] = 'Bearer $_token';

// Add form fields...
req.fields.addAll({
  'title': titleCtrl.text,
  'description': descCtrl.text,
  // ...
});

// Send request
final streamed = await req.send();
final body = await streamed.stream.bytesToString();
final json = jsonDecode(body) as Map<String, dynamic>;
```

---

## 🎯 Complete Login Example

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<void> loginAndSaveCredentials() async {
  try {
    // 1. Send login request
    final response = await http.post(
      Uri.parse('http://localhost:3008/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'org@example.com',
        'password': 'password123',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed');
    }

    // 2. Parse response
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['token'] as String;
    final user = json['user'] as Map<String, dynamic>;
    final organization = user['organization'] as Map<String, dynamic>;
    
    // 3. Extract important data
    final organizationId = organization['_id'] as String;
    final organizationName = organization['name'] as String;

    // 4. Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('org_id', organizationId);
    await prefs.setString('org_name', organizationName);

    print('✓ Logged in successfully!');
    print('Token: $token');
    print('Organization ID: $organizationId');
    print('Organization Name: $organizationName');

  } catch (e) {
    print('✗ Login error: $e');
  }
}
```

---

## 🚀 Making Authenticated API Calls

```dart
// Get all events for organization
Future<void> fetchOrgEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final orgId = prefs.getString('org_id');

  if (token == null || orgId == null) {
    print('Not authenticated');
    return;
  }

  final response = await http.get(
    Uri.parse(
      'http://localhost:3008/api/v1/events/organization/$orgId?page=1&limit=10'
    ),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Events: ${data['data']}');
  } else {
    print('Failed to fetch events: ${response.body}');
  }
}
```

---

## 💾 SharedPreferences Keys Used in App

| Key | Description | Example |
|-----|-------------|---------|
| `auth_token` | JWT Bearer Token | `eyJhbGciOiJIUzI1NiI...` |
| `saved_email` | User's email (if remember me) | `org@example.com` |
| `org_id` | Organization ID (custom, not in code) | `507f1f77bcf86cd799439011` |
| `org_name` | Organization name (custom, not in code) | `My NGO` |
| `user_id` | User ID (custom, not in code) | `507f1f77bcf86cd799439010` |

---

## ⚠️ Important Notes

1. **Token Expiry**: Make sure to handle token expiration and implement a refresh mechanism
2. **Base URL**: Currently set to `http://localhost:3008/api/v1` in `api_endpoints.dart`
3. **Authorization Header Format**: Always use `Bearer {token}` (space between Bearer and token)
4. **Organization ID**: This is the **organization's unique ID**, not the user ID
5. **Role-based Access**: Organization users have `role: "organization"`

---

## 📚 Relevant Files to Study

1. `lib/main.dart` - Entry point and auth gate
2. `lib/features/Auth/controller/login_controller.dart` - Login implementation
3. `lib/features/Auth/models/login_model.dart` - Data models
4. `lib/core/api_endpoints.dart` - API configuration
5. `lib/features/Event/controllers/event_controller.dart` - How to use token for requests

---

## 🔗 See Also

- **AUTHENTICATION_GUIDE.dart** - Complete working code examples
- Backend Event Endpoint: `/events/organization/:organizationId`
