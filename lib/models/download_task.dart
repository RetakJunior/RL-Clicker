enum DownloadTaskStatus {
  queued,
  resolving,
  downloading,
  completed,
  failed,
  cancelled;

  String get labelTr {
    switch (this) {
      case DownloadTaskStatus.queued:
        return 'Bekliyor...';
      case DownloadTaskStatus.resolving:
        return 'Çözümleniyor...';
      case DownloadTaskStatus.downloading:
        return 'İndiriliyor...';
      case DownloadTaskStatus.completed:
        return 'Tamamlandı ✓';
      case DownloadTaskStatus.failed:
        return 'Hata oluştu ✗';
      case DownloadTaskStatus.cancelled:
        return 'İptal edildi';
    }
  }
}

class DownloadTask {
  final String id;
  final String sourceUrl;
  final String title;
  final String? thumbnail;
  final DownloadTaskStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // bytes/s
  final String? filePath;
  final String? error;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.sourceUrl,
    required this.title,
    this.thumbnail,
    this.status = DownloadTaskStatus.queued,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speed = 0.0,
    this.filePath,
    this.error,
    required this.createdAt,
    this.completedAt,
  });

  DownloadTask copyWith({
    String? id,
    String? sourceUrl,
    String? title,
    String? thumbnail,
    DownloadTaskStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speed,
    String? filePath,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speed: speed ?? this.speed,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceUrl': sourceUrl,
        'title': title,
        'thumbnail': thumbnail,
        'status': status.name,
        'progress': progress,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'speed': speed,
        'filePath': filePath,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String,
        sourceUrl: json['sourceUrl'] as String,
        title: json['title'] as String,
        thumbnail: json['thumbnail'] as String?,
        status: DownloadTaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DownloadTaskStatus.failed,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        downloadedBytes: json['downloadedBytes'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
        filePath: json['filePath'] as String?,
        error: json['error'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );
}
