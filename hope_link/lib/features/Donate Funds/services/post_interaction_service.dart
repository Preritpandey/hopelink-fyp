import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants/api_endpoints.dart';
import '../models/post_interaction_models.dart';

class PostInteractionService {
  final Dio _dio = Dio();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers({bool requireAuth = false}) async {
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

  Future<PostInteractionState> likePost(String postId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.postLike(postId),
        options: Options(headers: await _headers(requireAuth: true)),
      );
      return PostInteractionState.fromJson(response.data['data']);
    } catch (error) {
      throw Exception(_readError(error, 'Unable to like this post'));
    }
  }

  Future<PostInteractionState> unlikePost(String postId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.postUnlike(postId),
        options: Options(headers: await _headers(requireAuth: true)),
      );
      return PostInteractionState.fromJson(response.data['data']);
    } catch (error) {
      throw Exception(_readError(error, 'Unable to unlike this post'));
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.postComments(postId),
        options: Options(headers: await _headers()),
      );
      final data = (response.data['data'] as List?) ?? const [];
      return data
          .whereType<Map>()
          .map((comment) => PostComment.fromJson(Map<String, dynamic>.from(comment)))
          .toList();
    } catch (error) {
      throw Exception(_readError(error, 'Unable to load comments'));
    }
  }

  Future<PostComment> addComment(String postId, String text) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.postComments(postId),
        data: {'text': text},
        options: Options(headers: await _headers(requireAuth: true)),
      );
      return PostComment.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    } catch (error) {
      throw Exception(_readError(error, 'Unable to add comment'));
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete(
        ApiEndpoints.deleteComment(commentId),
        options: Options(headers: await _headers(requireAuth: true)),
      );
    } catch (error) {
      throw Exception(_readError(error, 'Unable to delete comment'));
    }
  }

  Future<bool> hasActiveSession() async {
    final token = await _getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
