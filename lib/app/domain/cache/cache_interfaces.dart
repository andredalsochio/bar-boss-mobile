// Exporta todas as interfaces de cache
export 'cache_store.dart';
export 'remote_store.dart';
export 'cached_repository.dart';

/// Interface para serviço de imagens com cache
abstract class ImageCacheService {
  /// Obtém uma imagem do cache ou baixa do servidor
  Future<ImageCacheResult> getImage(String imageUrl, {
    ImageSize? size,
    bool forceRefresh = false,
  });

  /// Obtém múltiplas imagens
  Future<List<ImageCacheResult>> getImages(List<String> imageUrls, {
    ImageSize? size,
  });

  /// Faz upload de uma imagem
  Future<String> uploadImage(String localPath, String remotePath, {
    ImageCompression? compression,
    Map<String, String>? metadata,
  });

  /// Faz upload de múltiplas imagens em paralelo
  Future<List<String>> uploadImages(Map<String, String> pathMap, {
    ImageCompression? compression,
    int maxConcurrency = 3,
  });

  /// Remove uma imagem do cache e servidor
  Future<void> removeImage(String imageUrl);

  /// Limpa o cache de imagens
  Future<void> clearCache();

  /// Obtém estatísticas do cache de imagens
  Future<ImageCacheStats> getStats();

  /// Pré-carrega imagens importantes
  Future<void> preloadImages(List<String> imageUrls);

  /// Obtém stream de progresso de upload
  Stream<UploadProgress> uploadWithProgress(String localPath, String remotePath);
}

/// Resultado de operação com imagem
class ImageCacheResult {
  final String? localPath;
  final String? url;
  final ImageSource source;
  final bool isStale;
  final Object? error;

  const ImageCacheResult({
    this.localPath,
    this.url,
    required this.source,
    this.isStale = false,
    this.error,
  });

  bool get hasLocalFile => localPath != null;
  bool get hasUrl => url != null;
  bool get hasError => error != null;
  bool get isFromCache => source == ImageSource.cache;
  bool get isFromNetwork => source == ImageSource.network;
}

/// Fonte da imagem
enum ImageSource {
  cache,
  network,
  none,
}

/// Tamanho da imagem para cache
class ImageSize {
  final int width;
  final int height;
  final bool maintainAspectRatio;

  const ImageSize({
    required this.width,
    required this.height,
    this.maintainAspectRatio = true,
  });

  /// Tamanho de thumbnail
  static const thumbnail = ImageSize(width: 150, height: 150);
  
  /// Tamanho médio
  static const medium = ImageSize(width: 500, height: 500);
  
  /// Tamanho original
  static const original = ImageSize(width: -1, height: -1);

  bool get isOriginal => width == -1 && height == -1;

  @override
  String toString() => isOriginal ? 'original' : '${width}x$height';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageSize &&
        other.width == width &&
        other.height == height &&
        other.maintainAspectRatio == maintainAspectRatio;
  }

  @override
  int get hashCode => Object.hash(width, height, maintainAspectRatio);
}

/// Configuração de compressão de imagem
class ImageCompression {
  final int quality; // 0-100
  final ImageFormat format;
  final int? maxWidth;
  final int? maxHeight;

  const ImageCompression({
    this.quality = 85,
    this.format = ImageFormat.jpeg,
    this.maxWidth,
    this.maxHeight,
  });

  static const high = ImageCompression(quality: 95);
  static const medium = ImageCompression(quality: 85);
  static const low = ImageCompression(quality: 70);
}

/// Formato da imagem
enum ImageFormat {
  jpeg,
  png,
  webp,
}

/// Progresso de upload
class UploadProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double percentage;
  final UploadState state;
  final String? error;

  const UploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.percentage,
    required this.state,
    this.error,
  });

  bool get isCompleted => state == UploadState.completed;
  bool get isError => state == UploadState.error;
  bool get isUploading => state == UploadState.uploading;
}

/// Estado do upload
enum UploadState {
  pending,
  uploading,
  completed,
  error,
  cancelled,
}

/// Estatísticas do cache de imagens
class ImageCacheStats {
  final int totalImages;
  final int cacheSize; // em bytes
  final double hitRate;
  final double missRate;
  final DateTime lastCleanup;
  final Map<ImageSize, int> sizeDistribution;

  const ImageCacheStats({
    required this.totalImages,
    required this.cacheSize,
    required this.hitRate,
    required this.missRate,
    required this.lastCleanup,
    required this.sizeDistribution,
  });

  /// Tamanho do cache em MB
  double get cacheSizeMB => cacheSize / (1024 * 1024);
}