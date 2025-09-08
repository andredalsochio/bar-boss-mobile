import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';

import '../../../domain/cache/cache_interfaces.dart';
import '../drift/cache_database.dart';

/// Implementação do serviço de cache de imagens
class ImageCacheServiceImpl implements ImageCacheService {
  final CacheDatabase _database;
  late final Directory _cacheDir;
  bool _initialized = false;

  ImageCacheServiceImpl(this._database);

  /// Inicializa o serviço criando diretórios necessários
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'image_cache'));
    
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }

    _initialized = true;
  }

  @override
  Future<ImageCacheResult> getImage(
    String imageUrl, {
    ImageSize? size,
    bool forceRefresh = false,
  }) async {
    await _ensureInitialized();
    
    try {
      final imageId = _generateImageId(imageUrl, size);
      final sizeKey = size?.toString() ?? 'original';
      
      // Verifica se existe no cache e não está expirado
      if (!forceRefresh) {
        final cached = await _getCachedImage(imageId);
        if (cached != null && !_isExpired(cached)) {
          // Atualiza último acesso
          await _updateLastAccessed(imageId);
          
          final file = File(cached.localPath);
          if (await file.exists()) {
            return ImageCacheResult(
              localPath: cached.localPath,
              url: imageUrl,
              source: ImageSource.cache,
              isStale: false,
            );
          }
        }
      }
      
      // Download da imagem
      final downloadResult = await _downloadImage(imageUrl);
      if (downloadResult == null) {
        return ImageCacheResult(
          url: imageUrl,
          source: ImageSource.none,
          error: 'Falha no download da imagem',
        );
      }
      
      // Processa a imagem (redimensiona se necessário)
      final processedData = await _processImage(downloadResult.data, size);
      
      // Salva no cache
      final localPath = await _saveToCache(imageId, processedData, downloadResult.contentType);
      
      // Salva metadados no banco
      await _saveCacheMetadata(
        imageId,
        imageUrl,
        localPath,
        sizeKey,
        processedData.length,
        downloadResult.contentType,
      );
      
      return ImageCacheResult(
        localPath: localPath,
        url: imageUrl,
        source: ImageSource.network,
        isStale: false,
      );
      
    } catch (e) {
      return ImageCacheResult(
        url: imageUrl,
        source: ImageSource.none,
        error: e.toString(),
      );
    }
  }

  @override
  Future<List<ImageCacheResult>> getImages(
    List<String> imageUrls, {
    ImageSize? size,
  }) async {
    final results = <ImageCacheResult>[];
    
    // Processa em paralelo com limite de concorrência
    const maxConcurrency = 5;
    for (int i = 0; i < imageUrls.length; i += maxConcurrency) {
      final batch = imageUrls.skip(i).take(maxConcurrency);
      final batchResults = await Future.wait(
        batch.map((url) => getImage(url, size: size)),
      );
      results.addAll(batchResults);
    }
    
    return results;
  }

  @override
  Future<String> uploadImage(
    String localPath,
    String remotePath, {
    ImageCompression? compression,
    Map<String, String>? metadata,
  }) async {
    // Esta implementação seria integrada com Firebase Storage
    // Por enquanto, retorna uma URL simulada
    throw UnimplementedError('Upload será implementado com Firebase Storage');
  }

  @override
  Future<List<String>> uploadImages(
    Map<String, String> pathMap, {
    ImageCompression? compression,
    int maxConcurrency = 3,
  }) async {
    throw UnimplementedError('Upload será implementado com Firebase Storage');
  }

  @override
  Future<void> removeImage(String imageUrl) async {
    await _ensureInitialized();
    
    // Remove todas as versões da imagem (original, thumbnail, etc.)
    final images = _database.select(_database.cachedImages)
      ..where((tbl) => tbl.remoteUrl.equals(imageUrl));
    
    final cachedImages = await images.get();
    
    for (final cached in cachedImages) {
      // Remove arquivo do disco
      final file = File(cached.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove do banco
      await (_database.delete(_database.cachedImages)
        ..where((tbl) => tbl.id.equals(cached.id))).go();
    }
  }

  @override
  Future<void> clearCache() async {
    await _ensureInitialized();
    
    // Remove todos os arquivos
    if (await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create(recursive: true);
    }
    
    // Limpa banco
    await _database.delete(_database.cachedImages).go();
  }

  @override
  Future<ImageCacheStats> getStats() async {
    await _ensureInitialized();
    
    final images = await _database.select(_database.cachedImages).get();
    final totalSize = images.fold<int>(0, (sum, img) => sum + img.fileSizeBytes);
    
    // Calcula distribuição por tamanho
    final sizeDistribution = <ImageSize, int>{};
    for (final image in images) {
      final size = _parseImageSize(image.size);
      sizeDistribution[size] = (sizeDistribution[size] ?? 0) + 1;
    }
    
    return ImageCacheStats(
      totalImages: images.length,
      cacheSize: totalSize,
      hitRate: 0.0, // Seria calculado com métricas de acesso
      missRate: 0.0,
      lastCleanup: DateTime.now(),
      sizeDistribution: sizeDistribution,
    );
  }

  @override
  Future<void> preloadImages(List<String> imageUrls) async {
    // Baixa imagens em background sem bloquear
    for (final url in imageUrls) {
      getImage(url).catchError((e) {
        // Ignora erros no preload
        return ImageCacheResult(
          url: url,
          source: ImageSource.none,
          error: e.toString(),
        );
      });
    }
  }

  @override
  Stream<UploadProgress> uploadWithProgress(
    String localPath,
    String remotePath,
  ) {
    throw UnimplementedError('Upload será implementado com Firebase Storage');
  }

  // Métodos privados
  
  String _generateImageId(String url, ImageSize? size) {
    final sizeKey = size?.toString() ?? 'original';
    final combined = '$url:$sizeKey';
    return sha256.convert(utf8.encode(combined)).toString();
  }
  
  Future<CachedImage?> _getCachedImage(String imageId) async {
    final query = _database.select(_database.cachedImages)
      ..where((tbl) => tbl.id.equals(imageId));
    
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }
  
  bool _isExpired(CachedImage cached) {
    if (cached.cacheExpiresAt == null) return false;
    return DateTime.now().isAfter(cached.cacheExpiresAt!);
  }
  
  Future<void> _updateLastAccessed(String imageId) async {
    await (_database.update(_database.cachedImages)
      ..where((tbl) => tbl.id.equals(imageId)))
      .write(CachedImagesCompanion(
        lastAccessedAt: Value(DateTime.now()),
        cacheUpdatedAt: Value(DateTime.now()),
      ));
  }
  
  Future<_DownloadResult?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return _DownloadResult(
          data: response.bodyBytes,
          contentType: response.headers['content-type'] ?? 'image/jpeg',
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<Uint8List> _processImage(Uint8List data, ImageSize? size) async {
    // Por enquanto, retorna a imagem original
    // TODO: Implementar redimensionamento quando adicionar package:image
    return data;
  }
  
  Future<String> _saveToCache(String imageId, Uint8List data, String contentType) async {
    final extension = _getExtensionFromContentType(contentType);
    final fileName = '$imageId$extension';
    final file = File(path.join(_cacheDir.path, fileName));
    
    await file.writeAsBytes(data);
    return file.path;
  }
  
  Future<void> _saveCacheMetadata(
    String imageId,
    String remoteUrl,
    String localPath,
    String size,
    int fileSize,
    String contentType,
  ) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7)); // TTL de 7 dias
    
    await _database.into(_database.cachedImages).insertOnConflictUpdate(
      CachedImagesCompanion(
        id: Value(imageId),
        remoteUrl: Value(remoteUrl),
        localPath: Value(localPath),
        size: Value(size),
        fileSizeBytes: Value(fileSize),
        contentType: Value(contentType),
        downloadedAt: Value(now),
        lastAccessedAt: Value(now),
        cacheCreatedAt: Value(now),
        cacheUpdatedAt: Value(now),
        cacheExpiresAt: Value(expiresAt),
        needsSync: const Value(false),
        version: const Value(1),
      ),
    );
  }
  
  String _getExtensionFromContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }
  
  ImageSize _parseImageSize(String sizeStr) {
    if (sizeStr == 'original') return ImageSize.original;
    if (sizeStr == '150x150') return ImageSize.thumbnail;
    if (sizeStr == '500x500') return ImageSize.medium;
    
    final parts = sizeStr.split('x');
    if (parts.length == 2) {
      final width = int.tryParse(parts[0]) ?? -1;
      final height = int.tryParse(parts[1]) ?? -1;
      return ImageSize(width: width, height: height);
    }
    
    return ImageSize.original;
  }
}

/// Resultado do download de imagem
class _DownloadResult {
  final Uint8List data;
  final String contentType;
  
  const _DownloadResult({
    required this.data,
    required this.contentType,
  });
}