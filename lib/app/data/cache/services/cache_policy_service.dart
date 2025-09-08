import 'dart:async';

import 'package:drift/drift.dart';
import '../drift/cache_database.dart';

/// Estratégias de invalidação de cache
enum CacheInvalidationStrategy {
  /// Invalidação baseada em TTL (Time To Live)
  ttl,
  /// Invalidação manual por chave
  manual,
  /// Invalidação por padrão de chaves
  pattern,
  /// Invalidação por tag
  tag,
}

/// Políticas de substituição de cache
enum CacheEvictionPolicy {
  /// Least Recently Used - remove o menos usado recentemente
  lru,
  /// Least Frequently Used - remove o menos usado frequentemente
  lfu,
  /// First In First Out - remove o mais antigo
  fifo,
  /// Random - remove aleatoriamente
  random,
}

/// Configuração de políticas de cache
class CachePolicyConfig {
  /// TTL padrão para entradas de cache
  final Duration defaultTtl;
  
  /// Tamanho máximo do cache em MB
  final int maxSizeInMB;
  
  /// Número máximo de entradas no cache
  final int maxEntries;
  
  /// Política de substituição quando o cache está cheio
  final CacheEvictionPolicy evictionPolicy;
  
  /// Intervalo de limpeza automática
  final Duration cleanupInterval;
  
  /// Percentual de cache a ser limpo quando atingir o limite
  final double cleanupThreshold;

  const CachePolicyConfig({
    this.defaultTtl = const Duration(hours: 1),
    this.maxSizeInMB = 100,
    this.maxEntries = 1000,
    this.evictionPolicy = CacheEvictionPolicy.lru,
    this.cleanupInterval = const Duration(minutes: 15),
    this.cleanupThreshold = 0.8,
  });
}

/// Estatísticas de cache
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final double sizeInMB;
  final int hitCount;
  final int missCount;
  final DateTime lastCleanup;

  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.sizeInMB,
    required this.hitCount,
    required this.missCount,
    required this.lastCleanup,
  });

  double get hitRate => hitCount + missCount > 0 ? hitCount / (hitCount + missCount) : 0.0;
}

/// Serviço de políticas de cache
class CachePolicyService {
  final CacheDatabase _database;
  final CachePolicyConfig _config;
  Timer? _cleanupTimer;
  
  // Contadores para estatísticas
  int _hitCount = 0;
  int _missCount = 0;
  DateTime _lastCleanup = DateTime.now();

  CachePolicyService({
    required CacheDatabase database,
    CachePolicyConfig? config,
  }) : _database = database,
       _config = config ?? const CachePolicyConfig() {
    _startPeriodicCleanup();
  }

  /// Inicia limpeza periódica automática
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Para o serviço e cancela timers
  void dispose() {
    _cleanupTimer?.cancel();
  }

  /// Verifica se uma entrada está expirada
  bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Calcula TTL para uma chave específica
  Duration getTtlForKey(String key) {
    // Aqui você pode implementar lógica específica por tipo de dados
    // Por exemplo, imagens podem ter TTL maior que dados de API
    
    if (key.startsWith('image_')) {
      return const Duration(days: 7);
    } else if (key.startsWith('user_')) {
      return const Duration(hours: 6);
    } else if (key.startsWith('event_')) {
      return const Duration(hours: 2);
    }
    
    return _config.defaultTtl;
  }

  /// Atualiza timestamp de último acesso
  Future<void> updateLastAccessed(String key) async {
    final now = DateTime.now();
    
    // Atualiza CachedData
    await (_database.update(_database.cachedData)
      ..where((tbl) => tbl.key.equals(key)))
        .write(CachedDataCompanion(
          lastAccessed: Value(now),
        ));
    
    // Atualiza CachedImages se for uma imagem
    await (_database.update(_database.cachedImages)
      ..where((tbl) => tbl.remoteUrl.equals(key)))
        .write(CachedImagesCompanion(
          lastAccessedAt: Value(now),
        ));
  }

  /// Invalida entrada específica
  Future<void> invalidateKey(String key) async {
    await _database.transaction(() async {
      // Remove de CachedData
      await (_database.delete(_database.cachedData)
        ..where((tbl) => tbl.key.equals(key))).go();
      
      // Remove de CachedImages se for uma imagem
      await (_database.delete(_database.cachedImages)
        ..where((tbl) => tbl.remoteUrl.equals(key))).go();
    });
  }

  /// Invalida entradas por padrão
  Future<void> invalidatePattern(String pattern) async {
    await _database.transaction(() async {
      // Remove de CachedData
      await (_database.delete(_database.cachedData)
        ..where((tbl) => tbl.key.contains(pattern))).go();
      
      // Remove de CachedImages
      await (_database.delete(_database.cachedImages)
        ..where((tbl) => tbl.remoteUrl.contains(pattern))).go();
    });
  }

