import 'package:flutter/services.dart';
import '../utils/url_parser.dart';

class ClipboardService {
  /// Reads system clipboard text and parses any valid public Instagram URLs.
  /// Does not store, log, or persist clipboard content.
  static Future<List<InstagramUrl>> getInstagramUrlsFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) {
        return [];
      }
      return InstagramUrlParser.parse(text);
    } catch (_) {
      // In case of clipboard security exceptions or platform limitations
      return [];
    }
  }

  /// Clears or checks if clipboard has any string data without logging it.
  static Future<bool> hasText() async {
    try {
      return await Clipboard.hasStrings();
    } catch (_) {
      return false;
    }
  }
}
