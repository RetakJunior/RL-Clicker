import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_task.dart';
import '../utils/error_utils.dart';
import '../utils/url_parser.dart';
import 'downloader_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'video_resolver.dart';

class DownloadQueueService extends ChangeNotifier {
  static const String _keyHistory = 'download_history_v1';

  final VideoResolver _resolver;
  final DownloaderService _downloader;
  final SettingsService _settings;
  final SharedPreferences _prefs;

  final List<DownloadTask> _queue = [];
  final List<DownloadTask> _history = [];
  final Set<String> _activeRunningTaskIds = {};

  bool _isProcessing = false;

  DownloadQueueService({
    required VideoResolver resolver,
    required DownloaderService downloader,
    required SettingsService settings,
    required SharedPreferences prefs,
  })  : _resolver = resolver,
        _downloader = downloader,
        _settings = settings,
        _prefs = prefs {
    _loadHistory();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _processNext();
  }

  List<DownloadTask> get queue => List.unmodifiable(_queue);
  List<DownloadTask> get history => List.unmodifiable(_history);
  int get activeDownloadCount => _activeRunningTaskIds.length;
  bool get isProcessing => _isProcessing;

  /// Adds a list of Instagram URLs to the download queue.
  /// Returns a summary report with counts of added and duplicate items.
  ({int added, int duplicates}) addUrls(List<InstagramUrl> urls) {
    var addedCount = 0;
    var duplicateCount = 0;

    for (final parsed in urls) {
      // Check if already in queue
      final existsInQueue = _queue.any(
        (t) =>
            t.sourceUrl == parsed.normalizedUrl &&
            t.status != DownloadTaskStatus.completed &&
            t.status != DownloadTaskStatus.cancelled,
      );

      if (existsInQueue) {
        duplicateCount++;
        continue;
      }

      final task = DownloadTask(
        id: '${DateTime.now().microsecondsSinceEpoch}_${_queue.length}',
        sourceUrl: parsed.normalizedUrl,
        title: 'Instagram Video (${parsed.shortcode})',
        status: DownloadTaskStatus.queued,
        createdAt: DateTime.now(),
      );

      _queue.add(task);
      addedCount++;
    }

    notifyListeners();
    return (added: addedCount, duplicates: duplicateCount);
  }

  /// Starts downloading all queued tasks
  void startAll() {
    _isProcessing = true;
    _processNext();
    notifyListeners();
  }

