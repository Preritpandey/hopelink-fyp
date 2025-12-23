import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';

class CampaignController extends GetxController {
  final CampaignService _service = CampaignService();

  // Observable lists
  final RxList<Campaign> campaigns = <Campaign>[].obs;
  final RxList<Campaign> filteredCampaigns = <Campaign>[].obs;

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isOfflineMode = false.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, active, featured

  @override
  void onInit() {
    super.onInit();
    loadCampaigns();
  }

  /// Load campaigns with offline support
  Future<void> loadCampaigns({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;

      // Check if we should use cached data
      final isStale = await _service.isDataStale();

      if (!forceRefresh && !isStale) {
        // Load from cache if data is fresh
        final cachedCampaigns = await _service.getCampaignsFromLocal();
        if (cachedCampaigns.isNotEmpty) {
          campaigns.value = cachedCampaigns;
          filteredCampaigns.value = cachedCampaigns;
          isOfflineMode.value = false;
          lastSyncTime.value = await _service.getLastSyncTime();
          applyFilters();
          return;
        }
      }

      // Try to fetch from API
      final fetchedCampaigns = await _service.fetchCampaigns();
      campaigns.value = fetchedCampaigns;
      filteredCampaigns.value = fetchedCampaigns;
      isOfflineMode.value = false;
      lastSyncTime.value = DateTime.now();

      applyFilters();

      // Show success message if force refresh
      if (forceRefresh) {
        Get.snackbar(
          'Success',
          'Campaigns updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      print('Error in loadCampaigns: $e');

      // Load from local storage if API fails
      final cachedCampaigns = await _service.getCampaignsFromLocal();
      campaigns.value = cachedCampaigns;
      filteredCampaigns.value = cachedCampaigns;
      isOfflineMode.value = true;
      lastSyncTime.value = await _service.getLastSyncTime();

      // Show offline mode notification
      Get.snackbar(
        'Offline Mode',
        'Using cached data. Pull to refresh when online.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.white),
      );

      applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  /// Search campaigns by title, description, or organization
  void searchCampaigns(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  /// Set filter for campaigns
  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  /// Apply all filters (search + status filter)
  void applyFilters() {
    var filtered = campaigns.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((campaign) {
        final titleMatch = campaign.title.toLowerCase().contains(query);
        final descMatch = campaign.description.toLowerCase().contains(query);
        final orgMatch = campaign.organization.organizationName
            .toLowerCase()
            .contains(query);

        return titleMatch || descMatch || orgMatch;
      }).toList();
    }

    // Apply status filter
    switch (selectedFilter.value) {
      case 'active':
        filtered = filtered.where((c) => c.isActive).toList();
        break;
      case 'featured':
        filtered = filtered.where((c) => c.isFeatured).toList();
        break;
      case 'all':
      default:
        // No additional filtering
        break;
    }

    filteredCampaigns.value = filtered;
  }

  /// Get campaign by ID with caching
  Future<Campaign?> getCampaignById(String id) async {
    try {
      return await _service.getCampaignById(id);
    } catch (e) {
      print('Error getting campaign by ID: $e');
      Get.snackbar(
        'Error',
        'Failed to load campaign details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return null;
    }
  }

  /// Refresh campaigns (force refresh from API)
  Future<void> refreshCampaigns() async {
    await loadCampaigns(forceRefresh: true);
  }

  /// Clear search and filters
  void clearFilters() {
    searchQuery.value = '';
    selectedFilter.value = 'all';
    applyFilters();
  }

  /// Get active campaigns count
  int get activeCampaignsCount {
    return campaigns.where((c) => c.isActive).length;
  }

  /// Get featured campaigns count
  int get featuredCampaignsCount {
    return campaigns.where((c) => c.isFeatured).length;
  }

  /// Get total campaigns count
  int get totalCampaignsCount {
    return campaigns.length;
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _service.clearCache();
      campaigns.clear();
      filteredCampaigns.clear();
      lastSyncTime.value = null;

      Get.snackbar(
        'Cache Cleared',
        'All cached data has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      // Reload campaigns
      await loadCampaigns(forceRefresh: true);
    } catch (e) {
      print('Error clearing cache: $e');
      Get.snackbar(
        'Error',
        'Failed to clear cache',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Get cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    final cacheSize = await _service.getCacheSize();
    final lastSync = await _service.getLastSyncTime();
    final isStale = await _service.isDataStale();

    return {'cacheSize': cacheSize, 'lastSync': lastSync, 'isStale': isStale};
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
