import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';

import '../drift/cache_database.dart';

/// Estratégias de sincronização
enum SyncStrategy {
  /// Cache-first: retorna cache se disponível, senão busca remoto
  cacheFirst,
  /// Network-first: tenta buscar remoto primeiro, fallback para cache
  networkFirst,
  /// Stale-while-revalidate: retorna cache e atualiza em background
  staleWhileRevalidate,
  /// Cache-only: apenas dados do cache
  cacheOnly,
  /// Network-only: apenas dados remotos
  networkOnly,
}

/// Resultado de uma operação de sincronização
class SyncResult<T> {
  final T? data;
  final bool fromCache;
  final bool isStale;
  final String? error;
  final DateTime timestamp;

  const SyncResult({
    this.data,
    required this.fromCache,
    this.isStale = false,
    this.error,
    required this.timestamp,
  });

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isSuccess => hasData && !hasError;
}

/// Configuração de sincronização
class SyncConfig {
  final Duration cacheTtl;
  final Duration staleTtl;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableBackgroundSync;
  final SyncStrategy defaultStrategy;

  const SyncConfig({
    this.cacheTtl = const Duration(hours: 1),
    this.staleTtl = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableBackgroundSync = true,
    this.defaultStrategy = SyncStrategy.staleWhileRevalidate,
  });
}

/// Serviço de sincronização offline-first
class SyncService {
  final CacheDatabase _database;
  final SyncConfig _config;
  final Map<String, Timer> _backgroundSyncTimers = {};
  final Map<String, Completer<void>> _syncInProgress = {};

  SyncService({
    required CacheDatabase database,
    SyncConfig? config,
  }) : _database = database,
       _config = config ?? const SyncConfig();

  /// Sincroniza dados usando a estratégia especificada
  Future<SyncResult<T>> sync<T>(
    String key,
    Future<T> Function() remoteFetch,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson, {
    SyncStrategy? strategy,
    Duration? customTtl,
  }) async {
    final syncStrategy = strategy ?? _config.defaultStrategy;
    final ttl = customTtl ?? _config.cacheTtl;

    switch (syncStrategy) {
      case SyncStrategy.cacheFirst:
        return _cacheFirstSync(key, remoteFetch, fromJson, toJson, ttl);
      case SyncStrategy.networkFirst:
        return _networkFirstSync(key, remoteFetch, fromJson, toJson, ttl);
      case SyncStrategy.staleWhileRevalidate:
        return _staleWhileRevalidateSync(key, remoteFetch, fromJson, toJson, ttl);
      case SyncStrategy.cacheOnly:
        return _cacheOnlySync(key, fromJson);
      case SyncStrategy.networkOnly:
        return _networkOnlySync(key, remoteFetch, toJson, ttl);
    }
  }

