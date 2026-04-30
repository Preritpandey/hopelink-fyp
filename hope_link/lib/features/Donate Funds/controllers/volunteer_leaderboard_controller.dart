import 'package:get/get.dart';

import '../models/volunteer_leaderboard_model.dart';
import '../services/volunteer_leaderboard_service.dart';

class VolunteerLeaderboardController extends GetxController {
  VolunteerLeaderboardController({this.pageSize = 3});

  final int pageSize;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasLoaded = false.obs;
  final errorMessage = ''.obs;
  final entries = <VolunteerLeaderboardEntry>[].obs;
  final pagination = Rxn<VolunteerLeaderboardPagination>();

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboard();
  }

  bool get hasMore => pagination.value?.hasMore ?? false;

  Future<void> fetchLeaderboard({bool refresh = false}) async {
    final page = refresh ? 1 : 1;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await VolunteerLeaderboardService.fetchLeaderboard(
        page: page,
        pageSize: pageSize,
      );

      entries.assignAll(response.leaderboard);
      pagination.value = response.pagination;
      hasLoaded.value = true;
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      hasLoaded.value = true;
      entries.clear();
      pagination.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshLeaderboard() async {
    await fetchLeaderboard(refresh: true);
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;

    final nextPage = (pagination.value?.currentPage ?? 1) + 1;

    try {
      isLoadingMore.value = true;
      errorMessage.value = '';

      final response = await VolunteerLeaderboardService.fetchLeaderboard(
        page: nextPage,
        pageSize: pageSize,
      );

      entries.addAll(response.leaderboard);
      pagination.value = response.pagination;
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
