// ─────────────────────────────────────────────────────────────
// HOPELINK ADMIN — Practical Usage Examples
// ─────────────────────────────────────────────────────────────
// Real-world examples of using token & organization ID in views
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 1: LoginController Pattern (From Codebase)
// ═══════════════════════════════════════════════════════════════

/// This is how the actual app implements login
/// See: lib/features/Auth/controller/login_controller.dart
class LoginControllerExample extends GetxController {
  static const String _baseUrl = 'http://localhost:3008/api/v1';
  static const String _tokenKey = 'auth_token';
  static const String _orgIdKey = 'org_id';
  static const String _orgNameKey = 'org_name';

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // 1. POST to login endpoint
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
        }),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && json['success'] == true) {
        // 2. Extract token
        final token = json['token'] as String;

        // 3. Extract user and organization data
        final user = json['user'] as Map<String, dynamic>;
        final organization = user['organization'] as Map<String, dynamic>;

        final organizationId = organization['_id'] as String;
        final organizationName = organization['name'] as String;

        // 4. Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_orgIdKey, organizationId);
        await prefs.setString(_orgNameKey, organizationName);

        print('✓ Login successful');
        print('Token saved: $token');
        print('Org ID saved: $organizationId');

        // Navigate to dashboard
        Get.offAllNamed('/dashboard');
      } else {
        errorMessage.value = json['message'] ?? 'Login failed';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 2: EventController Pattern (From Codebase)
// ═══════════════════════════════════════════════════════════════

/// This shows how to use the token after login
/// See: lib/features/Event/controllers/event_controller.dart
class EventControllerExample extends GetxController {
  static const String _baseUrl = 'http://localhost:3008/api/v1';

  String _token = '';
  String _organizationId = '';

  final events = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStoredCredentials();
  }

  /// Load token and org ID from SharedPreferences
  Future<void> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    _organizationId = prefs.getString('org_id') ?? '';

    if (_token.isNotEmpty && _organizationId.isNotEmpty) {
      print('✓ Credentials loaded');
      print('Token: $_token');
      print('Org ID: $_organizationId');
    } else {
      print('✗ Missing credentials');
    }
  }

  /// Build authorization headers
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  /// Fetch events for the organization
  Future<void> fetchOrganizationEvents({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    if (_token.isEmpty || _organizationId.isEmpty) {
      errorMsg.value = 'Not authenticated';
      return;
    }

    isLoading.value = true;
    errorMsg.value = '';

    try {
      // Build URL with optional filters
      String url =
          '$_baseUrl/events/organization/$_organizationId?page=$page&limit=$limit';

      if (status != null) {
        url += '&status=$status'; // Filter by: upcoming, ongoing, past
      }

      // Make authenticated request
      final response = await http.get(Uri.parse(url), headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final eventList = data['data'] as List;

        events.value = eventList.cast<Map<String, dynamic>>();

        print('✓ Fetched ${events.length} events');
      } else {
        errorMsg.value = 'Failed to fetch events: ${response.statusCode}';
      }
    } catch (e) {
      errorMsg.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new event
  Future<bool> createEvent({
    required String title,
    required String description,
    required String category,
    required String city,
    required String startDate,
    required int maxVolunteers,
  }) async {
    if (_token.isEmpty) {
      errorMsg.value = 'Not authenticated';
      return false;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events'),
        headers: _authHeaders,
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'city': city,
          'startDate': startDate,
          'maxVolunteers': maxVolunteers,
          'eventType': 'one-day',
          'address': 'Unknown',
          'state': 'Bagmati',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✓ Event created successfully');
        await fetchOrganizationEvents(); // Refresh list
        return true;
      } else {
        errorMsg.value = 'Failed to create event';
        return false;
      }
    } catch (e) {
      errorMsg.value = 'Error: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 3: Using in a Widget/Page
// ═══════════════════════════════════════════════════════════════

class EventListPageExample extends StatelessWidget {
  const EventListPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(EventControllerExample());

    return Scaffold(
      appBar: AppBar(title: const Text('Organization Events')),
      body: Obx(() {
        // Show loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error
        if (controller.errorMsg.isNotEmpty) {
          return Center(child: Text('Error: ${controller.errorMsg.value}'));
        }

        // Show empty state
        if (controller.events.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        // Show list of events
        return ListView.builder(
          itemCount: controller.events.length,
          itemBuilder: (context, index) {
            final event = controller.events[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(event['title'] ?? 'Unknown'),
                subtitle: Text(event['description'] ?? ''),
                trailing: Text(
                  event['startDate']?.toString().split('T')[0] ?? '',
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.fetchOrganizationEvents(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 4: Service Class Pattern (Best Practice)
// ═══════════════════════════════════════════════════════════════

/// A cleaner way to manage API calls
class EventService {
  static const String _baseUrl = 'http://localhost:3008/api/v1';

  /// Get token from storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get organization ID from storage
  static Future<String?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('org_id');
  }

  /// Build auth headers
  static Future<Map<String, String>> buildAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Fetch events for organization
  static Future<List<Map<String, dynamic>>> getOrganizationEvents({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final orgId = await getOrganizationId();
      final headers = await buildAuthHeaders();

      if (orgId == null) {
        throw Exception('Organization ID not found');
      }

      String url =
          '$_baseUrl/events/organization/$orgId?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  /// Get a single event
  static Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final headers = await buildAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to fetch event');
      }
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }

  /// Get event volunteers
  static Future<List<Map<String, dynamic>>> getEventVolunteers(
    String eventId,
  ) async {
    try {
      final headers = await buildAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/events/$eventId/volunteers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch volunteers');
      }
    } catch (e) {
      throw Exception('Error fetching volunteers: $e');
    }
  }

  /// Logout - clear credentials
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('org_id');
    await prefs.remove('org_name');
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLE 5: Using Service in Controller
// ═══════════════════════════════════════════════════════════════

class SimpleEventController extends GetxController {
  final events = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMsg = ''.obs;

  Future<void> fetchEvents() async {
    isLoading.value = true;
    errorMsg.value = '';

    try {
      final result = await EventService.getOrganizationEvents(
        page: 1,
        limit: 10,
        status: 'upcoming',
      );
      events.value = result;
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await EventService.logout();
    Get.offAllNamed('/login');
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK REFERENCE
// ═══════════════════════════════════════════════════════════════

/*

LOGIN FLOW:
1. User enters email & password in LoginPage
2. LoginController sends POST request to /auth/login
3. Backend returns { token, user: { organization: { _id, name } } }
4. LoginController saves:
   - token → SharedPreferences['auth_token']
   - orgId → SharedPreferences['org_id']
   - orgName → SharedPreferences['org_name']

USING TOKEN & ORG ID:
1. Any controller needing API access loads: getToken() + getOrganizationId()
2. Build auth headers: { 'Authorization': 'Bearer $token' }
3. Make API calls: GET /events/organization/$orgId
4. All requests must include Authorization header

KEY FILES TO UNDERSTAND:
- login_controller.dart    ← See how login() saves token
- login_model.dart         ← See LoginUser and LoginOrganization structure
- event_controller.dart    ← See how to load and use token
- api_endpoints.dart       ← Base URL configuration

COMMON ERRORS:
- "Unauthorized 401" → Token missing or expired
- "Not Found 404" → Organization ID incorrect or endpoint wrong
- "Bad Request 400" → Missing required fields in request body

*/
