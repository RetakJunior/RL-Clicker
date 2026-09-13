import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'rl_clicker_downloads';
  static const String _channelName = 'RL Clicker İndirmeler';
  static const String _channelDescription =
      'RL Clicker video indirme bildirimleri';

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    try {
      await _plugin.initialize(initSettings);
      _initialized = true;

      // Create notification channel on Android
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }
    } catch (_) {
      // Graceful fallback if platform notifications fail to register
    }
  }

  static Future<void> showDownloadComplete({
    required int id,
    required String title,
    required String filePath,
  }) async {
    if (!_initialized) return;
    try {
      final safeId = (id.abs()) % 100000;
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const linuxDetails = LinuxNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _plugin.show(
        safeId,
        'İndirme Tamamlandı ✓',
        title,
        details,
        payload: filePath,
      );
    } catch (_) {}
  }

  static Future<void> showBatchComplete({
    required int successful,
    required int failed,
  }) async {
    if (!_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const linuxDetails = LinuxNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      final message = failed > 0
          ? '$successful video başarıyla indirildi. $failed video indirilemedi.'
          : '$successful video başarıyla indirildi.';

      await _plugin.show(
        9999,
        'RL Clicker',
        message,
        details,
      );
    } catch (_) {}
  }
}
