import 'dart:io';

class ResolverException implements Exception {
  final String message;
  final String? originalUrl;
  final bool isPrivateOrRestricted;
  final bool isNotVideo;

  const ResolverException(
    this.message, {
    this.originalUrl,
    this.isPrivateOrRestricted = false,
    this.isNotVideo = false,
  });

  @override
  String toString() => message;
}

class ErrorUtils {
  static String mapError(dynamic error) {
    if (error is ResolverException) {
      return error.message;
    }

    if (error is SocketException) {
      return 'İnternet bağlantınızı kontrol edin.';
    }

    if (error is HttpException) {
      return 'Ağ isteği başarısız oldu (${error.message}).';
    }

    final str = error.toString().toLowerCase();
    if (str.contains('timed out') || str.contains('timeout')) {
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    if (str.contains('connection refused') ||
        str.contains('network is unreachable')) {
      return 'Sunucuya ulaşılamıyor veya ağ bağlantısı yok.';
    }

    if (str.contains('permission denied')) {
      return 'Depolama erişim izni verilmedi.';
    }

    return 'Bir hata oluştu: ${error.toString()}';
  }
}
