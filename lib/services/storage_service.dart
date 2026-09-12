import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/filename_utils.dart';

class StorageService {
  /// Resolves the platform-specific download directory:
  /// - Android: Movies/RL Clicker/ (or app external storage as fallback)
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
      // Primary standard path for user visible videos on modern Android:
      final moviesDir = Directory('/storage/emulated/0/Movies/RL Clicker');
      try {
        if (!moviesDir.existsSync()) {
          moviesDir.createSync(recursive: true);
        }
        return moviesDir;
      } catch (_) {
        // Fallback to app external storage Movies or Documents
        final extDirs =
            await getExternalStorageDirectories(type: StorageDirectory.movies);
        if (extDirs != null && extDirs.isNotEmpty) {
          final target = Directory('${extDirs.first.path}/RL_Clicker');
          if (!target.existsSync()) {
            target.createSync(recursive: true);
          }
          return target;
        }
        final docDir = await getApplicationDocumentsDirectory();
        final target = Directory('${docDir.path}/RL_Clicker');
        if (!target.existsSync()) {
          target.createSync(recursive: true);
        }
        return target;
      }
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
    return await OpenFilex.open(filePath);
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
