import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../services/download_queue_service.dart';
import '../services/settings_service.dart';
import '../utils/url_parser.dart';
import '../widgets/download_queue.dart';
import '../widgets/multi_url_input.dart';
import '../widgets/url_input.dart';

class HomeScreen extends StatefulWidget {
  final DownloadQueueService queueService;
  final SettingsService settingsService;
  final VoidCallback onNavigateToDownloads;

  const HomeScreen({
    super.key,
    required this.queueService,
    required this.settingsService,
    required this.onNavigateToDownloads,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastCheckedClipboard;
  bool _showSingleInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboardOnStartup();
    });
  }

  Future<void> _checkClipboardOnStartup() async {
    if (!widget.settingsService.autoClipboard) return;

    final urls = await ClipboardService.getInstagramUrlsFromClipboard();
    if (urls.isEmpty) return;

    final signature = urls.map((u) => u.shortcode).join(',');
    if (signature == _lastCheckedClipboard) return;
    _lastCheckedClipboard = signature;

    if (!mounted) return;

    if (urls.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Instagram bağlantısı bulundu'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'İNDİR',
            onPressed: () {
              final result = widget.queueService.addUrls(urls);
              if (result.added > 0) {
                widget.queueService.startAll();
              } else if (result.duplicates > 0) {
                _showDuplicateWarning();
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${urls.length} Instagram bağlantısı bulundu'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'TÜMÜNÜ EKLE',
            onPressed: () {
              final result = widget.queueService.addUrls(urls);
              _showAddSummary(result.added, result.duplicates);
            },
          ),
        ),
      );
    }
  }

  void _showAddSummary(int added, int duplicates) {
    if (!mounted) return;
    if (added > 0 && duplicates > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$added bağlantı eklendi. $duplicates bağlantı zaten kuyruktaydı.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added bağlantı indirme kuyruğuna eklendi.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (duplicates > 0) {
      _showDuplicateWarning();
    }
  }

  void _showDuplicateWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu bağlantı zaten indirme kuyruğunda.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleAddLinks(List<InstagramUrl> urls) {
    final result = widget.queueService.addUrls(urls);
    _showAddSummary(result.added, result.duplicates);
  }

  void _handleDownloadAll(List<InstagramUrl> urls) {
    final result = widget.queueService.addUrls(urls);
    if (result.added > 0) {
      widget.queueService.startAll();
    }
    _showAddSummary(result.added, result.duplicates);
  }

  void _handleSingleDownload(InstagramUrl url) {
    final result = widget.queueService.addUrls([url]);
    if (result.added > 0) {
      widget.queueService.startAll();
    } else if (result.duplicates > 0) {
      _showDuplicateWarning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.queueService,
      builder: (context, _) {
        final tasks = widget.queueService.queue;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RL Clicker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Instagram Video Downloader',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSingleInput
                      ? Icons.dynamic_feed_rounded
                      : Icons.link_rounded,
                ),
                tooltip: _showSingleInput
                    ? 'Çoklu Giriş Moduna Geç'
                    : 'Hızlı Tekli Giriş Moduna Geç',
                onPressed: () {
                  setState(() => _showSingleInput = !_showSingleInput);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showSingleInput) ...[
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleUrlInput(
                        onDownload: _handleSingleDownload,
                      ),
                    ),
                  ),
                ] else ...[
                  MultiUrlInput(
                    onAddLinks: _handleAddLinks,
                    onDownloadAll: _handleDownloadAll,
                  ),
                ],
                const SizedBox(height: 20),
                DownloadQueueWidget(
                  tasks: tasks,
                  onStartAll: widget.queueService.startAll,
                  onCancelAll: widget.queueService.cancelAll,
                  onRetryAll: widget.queueService.retryAll,
                  onClearCompleted: widget.queueService.clearInactiveFromQueue,
                  onRetryTask: widget.queueService.retryTask,
                  onCancelTask: widget.queueService.cancelTask,
                  onRemoveTask: widget.queueService.removeTask,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
