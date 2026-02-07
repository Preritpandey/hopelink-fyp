import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants/api_endpoints.dart';
import '../models/event_model.dart';

class EventController extends GetxController {
  final Dio _dio = Dio();

  // Observables
  var events = <Event>[].obs;
  var filteredEvents = <Event>[].obs;
  var isLoading = false.obs;
  var isEnrolling = false.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'all'.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var enrolledEventIds = <String>{}.obs;
  var enrollmentStatusByEventId = <String, String>{}.obs;

  // Hive box
  late Box<Event> eventBox;

  @override
  void onInit() {
    super.onInit();
    initHive();
  }

  Future<void> initHive() async {
    try {
      eventBox = await Hive.openBox<Event>('events');
      loadEventsFromCache();
      fetchEvents();
    } catch (e) {
      print('Error initializing Hive: $e');
      fetchEvents();
    }
  }

  void loadEventsFromCache() {
    if (eventBox.isNotEmpty) {
      events.value = eventBox.values.toList();
      filteredEvents.value = events;
    }
  }

  Future<void> fetchEvents() async {
    try {
      print('Fetching events...');
      isLoading.value = true;
      hasError.value = false;

      final response = await _dio.get(ApiEndpoints.events);
      print(response.data);

      if (response.statusCode == 200) {
        final eventResponse = EventResponse.fromJson(response.data);
        events.value = eventResponse.data;

        // Save to Hive for offline access
        await saveEventsToCache(eventResponse.data);

        applyFilters();
        await fetchMyEnrollments();
      }
    } on DioException catch (e) {
      hasError.value = true;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage.value = 'No internet connection. Showing cached data.';
        loadEventsFromCache();
      } else {
        errorMessage.value = 'Failed to load events: ${e.message}';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'An unexpected error occurred';
      print('Error fetching events: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final response = await _dio.get(
        '${ApiEndpoints.events}/me/enrollments',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('My enrollments response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final enrollments = (data['data'] as List?) ?? [];

        final ids = <String>{};
        final statusMap = <String, String>{};

        for (final item in enrollments) {
          if (item is Map) {
            final event = item['event'];
            final eventId = event is Map ? (event['_id'] ?? '') : '';
            final status = item['status']?.toString().toLowerCase() ?? '';
            if (eventId.isNotEmpty) {
              ids.add(eventId);
              if (status.isNotEmpty) {
                statusMap[eventId] = status;
              }
            }
          }
        }

        enrolledEventIds.value = ids;
        enrollmentStatusByEventId.value = statusMap;
      }
    } catch (e) {
      print('Error fetching my enrollments: $e');
    }
  }

  bool isEnrolled(String eventId) {
    return enrolledEventIds.contains(eventId);
  }

  String? enrollmentStatus(String eventId) {
    return enrollmentStatusByEventId[eventId];
  }

  Future<void> saveEventsToCache(List<Event> eventsList) async {
    try {
      await eventBox.clear();
      for (var event in eventsList) {
        await eventBox.put(event.id, event);
      }
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  void searchEvents(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  void applyFilters() {
    var filtered = events.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            event.description.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            event.category.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // Apply category filter
    if (selectedFilter.value != 'all') {
      if (selectedFilter.value == 'featured') {
        filtered = filtered.where((event) => event.isFeatured).toList();
      } else if (selectedFilter.value == 'active') {
        filtered = filtered
            .where(
              (event) =>
                  event.status == 'published' &&
                  event.startDate.isAfter(DateTime.now()),
            )
            .toList();
      }
    }

    filteredEvents.value = filtered;
  }

  Future<bool> enrollInEvent(String eventId) async {
    try {
      isEnrolling.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) {
        Get.snackbar(
          'Login Required',
          'Please log in to enroll in this event.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }

      final response = await _dio.post(
        '${ApiEndpoints.events}/$eventId/enroll',
        options: Options(
          headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success',
          'Enrollment request sent successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        // Refresh events
        await fetchEvents();
        await fetchMyEnrollments();
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar(
        'Error',
        e.response?.data['message'] ?? 'Failed to enroll in event',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isEnrolling.value = false;
    }
  }

  Future<void> refreshEvents() async {
    await fetchEvents();
  }

  @override
  void onClose() {
    eventBox.close();
    super.onClose();
  }
}