  /// Cancels all active and queued downloads
  void cancelAll() {
    for (final taskId in _activeRunningTaskIds.toList()) {
      _downloader.cancel(taskId);
    }
    _activeRunningTaskIds.clear();

    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].status == DownloadTaskStatus.queued ||
          _queue[i].status == DownloadTaskStatus.resolving ||
          _queue[i].status == DownloadTaskStatus.downloading) {
        _queue[i] = _queue[i].copyWith(
          status: DownloadTaskStatus.cancelled,
          speed: 0.0,
        );
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// Retries all failed or cancelled tasks in the queue
  void retryAll() {
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].status == DownloadTaskStatus.failed ||
          _queue[i].status == DownloadTaskStatus.cancelled) {
        _queue[i] = _queue[i].copyWith(
          status: DownloadTaskStatus.queued,
          progress: 0.0,
          downloadedBytes: 0,
          error: null,
          speed: 0.0,
        );
      }
    }
    startAll();
  }

  /// Retries a single failed or cancelled task
  void retryTask(String taskId) {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: DownloadTaskStatus.queued,
        progress: 0.0,
        downloadedBytes: 0,
        error: null,
        speed: 0.0,
      );
      notifyListeners();
      _processNext();
    }
  }

  /// Cancels a specific download task
  void cancelTask(String taskId) {
    if (_activeRunningTaskIds.contains(taskId)) {
      _downloader.cancel(taskId);
      _activeRunningTaskIds.remove(taskId);
    }

    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: DownloadTaskStatus.cancelled,
        speed: 0.0,
      );
      notifyListeners();
      _processNext();
    }
  }

  /// Removes a task from the queue display
  void removeTask(String taskId) {
    cancelTask(taskId);
    _queue.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// Clears completed/cancelled/failed tasks from the queue
  void clearInactiveFromQueue() {
    _queue.removeWhere((t) =>
        t.status == DownloadTaskStatus.completed ||
        t.status == DownloadTaskStatus.cancelled);
    notifyListeners();
  }

  /// Internal queue processor ensuring concurrent download limit
  void _processNext() {
    final maxConcurrent = _settings.concurrentDownloads;

    while (_activeRunningTaskIds.length < maxConcurrent) {
      final nextTaskIndex = _queue.indexWhere(
        (t) => t.status == DownloadTaskStatus.queued,
      );

      if (nextTaskIndex == -1) {
        // No more queued tasks
        if (_activeRunningTaskIds.isEmpty && _isProcessing) {
          _isProcessing = false;
          _checkBatchFinished();
        }
        break;
      }

      final task = _queue[nextTaskIndex];
      _activeRunningTaskIds.add(task.id);
      _executeTask(task.id);
    }
  }

  Future<void> _executeTask(String taskId) async {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      _activeRunningTaskIds.remove(taskId);
      _processNext();
      return;
    }

    // Step 1: Resolving video
    _queue[index] = _queue[index].copyWith(
      status: DownloadTaskStatus.resolving,
    );
    notifyListeners();

    File? destination;
    try {
      final resolved = await _resolver.resolve(_queue[index].sourceUrl);

      // Verify if task was cancelled while resolving
      if (!_activeRunningTaskIds.contains(taskId)) return;

      final updatedIndex = _queue.indexWhere((t) => t.id == taskId);
      if (updatedIndex == -1) return;

      _queue[updatedIndex] = _queue[updatedIndex].copyWith(
        title: resolved.title,
        thumbnail: resolved.thumbnailUrl,
        status: DownloadTaskStatus.downloading,
      );
      notifyListeners();

      // Step 2: Prepare storage file
      destination = await StorageService.createDestinationFile();

      // Step 3: Stream download
      await _downloader.download(
        taskId: taskId,
        url: resolved.videoUrl,
        destinationFile: destination,
        onProgress: (prog) {
          final curIdx = _queue.indexWhere((t) => t.id == taskId);
          if (curIdx != -1) {
            _queue[curIdx] = _queue[curIdx].copyWith(
              progress: prog.fraction,
              downloadedBytes: prog.downloadedBytes,
              totalBytes: prog.totalBytes,
              speed: prog.speed,
            );
            notifyListeners();
          }
        },
      );

      // Step 4: Complete
      final finalIdx = _queue.indexWhere((t) => t.id == taskId);
      if (finalIdx != -1) {
        // Trigger media scanner so Android Gallery / media players detect the file immediately
        await StorageService.scanFile(destination.path);

        final completedTask = _queue[finalIdx].copyWith(
          status: DownloadTaskStatus.completed,
          progress: 1.0,
          speed: 0.0,
          filePath: destination.path,
          completedAt: DateTime.now(),
        );
        _queue[finalIdx] = completedTask;
        _addToHistory(completedTask);

        if (_settings.notificationsEnabled) {
          try {
            await NotificationService.showDownloadComplete(
              id: (taskId.hashCode.abs()) % 100000,
              title: completedTask.title,
              filePath: destination.path,
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      final finalIdx = _queue.indexWhere((t) => t.id == taskId);
      if (finalIdx != -1 &&
          _queue[finalIdx].status != DownloadTaskStatus.cancelled) {
        final errorMsg = ErrorUtils.mapError(e);
        final failedTask = _queue[finalIdx].copyWith(
          status: DownloadTaskStatus.failed,
          error: errorMsg,
          speed: 0.0,
        );
        _queue[finalIdx] = failedTask;
        _addToHistory(failedTask);
      }
    } finally {
      if (destination != null) {
        StorageService.releaseDestinationFile(destination.path);
      }
      _activeRunningTaskIds.remove(taskId);
      notifyListeners();
      _processNext();
    }
  }

  void _checkBatchFinished() {
    final completedCount =
        _queue.where((t) => t.status == DownloadTaskStatus.completed).length;
    final failedCount =
        _queue.where((t) => t.status == DownloadTaskStatus.failed).length;

    if (_settings.notificationsEnabled &&
        (completedCount > 0 || failedCount > 0)) {
      NotificationService.showBatchComplete(
        successful: completedCount,
        failed: failedCount,
      );
    }
  }

  void _addToHistory(DownloadTask task) {
    _history.removeWhere((t) => t.id == task.id);
    _history.insert(0, task);
    _saveHistory();
  }

  void deleteFromHistory(String taskId) {
    _history.removeWhere((t) => t.id == taskId);
    _saveHistory();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    notifyListeners();
  }

  Future<void> deleteHistoryFile(DownloadTask task) async {
    if (task.filePath != null) {
      final file = File(task.filePath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    deleteFromHistory(task.id);
  }

  void _loadHistory() {
    final raw = _prefs.getString(_keyHistory);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        _history.clear();
        for (final item in list) {
          _history.add(DownloadTask.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {}
    }
  }

  void _saveHistory() {
    try {
      final list = _history.take(100).map((t) => t.toJson()).toList();
      _prefs.setString(_keyHistory, json.encode(list));
    } catch (_) {}
  }
}
