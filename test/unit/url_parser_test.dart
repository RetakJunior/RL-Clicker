import 'package:flutter_test/flutter_test.dart';
import 'package:rl_clicker/utils/url_parser.dart';

void main() {
  group('InstagramUrlParser Tests', () {
    test('normalizes single URL and removes tracking params', () {
      const input =
          'https://www.instagram.com/reel/C8_zXyZ123/?utm_source=ig_web_copy_link';
      final parsed = InstagramUrlParser.normalizeSingle(input);
      expect(parsed, isNotNull);
      expect(parsed!.shortcode, equals('C8_zXyZ123'));
      expect(parsed.normalizedUrl,
          equals('https://www.instagram.com/reel/C8_zXyZ123/'));
    });

    test('parses multi URLs separated by newlines, commas and spaces', () {
      const input = '''
https://www.instagram.com/reel/AAAA/
https://www.instagram.com/reel/BBBB/, https://www.instagram.com/p/CCCC/
https://www.instagram.com/reels/DDDD/
''';
      final list = InstagramUrlParser.parse(input);
      expect(list.length, equals(4));
      expect(list[0].shortcode, equals('AAAA'));
      expect(list[1].shortcode, equals('BBBB'));
      expect(list[2].shortcode, equals('CCCC'));
      expect(list[3].shortcode, equals('DDDD'));
    });

    test('deduplicates identical and normalized duplicate URLs', () {
      const input = '''
https://instagram.com/reel/ABC
https://instagram.com/reel/ABC/
https://www.instagram.com/reel/ABC/?igsh=random
https://instagram.com/reel/XYZ/
''';
      final list = InstagramUrlParser.parse(input);
      expect(list.length, equals(2));
      expect(list[0].shortcode, equals('ABC'));
      expect(list[1].shortcode, equals('XYZ'));
    });

    test('returns empty list for empty or invalid input', () {
      expect(InstagramUrlParser.parse(''), isEmpty);
      expect(InstagramUrlParser.parse('   '), isEmpty);
      expect(InstagramUrlParser.parse('hello world test'), isEmpty);
    });
  });
}
