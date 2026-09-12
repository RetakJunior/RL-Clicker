import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rl_clicker/utils/filename_utils.dart';

void main() {
  group('FilenameUtils Tests', () {
    test('sanitizes illegal filesystem characters', () {
      expect(
        FilenameUtils.sanitize('Video: Reel *123? <cool> | path/test"'),
        equals('Video_ Reel _123_ _cool_ _ path_test_'),
      );
      expect(FilenameUtils.sanitize('   '), equals('video'));
    });

    test('generates standard timestamp filename', () {
      final dt = DateTime(2026, 9, 12, 18, 45, 0);
      final filename = FilenameUtils.generateVideoFilename(timestamp: dt);
      expect(filename, equals('RL_Clicker_20260912_184500.mp4'));
    });

    test('generates duplicate index filename when index is provided', () {
      final dt = DateTime(2026, 9, 12, 18, 45, 0);
      final filename = FilenameUtils.generateVideoFilename(
        timestamp: dt,
        duplicateIndex: 1,
      );
      expect(filename, equals('RL_Clicker_20260912_184500_1.mp4'));
    });

    test('getUniqueDestinationFile prevents filename collision', () {
      final tempDir = Directory.systemTemp.createTempSync('rl_clicker_test_');
      final dt = DateTime(2026, 9, 12, 18, 45, 0);

      // Create base file
      final file1 =
          FilenameUtils.getUniqueDestinationFile(tempDir.path, timestamp: dt);
      file1.writeAsStringSync('dummy content 1');
      expect(file1.path.endsWith('RL_Clicker_20260912_184500.mp4'), isTrue);

      // Next call should avoid collision by appending _1.mp4
      final file2 =
          FilenameUtils.getUniqueDestinationFile(tempDir.path, timestamp: dt);
      expect(file2.path.endsWith('RL_Clicker_20260912_184500_1.mp4'), isTrue);

      tempDir.deleteSync(recursive: true);
    });
  });
}