  /// Estratégia Cache-First
  Future<SyncResult<T>> _cacheFirstSync<T>(
    String key,
    Future<T> Function() remoteFetch,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
    Duration ttl,
  ) async {
    // Tenta buscar do cache primeiro
    final cached = await _getCachedData(key);
    if (cached != null && !_isExpired(cached, ttl)) {
      final data = fromJson(jsonDecode(cached.data));
      return SyncResult(
        data: data,
        fromCache: true,
        timestamp: cached.lastUpdated,
      );
    }

    // Se não tem cache válido, busca remoto
    try {
      final data = await remoteFetch();
      await _saveToCache(key, toJson(data));
      return SyncResult(
        data: data,
        fromCache: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Se falhou e tem cache expirado, retorna ele mesmo assim
      if (cached != null) {
        final data = fromJson(jsonDecode(cached.data));
        return SyncResult(
          data: data,
          fromCache: true,
          isStale: true,
          error: e.toString(),
          timestamp: cached.lastUpdated,
        );
      }
      
      return SyncResult(
        fromCache: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Estratégia Network-First
  Future<SyncResult<T>> _networkFirstSync<T>(
    String key,
    Future<T> Function() remoteFetch,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
    Duration ttl,
  ) async {
    try {
      // Tenta buscar remoto primeiro
      final data = await remoteFetch();
      await _saveToCache(key, toJson(data));
      return SyncResult(
        data: data,
        fromCache: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Se falhou, tenta cache
      final cached = await _getCachedData(key);
      if (cached != null) {
        final data = fromJson(jsonDecode(cached.data));
        return SyncResult(
          data: data,
          fromCache: true,
          isStale: _isExpired(cached, ttl),
          error: e.toString(),
          timestamp: cached.lastUpdated,
        );
      }
      
      return SyncResult(
        fromCache: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Estratégia Stale-While-Revalidate
  Future<SyncResult<T>> _staleWhileRevalidateSync<T>(
    String key,
    Future<T> Function() remoteFetch,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
    Duration ttl,
  ) async {
    final cached = await _getCachedData(key);
    
    // Se tem cache válido, retorna imediatamente
    if (cached != null && !_isExpired(cached, ttl)) {
      final data = fromJson(jsonDecode(cached.data));
      
      // Se está ficando stale, agenda revalidação em background
      if (_isStale(cached, _config.staleTtl)) {
        _scheduleBackgroundSync(key, remoteFetch, toJson);
      }
      
      return SyncResult(
        data: data,
        fromCache: true,
        isStale: _isStale(cached, _config.staleTtl),
        timestamp: cached.lastUpdated,
      );
    }
    
    // Se tem cache expirado, retorna ele e busca novo em background
    if (cached != null) {
      final data = fromJson(jsonDecode(cached.data));
      _scheduleBackgroundSync(key, remoteFetch, toJson);
      
      return SyncResult(
        data: data,
        fromCache: true,
        isStale: true,
        timestamp: cached.lastUpdated,
      );
    }
    
    // Se não tem cache, busca remoto
    try {
      final data = await remoteFetch();
      await _saveToCache(key, toJson(data));
      return SyncResult(
        data: data,
        fromCache: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        fromCache: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Estratégia Cache-Only
  Future<SyncResult<T>> _cacheOnlySync<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cached = await _getCachedData(key);
    if (cached != null) {
      final data = fromJson(jsonDecode(cached.data));
      return SyncResult(
        data: data,
        fromCache: true,
        timestamp: cached.lastUpdated,
      );
    }
    
    return SyncResult(
      fromCache: true,
      error: 'No cached data found',
      timestamp: DateTime.now(),
    );
  }

  /// Estratégia Network-Only
  Future<SyncResult<T>> _networkOnlySync<T>(
    String key,
    Future<T> Function() remoteFetch,
    Map<String, dynamic> Function(T) toJson,
    Duration ttl,
  ) async {
    try {
      final data = await remoteFetch();
      await _saveToCache(key, toJson(data));
      return SyncResult(
        data: data,
        fromCache: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        fromCache: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Agenda sincronização em background
  void _scheduleBackgroundSync<T>(
    String key,
    Future<T> Function() remoteFetch,
    Map<String, dynamic> Function(T) toJson,
  ) {
    if (!_config.enableBackgroundSync) return;
    if (_syncInProgress.containsKey(key)) return;

    // Cancela timer anterior se existir
    _backgroundSyncTimers[key]?.cancel();
    
    _backgroundSyncTimers[key] = Timer(const Duration(milliseconds: 100), () async {
      final completer = Completer<void>();
      _syncInProgress[key] = completer;
      
      try {
        final data = await remoteFetch();
        await _saveToCache(key, toJson(data));
      } catch (e) {
        // Falha silenciosa em background sync
      } finally {
        _syncInProgress.remove(key);
        _backgroundSyncTimers.remove(key);
        completer.complete();
      }
    });
  }

  /// Busca dados do cache
  Future<CachedDataData?> _getCachedData(String key) async {
    final query = _database.select(_database.cachedData)
      ..where((tbl) => tbl.key.equals(key));
    
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Salva dados no cache
  Future<void> _saveToCache(String key, Map<String, dynamic> data) async {
    final now = DateTime.now();
    
    await _database.into(_database.cachedData).insertOnConflictUpdate(
      CachedDataCompanion(
        key: Value(key),
        data: Value(jsonEncode(data)),
        lastUpdated: Value(now),
        lastAccessed: Value(now),
      ),
    );
  }

  /// Verifica se dados estão expirados
  bool _isExpired(CachedDataData cached, Duration ttl) {
    return DateTime.now().difference(cached.lastUpdated) > ttl;
  }

  /// Verifica se dados estão ficando stale
  bool _isStale(CachedDataData cached, Duration staleTtl) {
    return DateTime.now().difference(cached.lastUpdated) > staleTtl;
  }

  /// Invalida cache por chave
  Future<void> invalidateCache(String key) async {
    await (_database.delete(_database.cachedData)
      ..where((tbl) => tbl.key.equals(key))).go();
    
    // Cancela sync em background se existir
    _backgroundSyncTimers[key]?.cancel();
    _backgroundSyncTimers.remove(key);
  }

  /// Invalida todo o cache
  Future<void> invalidateAllCache() async {
    await _database.delete(_database.cachedData).go();
    
    // Cancela todos os syncs em background
    for (final timer in _backgroundSyncTimers.values) {
      timer.cancel();
    }
    _backgroundSyncTimers.clear();
    _syncInProgress.clear();
  }

  /// Limpa cache expirado
  Future<void> cleanExpiredCache() async {
    final expiredBefore = DateTime.now().subtract(_config.cacheTtl);
    
    await (_database.delete(_database.cachedData)
      ..where((tbl) => tbl.lastUpdated.isSmallerThanValue(expiredBefore))).go();
  }

  /// Dispose do serviço
  void dispose() {
    for (final timer in _backgroundSyncTimers.values) {
      timer.cancel();
    }
    _backgroundSyncTimers.clear();
    _syncInProgress.clear();
  }
}