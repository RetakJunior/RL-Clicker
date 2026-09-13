import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/filename_utils.dart';

class StorageService {
  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.reelgrab.reelgrab/media_scanner');

  /// Requests Android MediaScanner to index the file so it appears in the system Gallery/Photos immediately.
  static Future<void> scanFile(String filePath) async {
    if (Platform.isAndroid) {
      try {
        await _mediaScannerChannel.invokeMethod('scanFile', {'path': filePath});
      } catch (_) {}
    }
  }

  /// Resolves the platform-specific download directory:
  /// - Android: Tests candidates in priority order (Movies -> Download -> Android/media -> App external -> Documents)
  ///   Verifies each candidate with a probe write so it is guaranteed writable.
  /// - Linux: ~/Downloads/RL_Clicker/
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      final dirPath = '$home/Downloads/RL_Clicker';
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    } else if (Platform.isAndroid) {
      // Helper to test if directory exists or can be created AND written to
      bool isWritable(Directory dir) {
        try {
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final probe = File(
              '${dir.path}/.probe_${DateTime.now().microsecondsSinceEpoch}');
          probe.writeAsStringSync('probe');
          probe.deleteSync();
          return true;
        } catch (_) {
          return false;
        }
      }

      // 1. Primary standard: /storage/emulated/0/Movies/RL Clicker
      final moviesDir = Directory('/storage/emulated/0/Movies/RL Clicker');
      if (isWritable(moviesDir)) {
        return moviesDir;
      }

      // 2. Secondary public: /storage/emulated/0/Download/RL Clicker
      final downloadDir = Directory('/storage/emulated/0/Download/RL Clicker');
      if (isWritable(downloadDir)) {
        return downloadDir;
      }

      // 3. Android/media: publicly visible and indexed by MediaStore on Android 11+
      final mediaDir = Directory(
          '/storage/emulated/0/Android/media/com.reelgrab.reelgrab/RL Clicker');
      if (isWritable(mediaDir)) {
        return mediaDir;
      }

      // 4. App-specific external storage (Movies)
      try {
        final extDirs =
            await getExternalStorageDirectories(type: StorageDirectory.movies);
        if (extDirs != null && extDirs.isNotEmpty) {
          final target = Directory('${extDirs.first.path}/RL_Clicker');
          if (isWritable(target)) {
            return target;
          }
        }
      } catch (_) {}

      // 5. App documents directory (guaranteed fallback)
      final docDir = await getApplicationDocumentsDirectory();
      final target = Directory('${docDir.path}/RL_Clicker');
      if (!target.existsSync()) {
        target.createSync(recursive: true);
      }
      return target;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/RL_Clicker');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
  }

  static final Set<String> _inProgressPaths = {};

  /// Creates a unique destination File inside the download directory,
  /// tracking in-progress downloads to prevent race condition collisions.
  static Future<File> createDestinationFile({DateTime? timestamp}) async {
    final dir = await getDownloadDirectory();
    final now = timestamp ?? DateTime.now();
    var index = 0;
    while (true) {
      final filename = FilenameUtils.generateVideoFilename(
        timestamp: now,
        duplicateIndex: index > 0 ? index : null,
      );
      final fullPath = '${dir.path}/$filename';
      final file = File(fullPath);
      final partFile = File('$fullPath.part');
      if (!file.existsSync() &&
          !partFile.existsSync() &&
          !_inProgressPaths.contains(fullPath)) {
        _inProgressPaths.add(fullPath);
        return file;
      }
      index++;
    }
  }

  /// Releases the destination reservation once a download finishes or fails.
  static void releaseDestinationFile(String path) {
    _inProgressPaths.remove(path);
  }

  /// Opens the downloaded video with the system's default media player.
  static Future<OpenResult> openVideoFile(String filePath) async {
    await scanFile(filePath);
    return await OpenFilex.open(filePath, type: 'video/mp4');
  }

  /// Opens the folder containing the downloaded file.
  static Future<void> openFolder(String filePath) async {
    try {
      final file = File(filePath);
      final parentPath = file.parent.path;

      if (Platform.isLinux) {
        await Process.run('xdg-open', [parentPath]);
      } else {
        await OpenFilex.open(parentPath);
      }
    } catch (_) {
      // Graceful fallback
    }
  }
}
