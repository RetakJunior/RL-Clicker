import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rl_clicker/models/download_task.dart';
import 'package:rl_clicker/services/download_queue_service.dart';
import 'package:rl_clicker/services/downloader_service.dart';
import 'package:rl_clicker/services/settings_service.dart';
import 'package:rl_clicker/services/video_resolver.dart';
import 'package:rl_clicker/utils/url_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SettingsService settings;
  late VideoResolver mockResolver;
  late DownloaderService mockDownloader;
  late DownloadQueueService queueService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    await settings.setConcurrentDownloads(2);

    mockResolver = MockVideoResolver(
      delay: const Duration(milliseconds: 10),
    );

    // Mock HTTP client that returns dummy video bytes
    final client = MockClient((request) async {
      return http.Response.bytes(
        List<int>.filled(1024, 0),
        200,
        headers: {
          HttpHeaders.contentTypeHeader: 'video/mp4',
          HttpHeaders.contentLengthHeader: '1024',
        },
      );
    });

    mockDownloader = DownloaderService(client: client);
    queueService = DownloadQueueService(
      resolver: mockResolver,
      downloader: mockDownloader,
      settings: settings,
      prefs: prefs,
    );
  });

  group('DownloadQueueService Tests', () {
    test('adds URLs and prevents duplicates', () {
      final urls = InstagramUrlParser.parse('''
https://instagram.com/reel/1111/
https://instagram.com/reel/2222/
''');

      final result1 = queueService.addUrls(urls);
      expect(result1.added, equals(2));
      expect(result1.duplicates, equals(0));
      expect(queueService.queue.length, equals(2));

      // Trying to add same URLs again
      final result2 = queueService.addUrls(urls);
      expect(result2.added, equals(0));
      expect(result2.duplicates, equals(2));
      expect(queueService.queue.length, equals(2));
    });

    test('processes downloads respecting concurrency limit', () async {
      final urls = InstagramUrlParser.parse('''
https://instagram.com/reel/AAAA/
https://instagram.com/reel/BBBB/
https://instagram.com/reel/CCCC/
''');

      queueService.addUrls(urls);
      queueService.startAll();

      // Immediately after start, active downloads should not exceed concurrentDownloads (2)
      expect(queueService.activeDownloadCount, lessThanOrEqualTo(2));

      // Wait for all to finish
      await Future.delayed(const Duration(milliseconds: 600));

      // Check that all tasks finished successfully
      for (final task in queueService.queue) {
        expect(task.status, equals(DownloadTaskStatus.completed));
      }
      expect(queueService.history.length, equals(3));
    });

    test('cancels active and queued downloads', () async {
      final urls =
          InstagramUrlParser.parse('https://instagram.com/reel/CANCEL_TEST/');
      queueService.addUrls(urls);
      queueService.cancelAll();

      expect(queueService.queue.first.status,
          equals(DownloadTaskStatus.cancelled));
    });

    test('retries failed or cancelled tasks', () async {
      final urls =
          InstagramUrlParser.parse('https://instagram.com/reel/RETRY_TEST/');
      queueService.addUrls(urls);
      queueService.cancelAll();
      expect(queueService.queue.first.status,
          equals(DownloadTaskStatus.cancelled));

      queueService.retryAll();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(queueService.queue.first.status,
          equals(DownloadTaskStatus.completed));
    });
  });
}
