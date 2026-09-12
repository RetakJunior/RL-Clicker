import 'url_validator.dart';

class InstagramUrl {
  final String rawUrl;
  final String normalizedUrl;
  final String shortcode;
  final String type; // 'reel', 'p', 'tv'

  const InstagramUrl({
    required this.rawUrl,
    required this.normalizedUrl,
    required this.shortcode,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstagramUrl &&
          runtimeType == other.runtimeType &&
          shortcode == other.shortcode;

  @override
  int get hashCode => shortcode.hashCode;

  @override
  String toString() => normalizedUrl;
}

class InstagramUrlParser {
  static final RegExp _urlExtractorRegex = RegExp(
    r'(https?:\/\/[^\s,;]+|instagram\.com\/[^\s,;]+|instagr\.am\/[^\s,;]+)',
    caseSensitive: false,
  );

  /// Parses text containing one or multiple Instagram URLs separated by newlines, commas, or spaces.
  /// Deduplicates by shortcode and returns a normalized list.
  static List<InstagramUrl> parse(String input) {
    if (input.trim().isEmpty) return [];

    final List<InstagramUrl> results = [];
    final Set<String> seenShortcodes = {};

    // First, split by obvious delimiters like newlines, commas, semicolons
    final tokens = input.split(RegExp(r'[\r\n,;]+'));

    for (final rawToken in tokens) {
      final token = rawToken.trim();
      if (token.isEmpty) continue;

      // Extract URLs from the token (handles spaces or embedded text)
      final matches = _urlExtractorRegex.allMatches(token);
      if (matches.isEmpty) {
        // Test if the token itself is a URL directly
        _processPotentialUrl(token, seenShortcodes, results);
      } else {
        for (final match in matches) {
          final matchedStr = match.group(0);
          if (matchedStr != null) {
            _processPotentialUrl(matchedStr, seenShortcodes, results);
          }
        }
      }
    }

    return results;
  }

  static void _processPotentialUrl(
    String raw,
    Set<String> seenShortcodes,
    List<InstagramUrl> results,
  ) {
    var cleaned = raw.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }

    if (!UrlValidator.isInstagramUrl(cleaned)) {
      return;
    }

    final shortcode = UrlValidator.extractShortcode(cleaned);
    final rawType = UrlValidator.extractContentType(cleaned);
    if (shortcode == null || shortcode.isEmpty) return;

    if (seenShortcodes.contains(shortcode)) {
      // Duplicate ignored
      return;
    }

    final type = (rawType == 'reels') ? 'reel' : (rawType ?? 'reel');
    final normalized = 'https://www.instagram.com/$type/$shortcode/';

    seenShortcodes.add(shortcode);
    results.add(InstagramUrl(
      rawUrl: raw,
      normalizedUrl: normalized,
      shortcode: shortcode,
      type: type,
    ));
  }

  /// Normalizes a single URL string. Returns null if invalid.
  static InstagramUrl? normalizeSingle(String url) {
    final list = parse(url);
    if (list.isEmpty) return null;
    return list.first;
  }
}