  /// Invalida todas as entradas expiradas
  Future<int> invalidateExpired() async {
    final now = DateTime.now();
    int removedCount = 0;
    
    await _database.transaction(() async {
      // Remove CachedData expirados
      final expiredData = await (_database.delete(_database.cachedData)
        ..where((tbl) => tbl.expiresAt.isSmallerThan(Variable(now)))).go();
      
      // Remove CachedImages expirados
      final expiredImages = await (_database.delete(_database.cachedImages)
        ..where((tbl) => tbl.cacheExpiresAt.isSmallerThan(Variable(now)))).go();
      
      removedCount = expiredData + expiredImages;
    });
    
    return removedCount;
  }

  /// Aplica política de substituição LRU
  Future<int> applyLruEviction(int targetCount) async {
    int removedCount = 0;
    
    await _database.transaction(() async {
      // Remove entradas menos acessadas de CachedData
      final oldestData = await (_database.select(_database.cachedData)
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.lastAccessed)])
        ..limit(targetCount)).get();
      
      for (final entry in oldestData) {
        await (_database.delete(_database.cachedData)
          ..where((tbl) => tbl.key.equals(entry.key))).go();
        removedCount++;
      }
      
      // Remove imagens menos acessadas
      final remainingToRemove = targetCount - removedCount;
      if (remainingToRemove > 0) {
        final oldestImages = await (_database.select(_database.cachedImages)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lastAccessedAt)])
          ..limit(remainingToRemove)).get();
        
        for (final image in oldestImages) {
          await (_database.delete(_database.cachedImages)
            ..where((tbl) => tbl.id.equals(image.id))).go();
          removedCount++;
        }
      }
    });
    
    return removedCount;
  }

  /// Executa limpeza automática
  Future<void> _performCleanup() async {
    try {
      _lastCleanup = DateTime.now();
      
      // 1. Remove entradas expiradas
      final expiredCount = await invalidateExpired();
      
      // 2. Verifica se precisa aplicar política de substituição
      final stats = await getCacheStats();
      
      if (stats.totalEntries > _config.maxEntries) {
        final targetRemoval = (stats.totalEntries * (1 - _config.cleanupThreshold)).round();
        await applyLruEviction(targetRemoval);
      }
      
      // TODO: Implementar logging
      // Logger.info('Cache cleanup completed: $expiredCount expired entries removed');
      
    } catch (e) {
      // TODO: Implementar logging
      // Logger.error('Error during cache cleanup: $e');
    }
  }

  /// Força limpeza manual
  Future<void> forceCleanup() async {
    await _performCleanup();
  }

  /// Limpa todo o cache
  Future<void> clearAll() async {
    await _database.transaction(() async {
      await _database.delete(_database.cachedData).go();
      await _database.delete(_database.cachedImages).go();
      await _database.delete(_database.cacheMetrics).go();
    });
    
    _hitCount = 0;
    _missCount = 0;
  }

  /// Registra hit de cache
  void recordHit() {
    _hitCount++;
  }

  /// Registra miss de cache
  void recordMiss() {
    _missCount++;
  }

  /// Obtém estatísticas do cache
  Future<CacheStats> getCacheStats() async {
    // Conta entradas em CachedData
    final dataEntries = await _database.select(_database.cachedData).get();
    final dataCount = dataEntries.length;
    
    // Conta imagens em CachedImages
    final imageEntries = await _database.select(_database.cachedImages).get();
    final imageCount = imageEntries.length;
    
    // Conta entradas expiradas
    final now = DateTime.now();
    final expiredDataEntries = await (_database.select(_database.cachedData)
      ..where((tbl) => tbl.expiresAt.isSmallerThan(Variable(now)))).get();
    
    final expiredImageEntries = await (_database.select(_database.cachedImages)
      ..where((tbl) => tbl.cacheExpiresAt.isSmallerThan(Variable(now)))).get();
    
    // Calcula tamanho total das imagens
     int totalSizeInBytes = 0;
     for (final image in imageEntries) {
       totalSizeInBytes += image.fileSizeBytes;
     }
    
    final totalEntries = dataCount + imageCount;
    final expiredEntries = expiredDataEntries.length + expiredImageEntries.length;
    
    return CacheStats(
      totalEntries: totalEntries,
      expiredEntries: expiredEntries,
      sizeInMB: totalSizeInBytes / (1024 * 1024),
      hitCount: _hitCount,
      missCount: _missCount,
      lastCleanup: _lastCleanup,
    );
  }

  /// Obtém configuração atual
  CachePolicyConfig get config => _config;
}