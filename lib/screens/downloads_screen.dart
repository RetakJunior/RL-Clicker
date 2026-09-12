import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/download_progress.dart';
import '../models/download_task.dart';
import '../services/download_queue_service.dart';
import '../services/storage_service.dart';

class DownloadsScreen extends StatelessWidget {
  final DownloadQueueService queueService;

  const DownloadsScreen({
    super.key,
    required this.queueService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return ListenableBuilder(
      listenable: queueService,
      builder: (context, _) {
        final history = queueService.history;

        return Scaffold(
          appBar: AppBar(
            title: const Text('İndirilenler'),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Geçmişi Temizle',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Geçmişi Temizle'),
                        content: const Text(
                          'İndirme geçmişini temizlemek istiyor musunuz? (İndirilen dosyalar silinmez)',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Vazgeç'),
                          ),
                          FilledButton(
                            onPressed: () {
                              queueService.clearHistory();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Temizle'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_done_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz indirme geçmişi yok',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tamamlanan videolar burada listelenecektir.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final dateStr = item.completedAt != null
                        ? dateFormatter.format(item.completedAt!)
                        : dateFormatter.format(item.createdAt);
                    final sizeStr = item.totalBytes > 0
                        ? DownloadProgress.formatBytes(item.totalBytes)
                        : (item.downloadedBytes > 0
                            ? DownloadProgress.formatBytes(item.downloadedBytes)
                            : '');

                    final isSuccess =
                        item.status == DownloadTaskStatus.completed;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: item.thumbnail != null
                                        ? Image.network(
                                            item.thumbnail!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.play_circle_outline_rounded,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.play_circle_outline_rounded,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$dateStr • $sizeStr',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSuccess
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSuccess ? 'İndirildi' : 'Hata',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isSuccess
                                          ? Colors.green
                                          : theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isSuccess && item.filePath != null) ...[
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        StorageService.openVideoFile(
                                            item.filePath!),
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 18),
                                    label: const Text('AÇ'),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => StorageService.openFolder(
                                        item.filePath!),
                                    icon: const Icon(Icons.folder_open_rounded,
                                        size: 18),
                                    label: const Text('KLASÖR'),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20),
                                  tooltip: 'Sil',
                                  onPressed: () =>
                                      queueService.deleteHistoryFile(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
