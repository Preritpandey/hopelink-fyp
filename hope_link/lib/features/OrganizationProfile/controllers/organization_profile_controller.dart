import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Donate Funds/pages/event_details_page.dart';
import '../../Donate Funds/pages/volunteer_job_details_page.dart';
import '../models/organization_profile_model.dart';
import '../services/organization_profile_service.dart';

class OrganizationProfileController extends GetxController {
  OrganizationProfileController({required this.organizationId});

  final String organizationId;
  final OrganizationProfileService _service = OrganizationProfileService();
  final ScrollController scrollController = ScrollController();

  final Rxn<OrganizationProfile> profile = Rxn<OrganizationProfile>();
  final RxList<OrganizationPost> posts = <OrganizationPost>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxBool hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadOrganizationProfile();
  }

  Future<void> loadOrganizationProfile({bool forceRefresh = false}) async {
    if (organizationId.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'Organization id is missing';
      return;
    }

    try {
      if (!forceRefresh) {
        await _loadFromCache();
      }

      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final results = await Future.wait([
        _service.fetchProfile(organizationId),
        _service.fetchPosts(organizationId, page: 1, limit: 10),
      ]);

      final fetchedProfile = results[0] as OrganizationProfile;
      final fetchedPosts = results[1] as PaginatedOrganizationPosts;

      profile.value = fetchedProfile;
      posts.assignAll(fetchedPosts.posts);
      currentPage.value = fetchedPosts.page;
      totalPages.value = fetchedPosts.pages;
      hasMore.value = fetchedPosts.page < fetchedPosts.pages;

      await _service.cacheProfile(organizationId, fetchedProfile);
      await _service.cachePosts(organizationId, fetchedPosts.posts);
    } catch (e) {
      hasError.value = profile.value == null && posts.isEmpty;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshProfile() async {
    isRefreshing.value = true;
    await loadOrganizationProfile(forceRefresh: true);
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      final nextPage = currentPage.value + 1;
      final response = await _service.fetchPosts(
        organizationId,
        page: nextPage,
        limit: 10,
      );

      posts.addAll(response.posts);
      currentPage.value = response.page;
      totalPages.value = response.pages;
      hasMore.value = response.page < response.pages;

      await _service.cachePosts(organizationId, posts.toList());
    } catch (e) {
      Get.snackbar(
        'Load failed',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> openPost(OrganizationPost post) async {
    try {
      if (post.isCampaign) {
        Get.toNamed('/campaign-details', arguments: post.id);
        return;
      }

      if (post.isEvent) {
        final event = await _service.fetchEventById(post.id);
        Get.to(() => EventDetailsPage(event: event));
        return;
      }

      final job = await _service.fetchVolunteerJobById(post.id);
      Get.to(() => const VolunteerJobDetailsPage(), arguments: job);
    } catch (e) {
      Get.snackbar(
        'Unable to open post',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadFromCache() async {
    final cachedProfile = await _service.getCachedProfile(organizationId);
    final cachedPosts = await _service.getCachedPosts(organizationId);

    if (cachedProfile != null) {
      profile.value = cachedProfile;
    }
    if (cachedPosts.isNotEmpty) {
      posts.assignAll(cachedPosts);
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final threshold = scrollController.position.maxScrollExtent - 220;
    if (scrollController.position.pixels >= threshold) {
      loadMorePosts();
    }
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }
}
