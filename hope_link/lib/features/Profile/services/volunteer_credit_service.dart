import 'dart:convert';

import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;

import '../models/volunteer_credit_model.dart';

class VolunteerCreditService {
  static Future<VolunteerCreditSummary> getVolunteerCredits(String token) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.volunteerCredits),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message'] ?? 'Failed to load volunteer credits');
    }

    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return VolunteerCreditSummary.fromJson(data);
  }
}
