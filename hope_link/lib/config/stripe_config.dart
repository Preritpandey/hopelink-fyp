import 'package:dio/dio.dart';

class StripeConfig {
  // Change baseUrl if your backend runs on a different host.
  // For Android emulator use http://10.0.2.2:3008
  //  static const String baseUrl = 'http://192.168.1.72:3008';
  static const String baseUrl = 'http://10.0.2.2:3008';

  // Cached publishable key (will be fetched from backend at startup)
  static String? publishableKey;

  static Future<String?> fetchPublishableKey() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final res = await dio.get('/api/v1/payments/config');
      final data = res.data['data'];
      publishableKey = data?['publishableKey'] as String?;
      return publishableKey;
    } catch (e) {
      return null;
    }
  }
}
