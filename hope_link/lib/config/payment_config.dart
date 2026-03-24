import 'package:dio/dio.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';

class PaymentConfig {
  static String? stripePublishableKey;
  static String? khaltiPublicKey;
  static String currency = 'npr';

  static Future<void> fetch() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final res = await dio.get('/payments/config');
      final data = res.data['data'];
      stripePublishableKey = data?['publishableKey'] as String?;
      khaltiPublicKey = data?['khaltiPublicKey'] as String?;
      currency = (data?['currency'] as String?)?.toLowerCase() ?? 'npr';
    } catch (_) {
      // Keep defaults if config fetch fails.
    }
  }
}
