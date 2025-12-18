import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants/api_endpoints.dart';

class NetworkManager extends GetxController {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  String? _token;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
    _setupInterceptors();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (dio.DioError e, handler) async {
          if (e.response?.statusCode == 401) {
            // Handle unauthorized error (e.g., logout user)
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            // Navigate to login screen
            // Get.offAllNamed('/login');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(dio.DioException e) {
    String message = 'An error occurred';
    if (e.response?.data != null && e.response?.data is Map) {
      message = e.response?.data['message'] ?? message;
    } else if (e.message != null) {
      message = e.message!;
    }
    throw Exception(message);
  }

  // Helper method to create FormData for file uploads
  static dio.FormData createFormData(Map<String, dynamic> data) {
    final formData = dio.FormData();
    data.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          formData.files.add(
            MapEntry(
              key,
              dio.MultipartFile.fromFileSync(
                item.path,
                filename: item.path.split('/').last,
              ),
            ),
          );
        }
      } else if (value is String) {
        formData.fields.add(MapEntry(key, value));
      } else if (value != null) {
        formData.files.add(
          MapEntry(
            key,
            dio.MultipartFile.fromFileSync(
              value.path,
              filename: value.path.split('/').last,
            ),
          ),
        );
      }
    });
    return formData;
  }
}
