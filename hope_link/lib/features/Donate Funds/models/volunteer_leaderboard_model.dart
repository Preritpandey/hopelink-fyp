class VolunteerLeaderboardEntry {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final int rating;
  final int totalPoints;
  final int totalCreditHours;
  final int rank;

  const VolunteerLeaderboardEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.rating,
    required this.totalPoints,
    required this.totalCreditHours,
    required this.rank,
  });

  factory VolunteerLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return VolunteerLeaderboardEntry(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Volunteer',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      totalCreditHours: (json['totalCreditHours'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class VolunteerLeaderboardPagination {
  final int currentPage;
  final int pageSize;
  final int totalUsers;
  final int totalPages;
  final bool hasMore;

  const VolunteerLeaderboardPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalUsers,
    required this.totalPages,
    required this.hasMore,
  });

  factory VolunteerLeaderboardPagination.fromJson(Map<String, dynamic> json) {
    return VolunteerLeaderboardPagination(
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] == true,
    );
  }
}

class VolunteerLeaderboardResponse {
  final List<VolunteerLeaderboardEntry> leaderboard;
  final VolunteerLeaderboardPagination pagination;

  const VolunteerLeaderboardResponse({
    required this.leaderboard,
    required this.pagination,
  });

  factory VolunteerLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final leaderboard = data['leaderboard'] as List? ?? const [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};

    return VolunteerLeaderboardResponse(
      leaderboard: leaderboard
          .whereType<Map<String, dynamic>>()
          .map(VolunteerLeaderboardEntry.fromJson)
          .toList(),
      pagination: VolunteerLeaderboardPagination.fromJson(pagination),
    );
  }
}
