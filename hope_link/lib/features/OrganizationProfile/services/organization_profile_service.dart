import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;

import '../../Donate Funds/models/event_model.dart';
import '../../Donate Funds/models/volunteer_job_model.dart';
import '../models/organization_profile_model.dart';

class OrganizationProfileService {
  static const String _cacheBoxName = 'organization_profile_cache';

  Future<OrganizationProfile> fetchProfile(String organizationId) async {
    final response = await http
        .get(Uri.parse(ApiEndpoints.organizationProfile(organizationId)))
        .timeout(const Duration(seconds: 12));

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to load organization');
    }

    return OrganizationProfile.fromJson(
      Map<String, dynamic>.from(jsonData['data'] ?? {}),
    );
  }

  Future<PaginatedOrganizationPosts> fetchPosts(
    String organizationId, {
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '${ApiEndpoints.organizationPosts(organizationId)}?page=$page&limit=$limit',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to load organization posts');
    }

    final posts = (jsonData['data'] as List? ?? [])
        .map((item) => OrganizationPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return PaginatedOrganizationPosts(
      posts: posts,
      page: (jsonData['page'] as num?)?.toInt() ?? page,
      pages: (jsonData['pages'] as num?)?.toInt() ?? 0,
      total: (jsonData['total'] as num?)?.toInt() ?? posts.length,
    );
  }

  Future<Event> fetchEventById(String eventId) async {
    final response = await http
        .get(
          Uri.parse('${ApiEndpoints.events}/$eventId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to load event');
    }

    return Event.fromJson(Map<String, dynamic>.from(jsonData['data'] ?? {}));
  }

  Future<VolunteerJob> fetchVolunteerJobById(String jobId) async {
    final response = await http
        .get(
          Uri.parse('${ApiEndpoints.volunteerJobs}/$jobId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || jsonData['success'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to load volunteer job');
    }

    return VolunteerJob.fromJson(
      Map<String, dynamic>.from(jsonData['data'] ?? {}),
    );
  }

  Future<void> cacheProfile(
    String organizationId,
    OrganizationProfile profile,
  ) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put('profile_$organizationId', json.encode(profile.toJson()));
    await box.put('profile_time_$organizationId', DateTime.now().toIso8601String());
  }

  Future<OrganizationProfile?> getCachedProfile(String organizationId) async {
    final box = await Hive.openBox(_cacheBoxName);
    final raw = box.get('profile_$organizationId');
    if (raw is! String || raw.isEmpty) {
      return null;
    }

    return OrganizationProfile.fromJson(
      Map<String, dynamic>.from(json.decode(raw) as Map<String, dynamic>),
    );
  }

  Future<void> cachePosts(
    String organizationId,
    List<OrganizationPost> posts,
  ) async {
    final box = await Hive.openBox(_cacheBoxName);
    await box.put(
      'posts_$organizationId',
      json.encode(posts.map((post) => post.toJson()).toList()),
    );
    await box.put('posts_time_$organizationId', DateTime.now().toIso8601String());
  }

  Future<List<OrganizationPost>> getCachedPosts(String organizationId) async {
    final box = await Hive.openBox(_cacheBoxName);
    final raw = box.get('posts_$organizationId');
    if (raw is! String || raw.isEmpty) {
      return [];
    }

    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map((item) => OrganizationPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class PaginatedOrganizationPosts {
  final List<OrganizationPost> posts;
  final int page;
  final int pages;
  final int total;

  const PaginatedOrganizationPosts({
    required this.posts,
    required this.page,
    required this.pages,
    required this.total,
  });
}
