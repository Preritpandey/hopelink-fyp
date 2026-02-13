import 'package:dio/dio.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';

class StripeConfig {
  // Cached publishable key (will be fetched from backend at startup)
  static String? publishableKey;

  static Future<String?> fetchPublishableKey() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final res = await dio.get('/payments/config');
      final data = res.data['data'];
      publishableKey = data?['publishableKey'] as String?;
      return publishableKey;
    } catch (e) {
      return null;
    }
  }
}
