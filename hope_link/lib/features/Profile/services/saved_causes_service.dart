import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants/api_endpoints.dart';
import '../models/saved_cause_model.dart';

class SavedCausesService {
  final Dio _dio = Dio();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final token = await _getAuthToken();
    if (requireAuth && (token == null || token.isEmpty)) {
      throw Exception('Please log in to continue');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _readError(Object error, [String fallback = 'Something went wrong']) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return fallback;
  }

  Future<List<SavedCauseEntry>> fetchSavedCauses() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.savedCauses,
        options: Options(headers: await _headers()),
      );

      final data = (response.data['data'] as List?) ?? const [];
      return data
          .whereType<Map>()
          .map(
            (item) => SavedCauseEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (error) {
      throw Exception(_readError(error, 'Unable to load saved causes'));
    }
  }

  Future<void> saveCause(String postId) async {
    try {
      await _dio.post(
        ApiEndpoints.savedCauseByPost(postId),
        options: Options(headers: await _headers()),
      );
    } catch (error) {
      throw Exception(_readError(error, 'Unable to save this cause'));
    }
  }

  Future<void> unsaveCause(String postId) async {
    try {
      await _dio.delete(
        ApiEndpoints.savedCauseByPost(postId),
        options: Options(headers: await _headers()),
      );
    } catch (error) {
      throw Exception(_readError(error, 'Unable to remove this saved cause'));
    }
  }
}
