import 'package:flutter_test/flutter_test.dart';
import 'package:rl_clicker/utils/url_validator.dart';

void main() {
  group('UrlValidator Tests', () {
    test('validates standard Instagram reel URLs', () {
      expect(
        UrlValidator.isInstagramUrl(
            'https://www.instagram.com/reel/C8_zXyZ123/'),
        isTrue,
      );
      expect(
        UrlValidator.isInstagramUrl('https://instagram.com/reel/C8_zXyZ123'),
        isTrue,
      );
      expect(
        UrlValidator.isInstagramUrl(
            'http://www.instagram.com/reels/C8_zXyZ123/'),
        isTrue,
      );
    });

    test('validates post and tv URLs', () {
      expect(
        UrlValidator.isInstagramUrl('https://www.instagram.com/p/C8_zXyZ123/'),
        isTrue,
      );
      expect(
        UrlValidator.isInstagramUrl('https://www.instagram.com/tv/C8_zXyZ123/'),
        isTrue,
      );
    });

    test('rejects non-Instagram or invalid URLs', () {
      expect(UrlValidator.isInstagramUrl('https://youtube.com/watch?v=123'),
          isFalse);
      expect(UrlValidator.isInstagramUrl('https://tiktok.com/@user/video/123'),
          isFalse);
      expect(UrlValidator.isInstagramUrl('not a url'), isFalse);
      expect(UrlValidator.isInstagramUrl(''), isFalse);
      expect(UrlValidator.isInstagramUrl(null), isFalse);
    });

    test('extracts shortcode properly', () {
      expect(
        UrlValidator.extractShortcode(
            'https://www.instagram.com/reel/C_aBcDeF/'),
        equals('C_aBcDeF'),
      );
      expect(
        UrlValidator.extractShortcode('https://instagram.com/p/12345XYZ/'),
        equals('12345XYZ'),
      );
    });
  });
}
