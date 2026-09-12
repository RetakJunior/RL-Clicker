import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rl_clicker/models/download_progress.dart';
import 'package:rl_clicker/utils/error_utils.dart';

void main() {
  group('DownloadProgress & ErrorUtils Tests', () {
    test('calculates fraction and percentage correctly', () {
      const progress = DownloadProgress(
        downloadedBytes: 50,
        totalBytes: 100,
        speed: 1024,
      );
      expect(progress.fraction, equals(0.5));
      expect(progress.percentage, equals(50));
      expect(progress.downloadedString, equals('50 B'));
      expect(progress.totalString, equals('100 B'));
      expect(progress.speedString, equals('1.0 KB/s'));
    });

    test('handles unknown total bytes gracefully', () {
      const progress = DownloadProgress(
        downloadedBytes: 1024 * 1024 * 5,
        totalBytes: -1,
        speed: 1024 * 1024 * 2.5,
      );
      expect(progress.fraction, equals(0.0));
      expect(progress.totalString, equals('Unknown'));
      expect(progress.downloadedString, equals('5.0 MB'));
    });

    test('maps exceptions to friendly Turkish descriptions', () {
      const socketErr = SocketException('Failed host lookup');
      expect(
        ErrorUtils.mapError(socketErr),
        contains('İnternet bağlantınızı kontrol edin'),
      );

      const resolverErr = ResolverException('Özel hata mesajı');
      expect(ErrorUtils.mapError(resolverErr), equals('Özel hata mesajı'));

      const timeoutErr = 'Connection timed out';
      expect(
        ErrorUtils.mapError(timeoutErr),
        contains('zaman aşımına uğradı'),
      );
    });
  });
}
