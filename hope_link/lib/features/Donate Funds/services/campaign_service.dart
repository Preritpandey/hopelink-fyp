import 'dart:convert';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/campaign_model.dart';

class CampaignService {
  static const String campaignsBox = 'campaigns_box';
  static const String lastSyncKey = 'last_sync';

  /// Fetch campaigns from API
  Future<List<Campaign>> fetchCampaigns() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.campaigns),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> campaignsData = jsonData['data'];

        final campaigns = campaignsData
            .map((data) => Campaign.fromJson(data))
            .toList();

        // Save to Hive for offline access
        await saveCampaignsToLocal(campaigns);

        return campaigns;
      } else {
        throw Exception('Failed to load campaigns: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching campaigns: $e');
      // Return cached data if API fails
      return getCampaignsFromLocal();
    }
  }

  /// Save campaigns to Hive local storage
  Future<void> saveCampaignsToLocal(List<Campaign> campaigns) async {
    try {
      final box = await Hive.openBox<Campaign>(campaignsBox);
      await box.clear();

      for (var campaign in campaigns) {
        await box.put(campaign.id, campaign);
      }

      // Save last sync time
      final prefsBox = await Hive.openBox('preferences');
      await prefsBox.put(lastSyncKey, DateTime.now().toIso8601String());

      print('Saved ${campaigns.length} campaigns to local storage');
    } catch (e) {
      print('Error saving campaigns to local: $e');
    }
  }

  /// Get campaigns from Hive local storage
  Future<List<Campaign>> getCampaignsFromLocal() async {
    try {
      final box = await Hive.openBox<Campaign>(campaignsBox);
      final campaigns = box.values.toList();
      print('Loaded ${campaigns.length} campaigns from local storage');
      return campaigns;
    } catch (e) {
      print('Error getting campaigns from local: $e');
      return [];
    }
  }

  /// Get single campaign by ID
  Future<Campaign?> getCampaignById(String id) async {
    // Try to fetch from API first
    try {
      final response = await http
          .get(
            Uri.parse('${ApiEndpoints.campaigns}/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final campaign = Campaign.fromJson(jsonData['data']);

        // Update local cache
        final box = await Hive.openBox<Campaign>(campaignsBox);
        await box.put(campaign.id, campaign);

        return campaign;
      }
    } catch (e) {
      print('Error fetching campaign by ID: $e');
    }

    // Fallback to local data
    try {
      final box = await Hive.openBox<Campaign>(campaignsBox);
      return box.get(id);
    } catch (e) {
      print('Error getting campaign from local: $e');
      return null;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefsBox = await Hive.openBox('preferences');
      final lastSync = prefsBox.get(lastSyncKey);

      if (lastSync != null) {
        return DateTime.parse(lastSync);
      }
      return null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if data is stale (older than 1 hour)
  Future<bool> isDataStale() async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;

      final difference = DateTime.now().difference(lastSync);
      return difference.inHours >= 1;
    } catch (e) {
      print('Error checking data staleness: $e');
      return true;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox<Campaign>(campaignsBox);
      await box.clear();

      final prefsBox = await Hive.openBox('preferences');
      await prefsBox.delete(lastSyncKey);

      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache size (number of campaigns)
  Future<int> getCacheSize() async {
    try {
      final box = await Hive.openBox<Campaign>(campaignsBox);
      return box.length;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }
}
