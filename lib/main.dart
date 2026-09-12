import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/download_queue_service.dart';
import 'services/downloader_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/video_resolver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  // Load preferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize core services
  final settingsService = SettingsService(prefs);
  final videoResolver = InstagramResolver();
  final downloaderService = DownloaderService();
  final queueService = DownloadQueueService(
    resolver: videoResolver,
    downloader: downloaderService,
    settings: settingsService,
    prefs: prefs,
  );

  runApp(
    RLClickerApp(
      settingsService: settingsService,
      queueService: queueService,
    ),
  );
}
