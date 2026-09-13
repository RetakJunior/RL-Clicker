import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/download_progress.dart';

typedef ProgressCallback = void Function(DownloadProgress progress);

class DownloaderService {
  final http.Client _client;
  final Map<String, Completer<void>> _activeTasks = {};
  final Map<String, StreamSubscription<List<int>>> _activeSubscriptions = {};

  DownloaderService({http.Client? client}) : _client = client ?? http.Client();

  /// Downloads a remote video file using chunked streaming directly to disk.
  /// Uses a temporary file [.part] during download to ensure atomic storage.
  Future<File> download({
    required String taskId,
    required String url,
    required File destinationFile,
    ProgressCallback? onProgress,
  }) async {
    final partFile = File('${destinationFile.path}.part');

    // Clean up any existing partial download file
    if (partFile.existsSync()) {
      try {
        partFile.deleteSync();
      } catch (_) {}
    }

    final completer = Completer<void>();
    _activeTasks[taskId] = completer;

    IOSink? sink;
    StreamSubscription<List<int>>? subscription;

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
      request.headers['Connection'] = 'close';
      request.headers['Accept-Encoding'] = 'identity';

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw HttpException(
          'HTTP indirme hatası: ${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}',
          uri: Uri.parse(url),
        );
      }

      final totalBytes = streamedResponse.contentLength ?? -1;
      var downloadedBytes = 0;

      sink = partFile.openWrite();

      var lastTime = DateTime.now();
      var lastBytes = 0;
      var currentSpeed = 0.0;

      final streamCompleter = Completer<void>();

      subscription = streamedResponse.stream.listen(
        (chunk) {
          sink?.add(chunk);
          downloadedBytes += chunk.length;

          final now = DateTime.now();
          final elapsed = now.difference(lastTime).inMilliseconds;
          final isComplete = totalBytes > 0 && downloadedBytes >= totalBytes;

          if (elapsed >= 300 || isComplete) {
            final bytesSince = downloadedBytes - lastBytes;
            currentSpeed = elapsed > 0 ? (bytesSince / elapsed) * 1000.0 : 0.0;
            lastTime = now;
            lastBytes = downloadedBytes;

            onProgress?.call(DownloadProgress(
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes > 0 ? totalBytes : downloadedBytes,
              speed: currentSpeed,
            ));
          }

          if (isComplete) {
            subscription?.cancel();
            if (!streamCompleter.isCompleted) {
              streamCompleter.complete();
            }
          }
        },
        onError: (err) {
          if (!streamCompleter.isCompleted) {
            streamCompleter.completeError(err);
          }
        },
        onDone: () {
          if (!streamCompleter.isCompleted) {
            streamCompleter.complete();
          }
        },
        cancelOnError: true,
      );

      _activeSubscriptions[taskId] = subscription;

      await streamCompleter.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          if (downloadedBytes > 0) {
            return;
          }
          throw TimeoutException('İndirme zaman aşımına uğradı');
        },
      );

      await sink.flush();
      await sink.close();
      sink = null;

      // Rename from .part to final destination with fallback
      if (destinationFile.existsSync()) {
        try {
          destinationFile.deleteSync();
        } catch (_) {}
      }

      try {
        partFile.renameSync(destinationFile.path);
      } catch (_) {
        // Fallback for Android filesystems where rename across mounts or FUSE fails
        partFile.copySync(destinationFile.path);
        try {
          partFile.deleteSync();
        } catch (_) {}
      }

      onProgress?.call(DownloadProgress(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes > 0 ? totalBytes : downloadedBytes,
        speed: 0.0,
      ));

      return destinationFile;
    } catch (e) {
      if (sink != null) {
        try {
          await sink.flush();
          await sink.close();
        } catch (_) {}
      }
      if (partFile.existsSync()) {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    } finally {
      _activeTasks.remove(taskId);
      _activeSubscriptions.remove(taskId);
    }
  }

  /// Cancels an in-progress download task and cleans up temporary files.
  void cancel(String taskId) {
    if (_activeSubscriptions.containsKey(taskId)) {
      _activeSubscriptions[taskId]?.cancel();
      _activeSubscriptions.remove(taskId);
    }
    if (_activeTasks.containsKey(taskId)) {
      _activeTasks.remove(taskId);
    }
  }

  bool isDownloading(String taskId) => _activeTasks.containsKey(taskId);
}
