import 'package:flutter/material.dart';

class VideoDownloadProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // bytes/s
  final Color? color;

  const VideoDownloadProgressBar({
    super.key,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    this.color,
  });

  static String _formatBytes(int bytes) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress.clamp(0.0, 1.0) * 100).round();
    final downloadedStr = _formatBytes(downloadedBytes);
    final totalStr = totalBytes > 0 ? _formatBytes(totalBytes) : '...';
    final speedStr = '${_formatBytes(speed.round())}/s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percentage%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? theme.colorScheme.primary,
              ),
            ),
            Text(
              '$downloadedStr / $totalStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (speed > 0)
              Text(
                speedStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
