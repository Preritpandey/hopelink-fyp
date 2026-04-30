import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:hope_link/core/services/api_client.dart';

import '../models/volunteer_leaderboard_model.dart';

class VolunteerLeaderboardService {
  VolunteerLeaderboardService._();

  static Future<VolunteerLeaderboardResponse> fetchLeaderboard({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.create().get(
        ApiEndpoints.volunteerCreditsLeaderboard,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected leaderboard response');
      }

      return VolunteerLeaderboardResponse.fromJson(data);
    } catch (error) {
      throw Exception(
        ApiClient.errorMessage(
          error,
          fallback: 'Unable to load leaderboard right now',
        ),
      );
    }
  }
}
