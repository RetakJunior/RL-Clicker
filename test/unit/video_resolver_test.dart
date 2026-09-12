import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rl_clicker/services/video_resolver.dart';
import 'package:rl_clicker/utils/error_utils.dart';

void main() {
  group('InstagramResolver Tests', () {
    test('resolves video successfully from crawler BaseURL DASH manifest',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('DdGZb5sRY3b')) {
          const sampleHtml = '''
            <!DOCTYPE html><html><head></head><body>
            <script>
            BaseURL>https:\\/\\/instagram.fbcdn.net\\/video.mp4?test=1&amp;token=abc\\u00253D\\u00253D\\u003C\\/BaseURL>
            "caption":{"text":"Test Caption"}
            "username":"test_creator"
            </script>
            </body></html>
          ''';
          return http.Response(sampleHtml, 200);
        }
        return http.Response('Not found', 404);
      });

      final resolver = InstagramResolver(client: mockClient);
      final video =
          await resolver.resolve('https://www.instagram.com/reel/DdGZb5sRY3b/');

      expect(video.videoUrl,
          'https://instagram.fbcdn.net/video.mp4?test=1&token=abc==');
      expect(video.title, 'Test Caption');
      expect(video.author, 'test_creator');
    });

    test('throws ResolverException on 404 or PolarisErrorRoute', () async {
      final mockClient = MockClient((request) async {
        const errorHtml = '''
          <!DOCTYPE html><html><body>
          "canonicalRouteName":"comet.igweb.PolarisErrorRoute"
          "page_logging":{"name":"httpErrorPage"}
          </body></html>
        ''';
        return http.Response(errorHtml, 200);
      });

      final resolver = InstagramResolver(client: mockClient);
      expect(
        () => resolver.resolve('https://www.instagram.com/reel/DeletedReel/'),
        throwsA(isA<ResolverException>().having(
          (e) => e.message,
          'message',
          contains('İçerik bulunamadı veya silinmiş'),
        )),
      );
    });

    test('throws ResolverException on private or login restricted content',
        () async {
      final mockClient = MockClient((request) async {
        const restrictedHtml = '''
          <!DOCTYPE html><html><body>
          <div class="login-wall">Restricted content login required</div>
          </body></html>
        ''';
        return http.Response(restrictedHtml, 200);
      });

      final resolver = InstagramResolver(client: mockClient);
      expect(
        () => resolver.resolve('https://www.instagram.com/reel/PrivateReel/'),
        throwsA(isA<ResolverException>().having(
          (e) => e.isPrivateOrRestricted,
          'isPrivateOrRestricted',
          isTrue,
        )),
      );
    });
  });
}
