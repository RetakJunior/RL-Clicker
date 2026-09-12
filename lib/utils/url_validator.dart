class UrlValidator {
  static final RegExp _instagramUrlRegex = RegExp(
    r'^(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(reel|reels|p|tv)\/([A-Za-z0-9_-]+)',
    caseSensitive: false,
  );

  /// Checks whether a given string is a valid Instagram Reel, Video post or TV link.
  static bool isInstagramUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }
    final trimmed = url.trim();
    return _instagramUrlRegex.hasMatch(trimmed);
  }

  /// Extracts the shortcode (ID) from an Instagram URL.
  static String? extractShortcode(String url) {
    final match = _instagramUrlRegex.firstMatch(url.trim());
    if (match != null && match.groupCount >= 5) {
      return match.group(5);
    }
    return null;
  }

  /// Extracts the type ('reel', 'reels', 'p', 'tv')
  static String? extractContentType(String url) {
    final match = _instagramUrlRegex.firstMatch(url.trim());
    if (match != null && match.groupCount >= 4) {
      return match.group(4)?.toLowerCase();
    }
    return null;
  }
}
