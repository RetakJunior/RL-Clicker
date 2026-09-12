import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../utils/url_parser.dart';

class MultiUrlInput extends StatefulWidget {
  final ValueChanged<List<InstagramUrl>> onAddLinks;
  final ValueChanged<List<InstagramUrl>> onDownloadAll;

  const MultiUrlInput({
    super.key,
    required this.onAddLinks,
    required this.onDownloadAll,
  });

  @override
  State<MultiUrlInput> createState() => _MultiUrlInputState();
}

class _MultiUrlInputState extends State<MultiUrlInput> {
  final TextEditingController _controller = TextEditingController();
  List<InstagramUrl> _parsedUrls = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final urls = InstagramUrlParser.parse(_controller.text);
    if (urls.length != _parsedUrls.length) {
      setState(() {
        _parsedUrls = urls;
      });
    }
  }

  Future<void> _handlePasteFromClipboard() async {
    final urls = await ClipboardService.getInstagramUrlsFromClipboard();
    if (urls.isNotEmpty) {
      final joined = urls.map((u) => u.rawUrl).join('\n');
      setState(() {
        if (_controller.text.trim().isEmpty) {
          _controller.text = joined;
        } else {
          _controller.text = '${_controller.text.trim()}\n$joined';
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Panoda geçerli bir Instagram video bağlantısı bulunamadı.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleAddLinks() {
    if (_parsedUrls.isEmpty) return;
    widget.onAddLinks(_parsedUrls);
    _controller.clear();
    setState(() => _parsedUrls = []);
  }

  void _handleDownloadAll() {
    if (_parsedUrls.isEmpty) return;
    final urlsToDownload = List<InstagramUrl>.from(_parsedUrls);
    widget.onDownloadAll(urlsToDownload);
    _controller.clear();
    setState(() => _parsedUrls = []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _parsedUrls.length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Instagram video linklerini gir',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _handlePasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  label: const Text('Panodan Yapıştır'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Her satıra bir URL veya virgülle ayrılmış bağlantılar:\n'
                    'https://instagram.com/reel/AAAA/\n'
                    'https://instagram.com/reel/BBBB/\n'
                    'https://instagram.com/reel/CCCC/',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count bağlantı hazır',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: count > 0 ? _handleAddLinks : null,
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: const Text('LİNKLERİ EKLE'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: count > 0 ? _handleDownloadAll : null,
                    icon: const Icon(Icons.download_for_offline_rounded),
                    label: const Text('TÜMÜNÜ İNDİR'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
