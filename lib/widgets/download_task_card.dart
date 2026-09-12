import 'package:flutter/material.dart';
import '../models/download_task.dart';
import '../services/storage_service.dart';
import 'progress_indicator.dart';

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;

  const DownloadTaskCard({
    super.key,
    required this.task,
    this.onRetry,
    this.onCancel,
    this.onRemove,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (task.status) {
      case DownloadTaskStatus.completed:
        return Colors.green;
      case DownloadTaskStatus.failed:
        return theme.colorScheme.error;
      case DownloadTaskStatus.downloading:
        return theme.colorScheme.primary;
      case DownloadTaskStatus.resolving:
        return theme.colorScheme.secondary;
      case DownloadTaskStatus.queued:
        return theme.colorScheme.onSurfaceVariant;
      case DownloadTaskStatus.cancelled:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or Video Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 54,
                    height: 54,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: task.thumbnail != null
                        ? Image.network(
                            task.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 28,
                            ),
                          )
                        : const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Source
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.sourceUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.status.labelTr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.status == DownloadTaskStatus.failed ||
                        task.status == DownloadTaskStatus.cancelled)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Yeniden Dene',
                        onPressed: onRetry,
                      ),
                    if (task.status == DownloadTaskStatus.queued ||
                        task.status == DownloadTaskStatus.resolving ||
                        task.status == DownloadTaskStatus.downloading)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'İptal Et',
                        onPressed: onCancel,
                      ),
                    if (task.status == DownloadTaskStatus.completed &&
                        task.filePath != null) ...[
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Videoyu Oynat',
                        onPressed: () =>
                            StorageService.openVideoFile(task.filePath!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open_rounded),
                        tooltip: 'Klasörü Aç',
                        onPressed: () =>
                            StorageService.openFolder(task.filePath!),
                      ),
                    ],
                    if (onRemove != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Listeden Kaldır',
                        onPressed: onRemove,
                      ),
                  ],
                ),
              ],
            ),
            // Progress Bar (when downloading)
            if (task.status == DownloadTaskStatus.downloading) ...[
              const SizedBox(height: 10),
              VideoDownloadProgressBar(
                progress: task.progress,
                downloadedBytes: task.downloadedBytes,
                totalBytes: task.totalBytes,
                speed: task.speed,
              ),
            ],
            // Error notice
            if (task.status == DownloadTaskStatus.failed &&
                task.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
