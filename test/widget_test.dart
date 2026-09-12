import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rl_clicker/app.dart';
import 'package:rl_clicker/models/download_task.dart';
import 'package:rl_clicker/services/download_queue_service.dart';
import 'package:rl_clicker/services/downloader_service.dart';
import 'package:rl_clicker/services/settings_service.dart';
import 'package:rl_clicker/services/video_resolver.dart';
import 'package:rl_clicker/widgets/download_task_card.dart';
import 'package:rl_clicker/widgets/progress_indicator.dart';
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
    mockResolver = MockVideoResolver(delay: Duration.zero);

    final client = MockClient((request) async {
      return http.Response.bytes(
        List<int>.filled(512, 0),
        200,
        headers: {
          HttpHeaders.contentTypeHeader: 'video/mp4',
          HttpHeaders.contentLengthHeader: '512',
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

  Widget buildTestApp() {
    return RLClickerApp(
      settingsService: settings,
      queueService: queueService,
    );
  }

  group('RL Clicker UI & Widget Tests', () {
    testWidgets('renders Home screen and app title properly', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('RL Clicker'), findsWidgets);
      expect(find.text('Instagram video linklerini gir'), findsOneWidget);
      expect(find.text('İndirme Kuyruğu'), findsOneWidget);
      expect(find.text('LİNKLERİ EKLE'), findsOneWidget);
      expect(find.text('TÜMÜNÜ İNDİR'), findsOneWidget);
    });

    testWidgets('entering URLs updates count and enables actions',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(
        textField,
        'https://instagram.com/reel/TEST1/\nhttps://instagram.com/reel/TEST2/',
      );
      await tester.pump();

      expect(find.text('2 bağlantı hazır'), findsOneWidget);

      // Tap LİNKLERİ EKLE
      await tester.tap(find.text('LİNKLERİ EKLE'));
      await tester.pump();

      expect(queueService.queue.length, equals(2));
      expect(find.text('Instagram Video (TEST1)'), findsOneWidget);
      expect(find.text('Instagram Video (TEST2)'), findsOneWidget);
    });

    testWidgets('TÜMÜNÜ İNDİR triggers resolution and download',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(
          textField, 'https://instagram.com/reel/DOWNLOAD_NOW/');
      await tester.pump();

      await tester.tap(find.text('TÜMÜNÜ İNDİR'));
      await tester.pump();

      // Verify task entered resolution and download pipeline
      expect(queueService.queue.isNotEmpty, isTrue);
      expect(
        queueService.queue.first.status == DownloadTaskStatus.resolving ||
            queueService.queue.first.status == DownloadTaskStatus.downloading ||
            queueService.queue.first.status == DownloadTaskStatus.completed,
        isTrue,
      );
    });

    testWidgets('DownloadTaskCard displays completed state and player button',
        (tester) async {
      final task = DownloadTask(
        id: 'test_task_1',
        sourceUrl: 'https://instagram.com/reel/XYZ/',
        title: 'Completed Test Video',
        status: DownloadTaskStatus.completed,
        progress: 1.0,
        downloadedBytes: 1024 * 1024 * 10,
        totalBytes: 1024 * 1024 * 10,
        filePath: '/tmp/test.mp4',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadTaskCard(task: task),
          ),
        ),
      );

      expect(find.text('Completed Test Video'), findsOneWidget);
      expect(find.text('Tamamlandı ✓'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('DownloadTaskCard displays failed state and retry button',
        (tester) async {
      var retried = false;
      final task = DownloadTask(
        id: 'test_task_2',
        sourceUrl: 'https://instagram.com/reel/FAILED/',
        title: 'Failed Video',
        status: DownloadTaskStatus.failed,
        error: 'İnternet bağlantınızı kontrol edin.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadTaskCard(
              task: task,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed Video'), findsOneWidget);
      expect(find.text('Hata oluştu ✗'), findsOneWidget);
      expect(find.text('İnternet bağlantınızı kontrol edin.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(retried, isTrue);
    });

    testWidgets(
        'VideoDownloadProgressBar renders progress percentages correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoDownloadProgressBar(
              progress: 0.72,
              downloadedBytes: 1024 * 1024 * 34,
              totalBytes: 1024 * 1024 * 48,
              speed: 1024 * 1024 * 2.8,
            ),
          ),
        ),
      );

      expect(find.text('72%'), findsOneWidget);
      expect(find.text('34.0 MB / 48.0 MB'), findsOneWidget);
      expect(find.text('2.8 MB/s'), findsOneWidget);
    });

    testWidgets('switching navigation tabs switches to Downloads and Settings',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap İndirmeler tab
      await tester.tap(find.text('İndirmeler'));
      await tester.pumpAndSettle();
      expect(find.text('Henüz indirme geçmişi yok'), findsOneWidget);

      // Tap Ayarlar tab
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      expect(find.text('Eşzamanlı İndirme (Concurrent)'), findsOneWidget);
      expect(find.text('Otomatik Pano Algılama'), findsOneWidget);
      expect(find.text('Karanlık Mod'), findsOneWidget);
    });
  });
}
