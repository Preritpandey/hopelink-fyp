import 'package:hive_flutter/hive_flutter.dart';

import '../features/Donate Funds/models/campaign_model.dart';

class HiveConfig {
  static Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(CampaignAdapter());
    Hive.registerAdapter(OrganizationAdapter());
    Hive.registerAdapter(CampaignUpdateAdapter());
    Hive.registerAdapter(FAQAdapter());

    // Open boxes
    await Hive.openBox<Campaign>('campaigns_box');
    await Hive.openBox('preferences');
    await Hive.openBox('donations');
  }

  static Future<void> clearAllData() async {
    final campaignsBox = await Hive.openBox<Campaign>('campaigns_box');
    final prefsBox = await Hive.openBox('preferences');
    final donationsBox = await Hive.openBox('donations');

    await campaignsBox.clear();
    await prefsBox.clear();
    await donationsBox.clear();
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }
}