import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../utils/url_parser.dart';
import '../utils/url_validator.dart';

class SingleUrlInput extends StatefulWidget {
  final ValueChanged<InstagramUrl> onDownload;

  const SingleUrlInput({
    super.key,
    required this.onDownload,
  });

  @override
  State<SingleUrlInput> createState() => _SingleUrlInputState();
}

class _SingleUrlInputState extends State<SingleUrlInput> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final urls = await ClipboardService.getInstagramUrlsFromClipboard();
    if (urls.isNotEmpty) {
      setState(() {
        _controller.text = urls.first.rawUrl;
        _errorMessage = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Panoda geçerli bir Instagram bağlantısı bulunamadı.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Lütfen bir Instagram bağlantısı girin.');
      return;
    }

    final parsed = InstagramUrlParser.normalizeSingle(text);
    if (parsed == null || !UrlValidator.isInstagramUrl(parsed.normalizedUrl)) {
      setState(() => _errorMessage =
          'Geçerli bir Instagram Reel veya Video bağlantısı girin.');
      return;
    }

    setState(() => _errorMessage = null);
    _controller.clear();
    widget.onDownload(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'https://www.instagram.com/reel/XXXXXXXX/...',
            labelText: 'Instagram Video / Reel Bağlantısı',
            errorText: _errorMessage,
            prefixIcon: const Icon(Icons.link),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste_rounded),
              tooltip: 'Panodan Yapıştır',
              onPressed: _handlePaste,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _handleSubmit,
          icon: const Icon(Icons.download_rounded),
          label: const Text('İNDİR'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
