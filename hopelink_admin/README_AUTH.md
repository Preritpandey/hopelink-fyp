# HopeLink Admin - Complete Authentication Guide

## 📚 Quick Summary

This guide shows you how to:
1. **Get a Bearer Token** - Login with email/password
2. **Get Organization ID** - Extract from login response
3. **Use both** - Make authenticated API requests to the backend

---

## 📁 Reference Files Created

### 1. **AUTHENTICATION_GUIDE.dart** 
Complete, production-ready code with all methods:
- `login()` - Authenticate user
- `getToken()` - Retrieve stored token
- `getOrganizationId()` - Retrieve stored org ID
- `getOrganizationEvents()` - Fetch org events
- `createEvent()` - Create new event
- `updateEvent()` - Update event
- `getEventVolunteers()` - Get volunteers
- `updateVolunteerStatus()` - Approve/reject volunteers

**Use this file to**: Copy-paste working code into your app

---

### 2. **CODEBASE_STRUCTURE.md**
Overview of the entire hopelink_admin project:
- Project folder structure
- How authentication works
- Key components breakdown
- API endpoints reference
- SharedPreferences keys used
- Important notes and warnings

**Use this file to**: Understand the codebase architecture

---

### 3. **USAGE_EXAMPLES.dart**
Real-world implementation examples:
- LoginControllerExample (actual login flow)
- EventControllerExample (using token for API calls)
- EventListPageExample (UI widget example)
- EventService (best practice service class)
- SimpleEventController (clean implementation)

**Use this file to**: See how the actual app code works

---

### 4. **API_MODELS.dart**
Complete Dart models with JSON mapping:
- LoginRequest/Response models
- UserModel with OrganizationModel
- EventModel and related models
- EventResponse models
- VolunteerModel
- Example JSON responses

**Use this file to**: Understand data structures and API responses

---

## 🚀 Quick Start (3 Steps)

### Step 1: Login
```dart
final auth = AuthenticationExample();

final result = await auth.login(
  email: 'org@example.com',
  password: 'password123',
);

if (result['success']) {
  final token = result['token'];
  final organizationId = result['organizationId'];
  print('✓ Login successful!');
  print('Token: $token');
  print('Org ID: $organizationId');
}
```

### Step 2: Get Token & Org ID (Anytime)
```dart
final auth = AuthenticationExample();

final token = await auth.getToken();
final organizationId = await auth.getOrganizationId();

print('Token: $token');
print('Org ID: $organizationId');
```

### Step 3: Use Token for API Calls
```dart
final auth = AuthenticationExample();

final result = await auth.getOrganizationEvents(
  token: token,
  organizationId: organizationId,
  page: 1,
  limit: 10,
  status: 'upcoming',
);

if (result['success']) {
  print('✓ Events fetched!');
  print(result['data']);
}
```

---

## 🔑 Key Concepts

### Bearer Token
A JWT token used for authentication:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Organization ID
The unique identifier for your organization, obtained from login response:
```
{
  "user": {
    "organization": {
      "_id": "669def77bcf86cd799439011"  ← This is Organization ID
    }
  }
}
```

### Storage
Both token and organization ID are stored in SharedPreferences:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);        // Stores token
await prefs.setString('org_id', organizationId);   // Stores org ID
```

---

## 📡 Main API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/auth/login` | Login and get token |
| GET | `/events/organization/:orgId` | Get org's events ✅ NEW |
| POST | `/events` | Create new event |
| GET | `/events/:id` | Get single event |
| PUT | `/events/:id` | Update event |
| GET | `/events/:id/volunteers` | Get event volunteers |
| PUT | `/events/volunteers/:enrollmentId` | Approve/reject volunteer |

**Base URL**: `http://localhost:3008/api/v1`

All endpoints (except `/auth/login`) require:
```
Authorization: Bearer {token}
```

---

## 🔐 Authentication Flow Diagram

