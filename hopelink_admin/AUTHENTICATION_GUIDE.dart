// ─────────────────────────────────────────────────────────────
// HOPELINK ADMIN — Authentication & Token Management Guide
// ─────────────────────────────────────────────────────────────
// This file demonstrates how to get the bearer token and
// organization ID for authenticated API requests.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// STEP 1: LOGIN & GET TOKEN
// ═══════════════════════════════════════════════════════════════

class AuthenticationExample {
  static const String _baseUrl = 'http://localhost:3008/api/v1';
  static const String _tokenKey = 'auth_token';
  static const String _orgIdKey = 'org_id';
  static const String _orgNameKey = 'org_name';

  /// Login with email and password
  /// Returns: {token, userId, organizationId, organizationName}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/login');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw Exception('Login failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Login failed');
      }

      // Extract authentication data
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      final organization = user['organization'] as Map<String, dynamic>;

      final organizationId = organization['_id'] as String;
      final organizationName = organization['name'] as String;
      final userId = user['_id'] as String;

      // Save to local storage
      await _saveCredentials(
        token: token,
        organizationId: organizationId,
        organizationName: organizationName,
        userId: userId,
      );

      return {
        'success': true,
        'token': token,
        'userId': userId,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'organization': organization,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials({
    required String token,
    required String organizationId,
    required String organizationName,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_orgIdKey, organizationId);
    await prefs.setString(_orgNameKey, organizationName);
    await prefs.setString('user_id', userId);
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2: RETRIEVE TOKEN & ORGANIZATION ID
  // ─────────────────────────────────────────────────────────────

  /// Get stored bearer token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored organization ID
  Future<String?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgIdKey);
  }

  /// Get stored organization name
  Future<String?> getOrganizationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_orgNameKey);
  }

  /// Get all authentication data together
  Future<Map<String, String?>> getAllAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'organizationId': prefs.getString(_orgIdKey),
      'organizationName': prefs.getString(_orgNameKey),
      'userId': prefs.getString('user_id'),
    };
  }

  /// Build authorization header for API requests
  Map<String, String> buildAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 3: USE TOKEN FOR AUTHENTICATED REQUESTS
  // ─────────────────────────────────────────────────────────────

  /// Fetch events for the organization
  Future<Map<String, dynamic>> getOrganizationEvents({
    required String token,
    required String organizationId,
    int page = 1,
    int limit = 10,
    String? category,
    String? status,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/events/organization/$organizationId'
        '?page=$page&limit=$limit'
        '${category != null ? '&category=$category' : ''}'
        '${status != null ? '&status=$status' : ''}',
      );

      final response = await http.get(uri, headers: buildAuthHeaders(token));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch events: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new event for the organization
  Future<Map<String, dynamic>> createEvent({
    required String token,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/events');

      final response = await http.post(
        uri,
        headers: buildAuthHeaders(token),
        body: jsonEncode(eventData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to create event: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update an event
  Future<Map<String, dynamic>> updateEvent({
    required String token,
    required String eventId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/events/$eventId');

      final response = await http.put(
        uri,
        headers: buildAuthHeaders(token),
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update event: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get volunteers for an event
  Future<Map<String, dynamic>> getEventVolunteers({
    required String token,
    required String eventId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/events/$eventId/volunteers?page=$page&limit=$limit',
      );

      final response = await http.get(uri, headers: buildAuthHeaders(token));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch volunteers: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Approve/Reject volunteer for an event
  Future<Map<String, dynamic>> updateVolunteerStatus({
    required String token,
    required String enrollmentId,
    required String status, // 'approved' or 'rejected'
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/events/volunteers/$enrollmentId');

      final response = await http.put(
        uri,
        headers: buildAuthHeaders(token),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update volunteer status: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': true, 'data': data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_orgIdKey);
    await prefs.remove(_orgNameKey);
    await prefs.remove('user_id');
  }
}

// ═══════════════════════════════════════════════════════════════
// USAGE EXAMPLE
// ═══════════════════════════════════════════════════════════════

/*

// Example 1: Login and get token + organization ID
void exampleLogin() async {
  final auth = AuthenticationExample();

  final loginResult = await auth.login(
    email: 'org@example.com',
    password: 'password123',
  );

  if (loginResult['success']) {
    print('✓ Login successful!');
    print('Token: ${loginResult['token']}');
    print('Organization ID: ${loginResult['organizationId']}');
    print('Organization Name: ${loginResult['organizationName']}');
  } else {
    print('✗ Login failed: ${loginResult['error']}');
  }
}

// Example 2: Get stored credentials anytime
void exampleGetStoredCredentials() async {
  final auth = AuthenticationExample();

  final token = await auth.getToken();
  final orgId = await auth.getOrganizationId();
  final orgName = await auth.getOrganizationName();

  print('Token: $token');
  print('Organization ID: $orgId');
  print('Organization Name: $orgName');
}

// Example 3: Fetch events for organization
void exampleFetchOrgEvents() async {
  final auth = AuthenticationExample();

  final token = await auth.getToken();
  final orgId = await auth.getOrganizationId();

  if (token != null && orgId != null) {
    final result = await auth.getOrganizationEvents(
      token: token,
      organizationId: orgId,
      page: 1,
      limit: 10,
      status: 'upcoming',
    );

    if (result['success']) {
      print('✓ Events fetched successfully!');
      print('Response: ${result['data']}');
    } else {
      print('✗ Failed to fetch events: ${result['error']}');
    }
  }
}

// Example 4: Create an event
void exampleCreateEvent() async {
  final auth = AuthenticationExample();
  final token = await auth.getToken();

  if (token != null) {
    final result = await auth.createEvent(
      token: token,
      eventData: {
        'title': 'Community Cleanup Drive',
        'description': 'Join us for a community cleanup',
        'category': 'Environment',
        'eventType': 'one-day',
        'address': 'Main Street',
        'city': 'Kathmandu',
        'state': 'Bagmati',
        'startDate': '2024-05-15',
        'endDate': '2024-05-15',
        'maxVolunteers': 50,
      },
    );

    if (result['success']) {
      print('✓ Event created successfully!');
      print('Event: ${result['data']}');
    } else {
      print('✗ Failed to create event: ${result['error']}');
    }
  }
}

// Example 5: Get all auth data together
void exampleGetAllAuthData() async {
  final auth = AuthenticationExample();

  final authData = await auth.getAllAuthData();
  print('All Auth Data:');
  print(authData);
}

*/
