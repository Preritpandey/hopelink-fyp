import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';

import 'auth_session_service.dart';

class ApiClient {
  ApiClient._();

  static Dio create({bool authorized = true}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (authorized) {
            final token = await AuthSessionService.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await AuthSessionService.clearSession();
            if (!(Get.currentRoute == '/login')) {
              Get.offAllNamed('/login');
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static String errorMessage(Object error, {String fallback = 'Something went wrong'}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return fallback;
  }
}
