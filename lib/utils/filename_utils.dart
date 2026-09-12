import 'dart:io';
import 'package:intl/intl.dart';

class FilenameUtils {
  /// Strips characters that are illegal or problematic in Linux / Android file systems.
  static String sanitize(String name) {
    // Replace illegal characters: \ / : * ? " < > | \0
    var sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00]'), '_');
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x01-\x1f\x7f]'), '');
    // Trim spaces and dots
    sanitized = sanitized.trim();
    if (sanitized.isEmpty) {
      sanitized = 'video';
    }
    // Limit length to 120 chars for safety
    if (sanitized.length > 120) {
      sanitized = sanitized.substring(0, 120);
    }
    return sanitized;
  }

  /// Generates the standard timestamp-based video filename:
  /// RL_Clicker_YYYYMMDD_HHMMSS.mp4
  static String generateVideoFilename(
      {DateTime? timestamp, int? duplicateIndex}) {
    final now = timestamp ?? DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final base = 'RL_Clicker_${formatter.format(now)}';
    if (duplicateIndex != null && duplicateIndex > 0) {
      return '${base}_$duplicateIndex.mp4';
    }
    return '$base.mp4';
  }

  /// Ensures a unique file path in the given target directory.
  /// If RL_Clicker_20260912_184500.mp4 already exists, generates _1.mp4, _2.mp4, etc.
  /// Also checks and reserves .part to prevent collisions between concurrent downloads.
  static File getUniqueDestinationFile(String directoryPath,
      {DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    var index = 0;
    while (true) {
      final filename = generateVideoFilename(
        timestamp: now,
        duplicateIndex: index > 0 ? index : null,
      );
      final file = File('$directoryPath/$filename');
      final partFile = File('$directoryPath/$filename.part');
      if (!file.existsSync() && !partFile.existsSync()) {
        try {
          partFile.createSync(recursive: true);
        } catch (_) {}
        return file;
      }
      index++;
    }
  }
}
