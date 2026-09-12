class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // in bytes per second

  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
  });

  double get fraction {
    if (totalBytes <= 0) return 0.0;
    final f = downloadedBytes / totalBytes;
    return f.clamp(0.0, 1.0);
  }

  int get percentage => (fraction * 100).round();

  String get downloadedString => formatBytes(downloadedBytes);
  String get totalString =>
      totalBytes > 0 ? formatBytes(totalBytes) : 'Unknown';
  String get speedString => '${formatBytes(speed.round())}/s';

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
