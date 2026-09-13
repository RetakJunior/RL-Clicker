class ResolvedVideo {
  final String videoUrl;
  final String? audioUrl;
  final String? thumbnailUrl;
  final String title;
  final String? author;
  final String originalUrl;
  final String mimeType;
  final int? estimatedSize;

  const ResolvedVideo({
    required this.videoUrl,
    this.audioUrl,
    this.thumbnailUrl,
    required this.title,
    this.author,
    required this.originalUrl,
    this.mimeType = 'video/mp4',
    this.estimatedSize,
  });

  Map<String, dynamic> toJson() => {
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'thumbnailUrl': thumbnailUrl,
        'title': title,
        'author': author,
        'originalUrl': originalUrl,
        'mimeType': mimeType,
        'estimatedSize': estimatedSize,
      };

  factory ResolvedVideo.fromJson(Map<String, dynamic> json) => ResolvedVideo(
        videoUrl: json['videoUrl'] as String,
        audioUrl: json['audioUrl'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        title: json['title'] as String,
        author: json['author'] as String?,
        originalUrl: json['originalUrl'] as String,
        mimeType: json['mimeType'] as String? ?? 'video/mp4',
        estimatedSize: json['estimatedSize'] as int?,
      );
}
