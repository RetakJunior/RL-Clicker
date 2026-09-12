import 'package:flutter/material.dart';
import '../models/download_task.dart';
import 'download_task_card.dart';

class DownloadQueueWidget extends StatelessWidget {
  final List<DownloadTask> tasks;
  final VoidCallback? onStartAll;
  final VoidCallback? onCancelAll;
  final VoidCallback? onRetryAll;
  final VoidCallback? onClearCompleted;
  final ValueChanged<String>? onRetryTask;
  final ValueChanged<String>? onCancelTask;
  final ValueChanged<String>? onRemoveTask;

  const DownloadQueueWidget({
    super.key,
    required this.tasks,
    this.onStartAll,
    this.onCancelAll,
    this.onRetryAll,
    this.onClearCompleted,
    this.onRetryTask,
    this.onCancelTask,
    this.onRemoveTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQueued = tasks.any((t) => t.status == DownloadTaskStatus.queued);
    final hasActive = tasks.any((t) =>
        t.status == DownloadTaskStatus.resolving ||
        t.status == DownloadTaskStatus.downloading);
    final hasFailed = tasks.any((t) =>
        t.status == DownloadTaskStatus.failed ||
        t.status == DownloadTaskStatus.cancelled);
    final hasCompleted =
        tasks.any((t) => t.status == DownloadTaskStatus.completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Queue Header and Batch Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'İndirme Kuyruğu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: [
                if (hasQueued && !hasActive)
                  TextButton.icon(
                    onPressed: onStartAll,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Tümünü Başlat'),
                  ),
                if (hasActive)
                  TextButton.icon(
                    onPressed: onCancelAll,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Tümünü Durdur'),
                  ),
                if (hasFailed)
                  TextButton.icon(
                    onPressed: onRetryAll,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tümünü Tekrar Dene'),
                  ),
                if (hasCompleted)
                  IconButton(
                    icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                    tooltip: 'Tamamlananları Temizle',
                    onPressed: onClearCompleted,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.playlist_play_rounded,
                  size: 48,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kuyrukta video bulunmuyor',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yukarıdaki alana Instagram Reel/Video bağlantılarını ekleyin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return DownloadTaskCard(
                key: ValueKey(task.id),
                task: task,
                onRetry: () => onRetryTask?.call(task.id),
                onCancel: () => onCancelTask?.call(task.id),
                onRemove: () => onRemoveTask?.call(task.id),
              );
            },
          ),
      ],
    );
  }
}
