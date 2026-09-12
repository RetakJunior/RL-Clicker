import '../models/resolved_video.dart';
import '../utils/url_parser.dart';
import '../utils/url_validator.dart';
import 'video_resolver.dart';

class InstagramService {
  final VideoResolver resolver;

  InstagramService({VideoResolver? videoResolver})
      : resolver = videoResolver ?? InstagramResolver();

  bool isValidUrl(String url) => UrlValidator.isInstagramUrl(url);

  List<InstagramUrl> parseUrls(String text) => InstagramUrlParser.parse(text);

  Future<ResolvedVideo> resolveVideo(String url) => resolver.resolve(url);
}
