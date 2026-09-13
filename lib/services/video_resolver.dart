import 'package:http/http.dart' as http;
import '../models/resolved_video.dart';
import '../utils/error_utils.dart';
import '../utils/url_validator.dart';

abstract class VideoResolver {
  Future<ResolvedVideo> resolve(String url);
}

class InstagramResolver implements VideoResolver {
  final http.Client _client;

  InstagramResolver({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _crawlerHeaders = {
    'User-Agent':
        'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  static const Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
  };

  @override
  Future<ResolvedVideo> resolve(String url) async {
    final shortcode = UrlValidator.extractShortcode(url);
    if (shortcode == null || shortcode.isEmpty) {
      throw ResolverException(
        'Geçersiz Instagram bağlantısı.',
        originalUrl: url,
      );
    }

    // Attempt 1: Server-side rendered public Reel/Post page via search indexer headers (Fastest & Most reliable)
    try {
      final crawlerResult = await _resolveFromCrawler(shortcode, url);
      if (crawlerResult != null) {
        return crawlerResult;
      }
    } catch (e) {
      if (e is ResolverException) rethrow;
    }

    // Attempt 2: Public embed endpoint
    try {
      final embedResult = await _resolveFromEmbed(shortcode, url);
      if (embedResult != null) {
        return embedResult;
      }
    } catch (e) {
      if (e is ResolverException) rethrow;
    }

    // Attempt 3: Standard page HTML
    try {
      final pageResult = await _resolveFromPageHtml(shortcode, url);
      if (pageResult != null) {
        return pageResult;
      }
    } catch (e) {
      if (e is ResolverException) rethrow;
    }

    throw ResolverException(
      'Instagram içeriği şu anda çözümlenemedi veya video içermiyor.',
      originalUrl: url,
    );
  }

  /// Resolves video from Instagram's pre-rendered crawler page.
  /// This extracts the direct MP4 URL from the DASH manifest or video tags
  /// without requiring login, credentials or bypassing restrictions.
  Future<ResolvedVideo?> _resolveFromCrawler(
      String shortcode, String originalUrl) async {
    final targetUrls = [
      'https://www.instagram.com/reel/$shortcode/',
      'https://www.instagram.com/p/$shortcode/',
    ];

    for (final targetUrl in targetUrls) {
      try {
        final response = await _client
            .get(Uri.parse(targetUrl), headers: _crawlerHeaders)
            .timeout(const Duration(seconds: 14));

        if (response.statusCode == 404) {
          throw ResolverException(
            'İçerik bulunamadı veya silinmiş.',
            originalUrl: originalUrl,
          );
        }

        if (response.statusCode != 200) continue;

        final html = response.body;

        // 1. Look for BaseURL MP4 in DASH manifest (both video and audio)
        final dashRegex =
            RegExp(r'BaseURL>(https:[^<]+?)(?:\\u003C|\\u003C|<)');
        final dashMatches = dashRegex.allMatches(html);
        String? videoUrl;
        String? audioUrl;

        for (final m in dashMatches) {
          final rawUrl = m.group(1)!;
          final cleanUrl = _cleanJsonEscapedUrl(rawUrl);
          final start = (m.start - 500).clamp(0, html.length);
          final ctx = html.substring(start, m.start).toLowerCase();

          if (ctx.contains('audio') &&
              (ctx.contains('mimetype') || ctx.contains('contenttype'))) {
            audioUrl ??= cleanUrl;
          } else {
            videoUrl ??= cleanUrl;
          }
        }

        // 2. Look for "video_url":"..."
        if (videoUrl == null) {
          final videoUrlRegex = RegExp(r'"video_url":"([^"]+)"');
          final vMatch = videoUrlRegex.firstMatch(html);
          if (vMatch != null) {
            videoUrl = _cleanJsonEscapedUrl(vMatch.group(1)!);
          }
        }

        // 3. Look for "contentUrl":"..."
        if (videoUrl == null) {
          final contentUrlRegex = RegExp(r'"contentUrl":"([^"]+)"');
          final cMatch = contentUrlRegex.firstMatch(html);
          if (cMatch != null) {
            videoUrl = _cleanJsonEscapedUrl(cMatch.group(1)!);
          }
        }

        // 4. Look for generic MP4 URL in page
        if (videoUrl == null) {
          final generalMp4Regex = RegExp(
              r'''(https?:(?:\\/\\/|\/\/)[^"'\s<>\\]+?\.mp4[^"'\s<>\\]*)''');
          final gMatch = generalMp4Regex.firstMatch(html);
          if (gMatch != null) {
            videoUrl = _cleanJsonEscapedUrl(gMatch.group(1)!);
          }
        }

        if (videoUrl != null && videoUrl.isNotEmpty) {
          // Extract caption / title
          String title = 'Instagram Reel';
          final captionRegex = RegExp(r'"caption":\{"text":"([^"]+)"');
          final capMatch = captionRegex.firstMatch(html);
          if (capMatch != null) {
            title = _decodeUnicode(capMatch.group(1)!);
          } else {
            final ogTitle = RegExp(
              r'''<meta\s+property=["']og:title["']\s+content=["']([^"']+)["']''',
              caseSensitive: false,
            ).firstMatch(html);
            if (ogTitle != null) {
              title = ogTitle.group(1) ?? 'Instagram Video';
            }
          }

          // Extract author
          String? author;
          final userRegex = RegExp(r'"username":"([^"]+)"');
          final userMatch = userRegex.firstMatch(html);
          if (userMatch != null) {
            author = userMatch.group(1);
          }

          // Extract thumbnail
          String? thumbUrl;
          final ogImg = RegExp(
            r'''<meta\s+property=["']og:image["']\s+content=["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(html);
          if (ogImg != null) {
            thumbUrl = _cleanJsonEscapedUrl(ogImg.group(1)!);
          }

          return ResolvedVideo(
            videoUrl: videoUrl,
            audioUrl: audioUrl,
            thumbnailUrl: thumbUrl,
            title: title.isEmpty ? 'Instagram Video' : title,
            author: author,
            originalUrl: originalUrl,
          );
        }

        // If no video found, check if 404 error route or private/login wall was returned
        if (html.contains('PolarisErrorRoute') ||
            html.contains('show_lox_redesigned_404_page')) {
          throw ResolverException(
            'İçerik bulunamadı veya silinmiş.',
            originalUrl: originalUrl,
          );
        }

        if (html.contains('login') && html.contains('Restricted')) {
          throw ResolverException(
            'Bu içerik gizli veya oturum açma gerektiriyor. RL Clicker yalnızca herkese açık videoları destekler.',
            originalUrl: originalUrl,
            isPrivateOrRestricted: true,
          );
        }
      } catch (e) {
        if (e is ResolverException) rethrow;
      }
    }

    return null;
  }

  Future<ResolvedVideo?> _resolveFromEmbed(
      String shortcode, String originalUrl) async {
    final embedUrl = 'https://www.instagram.com/p/$shortcode/embed/captioned/';
    final response = await _client
        .get(Uri.parse(embedUrl), headers: _browserHeaders)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 404) {
      throw ResolverException(
        'İçerik bulunamadı veya silinmiş.',
        originalUrl: originalUrl,
      );
    }

    final html = response.body;

    if (html.contains('login') && html.contains('Restricted')) {
      throw ResolverException(
        'Bu içerik gizli veya oturum açma gerektiriyor. RL Clicker yalnızca herkese açık videoları destekler.',
        originalUrl: originalUrl,
        isPrivateOrRestricted: true,
      );
    }

    final videoUrlRegex = RegExp(r'"video_url":"(https?:\\\/\\\/[^"]+)"');
    final match = videoUrlRegex.firstMatch(html);
    if (match != null) {
      final rawVideoUrl = match.group(1)!.replaceAll(r'\/', '/');
      final videoUrl = _cleanJsonEscapedUrl(rawVideoUrl);

      final thumbMatch =
          RegExp(r'"display_url":"(https?:\\\/\\\/[^"]+)"').firstMatch(html);
      final thumbUrl = thumbMatch != null
          ? _cleanJsonEscapedUrl(thumbMatch.group(1)!.replaceAll(r'\/', '/'))
          : null;

      final titleMatch =
          RegExp(r'<div class="Caption"[^>]*>(.*?)<\/div>', dotAll: true)
              .firstMatch(html);
      var title = 'Instagram Reel';
      if (titleMatch != null) {
        title = _stripHtml(titleMatch.group(1) ?? 'Instagram Reel');
      }

      final authorMatch =
          RegExp(r'<a class="UsernameText"[^>]*>([^<]+)<\/a>').firstMatch(html);
      final author = authorMatch?.group(1)?.trim();

      return ResolvedVideo(
        videoUrl: videoUrl,
        thumbnailUrl: thumbUrl,
        title: title.isEmpty ? 'Instagram Video' : title,
        author: author,
        originalUrl: originalUrl,
      );
    }

    final videoSrcRegex = RegExp(r'<video[^>]+src="([^"]+)"');
    final srcMatch = videoSrcRegex.firstMatch(html);
    if (srcMatch != null) {
      final videoUrl = srcMatch.group(1)!.replaceAll('&amp;', '&');
      return ResolvedVideo(
        videoUrl: videoUrl,
        title: 'Instagram Video',
        originalUrl: originalUrl,
      );
    }

    return null;
  }

  Future<ResolvedVideo?> _resolveFromPageHtml(
      String shortcode, String originalUrl) async {
    final pageUrl = 'https://www.instagram.com/p/$shortcode/';
    final response = await _client
        .get(Uri.parse(pageUrl), headers: _browserHeaders)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    final html = response.body;

    final regex = RegExp(r'"video_url":"(https?:\\\/\\\/[^"]+)"');
    final match = regex.firstMatch(html);
    if (match != null) {
      final videoUrl = _cleanJsonEscapedUrl(match.group(1)!);
      return ResolvedVideo(
        videoUrl: videoUrl,
        title: 'Instagram Video',
        originalUrl: originalUrl,
      );
    }

    return null;
  }

  String _decodeUnicode(String input) {
    try {
      return input.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
        final hex = match.group(1)!;
        final code = int.parse(hex, radix: 16);
        return String.fromCharCode(code);
      });
    } catch (_) {
      return input;
    }
  }

  String _cleanJsonEscapedUrl(String url) {
    var u = url.replaceAll(r'\/', '/');
    u = u.replaceAll(r'\u0026', '&');
    u = u.replaceAll('&amp;', '&');
    u = u.replaceAll(r'\u00253D', '=');
    return u;
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

/// Mock resolver for testing without network calls
class MockVideoResolver implements VideoResolver {
  final Duration delay;
  final bool shouldFail;
  final String? failureMessage;

  MockVideoResolver({
    this.delay = const Duration(milliseconds: 100),
    this.shouldFail = false,
    this.failureMessage,
  });

  @override
  Future<ResolvedVideo> resolve(String url) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (shouldFail) {
      throw ResolverException(
        failureMessage ?? 'Instagram içeriği şu anda çözümlenemedi.',
        originalUrl: url,
      );
    }

    final shortcode = UrlValidator.extractShortcode(url) ?? 'MOCK123';

    return ResolvedVideo(
      videoUrl: 'https://example.com/videos/$shortcode.mp4',
      thumbnailUrl: 'https://example.com/thumbs/$shortcode.jpg',
      title: 'Instagram Reel $shortcode',
      author: 'creator_$shortcode',
      originalUrl: url,
      estimatedSize: 1024 * 1024 * 12, // 12 MB
    );
  }
}