```
┌─────────────────┐
│   User Login    │
│  (Email/Pass)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ POST /auth/login                    │
│ Body: {email, password}             │
└────────┬────────────────────────────┘
         │
         ▼ 200 OK
┌─────────────────────────────────────┐
│ Response:                           │
│ {                                   │
│   "token": "jwt...",               │
│   "user": {                         │
│     "organization": {               │
│       "_id": "org-id"  ← SAVE THIS  │
│     }                               │
│   }                                 │
│ }                                   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Save to SharedPreferences:          │
│ - auth_token = "jwt..."             │
│ - org_id = "org-id"                 │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ API Request with Token:             │
│ GET /events/organization/org-id     │
│ Header: Authorization: Bearer jwt..│
└─────────────────────────────────────┘
```

---

## 💡 Common Use Cases

### 1. Check if User is Logged In
```dart
final token = await auth.getToken();
final isLoggedIn = token != null && token.isNotEmpty;
```

### 2. Get Organization Events
```dart
final result = await auth.getOrganizationEvents(
  token: token,
  organizationId: orgId,
  page: 1,
  limit: 10,
);
```

### 3. Create Event for Organization
```dart
await auth.createEvent(
  token: token,
  eventData: {
    'title': 'Community Cleanup',
    'description': 'Help clean the streets',
    'category': 'Environment',
    'city': 'Kathmandu',
    'startDate': '2024-05-15',
  },
);
```

### 4. Get Event Volunteers
```dart
final result = await auth.getEventVolunteers(
  token: token,
  eventId: eventId,
  page: 1,
);
```

### 5. Approve/Reject Volunteer
```dart
await auth.updateVolunteerStatus(
  token: token,
  enrollmentId: enrollmentId,
  status: 'approved', // or 'rejected'
);
```

### 6. Logout
```dart
await auth.logout();
// All credentials cleared from SharedPreferences
```

---

## 🐛 Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Missing or expired token | Login again |
| 404 Not Found | Wrong org ID or endpoint | Check organization ID |
| 400 Bad Request | Missing fields | Check API request body |
| No connection | Network issue | Check internet/CORS |

---

## 📚 Files Overview

```
hopelink_admin/
├── AUTHENTICATION_GUIDE.dart    ← Production-ready code
├── CODEBASE_STRUCTURE.md        ← Project overview
├── USAGE_EXAMPLES.dart          ← Real examples
├── API_MODELS.dart              ← Data models
├── lib/
│   ├── main.dart                ← App entry point
│   ├── core/
│   │   └── api_endpoints.dart   ← Base URL config
│   └── features/
│       ├── Auth/                ← Login here
│       │   ├── controller/login_controller.dart
│       │   └── models/login_model.dart
│       └── Event/               ← Events here
│           ├── controllers/event_controller.dart
│           └── models/event_model.dart
└── pubspec.yaml                 ← Dependencies
```

---

## ✅ Checklist

Before making API calls:
- [ ] User is logged in (token exists)
- [ ] Organization ID is available
- [ ] Token is in `Authorization: Bearer {token}` format
- [ ] Organization ID is correct format (24-char ObjectId)
- [ ] API endpoint URL is correct
- [ ] All required fields are in request body
- [ ] Content-Type header is set correctly

---

## 🔗 Additional Resources

- **Backend GitHub**: Check hopelink backend for API details
- **Flutter Docs**: https://flutter.dev/docs
- **Dart HTTP Package**: https://pub.dev/packages/http
- **SharedPreferences**: https://pub.dev/packages/shared_preferences

---

## 📞 Quick Reference

**Getting Token**:
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
```

**Getting Organization ID**:
```dart
final prefs = await SharedPreferences.getInstance();
final orgId = prefs.getString('org_id');
```

**Making Auth Request**:
```dart
final response = await http.get(
  Uri.parse('$baseUrl/events/organization/$orgId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

**Response Status Codes**:
- 200 - OK (success)
- 201 - Created (resource created)
- 400 - Bad Request (invalid data)
- 401 - Unauthorized (missing/invalid token)
- 404 - Not Found (resource doesn't exist)
- 500 - Server Error

---

## 🎯 Next Steps

1. **Read**: CODEBASE_STRUCTURE.md for project overview
2. **Review**: API_MODELS.dart to understand data structures
3. **Study**: USAGE_EXAMPLES.dart to see real patterns
4. **Copy**: Code from AUTHENTICATION_GUIDE.dart into your app
5. **Test**: Make a login request and verify token retrieval
6. **Implement**: Use token for authenticated API calls

---

**Last Updated**: April 4, 2026
**Version**: 1.0
**Status**: Complete ✅
