import 'cache_store.dart';
import 'remote_store.dart';

/// Interface para repositório com cache offline-first
/// Implementa estratégia Stale-While-Revalidate
abstract class CachedRepository<T> {
  /// Store de cache local
  CacheStore<T> get cacheStore;

  /// Store remoto (Firebase, API, etc.)
  RemoteStore<T> get remoteStore;

  /// Configuração de cache
  CacheConfig get config;

  /// Obtém um item com estratégia offline-first
  /// 1. Tenta buscar do cache primeiro
  /// 2. Se não encontrar ou estiver expirado, busca do servidor
  /// 3. Atualiza o cache em background
  Future<CachedResult<T?>> get(String id) async {
    // Busca do cache primeiro
    final cached = await cacheStore.get(id);
    final metadata = await cacheStore.getMetadata(id);
    
    // Se tem no cache e não está expirado, retorna do cache
    if (cached != null && metadata != null && !metadata.isExpired) {
      // Inicia revalidação em background se necessário
      _revalidateInBackground(id);
      return CachedResult.fromCache(cached);
    }
    
    // Busca do servidor
    try {
      final remote = await remoteStore.get(id);
      if (remote != null) {
        // Salva no cache
        await _putInCache(id, remote);
        return CachedResult.fromNetwork(remote);
      }
      
      // Se não encontrou no servidor mas tem no cache (mesmo expirado)
      if (cached != null) {
        return CachedResult.fromCache(cached, isStale: true);
      }
      
      return CachedResult.notFound();
    } catch (e) {
      // Em caso de erro de rede, retorna do cache se disponível
      if (cached != null) {
        return CachedResult.fromCache(cached, isStale: true, error: e);
      }
      rethrow;
    }
  }

  /// Obtém múltiplos itens com cache
  Future<CachedResult<List<T>>> getMultiple(List<String> ids);

  /// Obtém todos os itens com cache
  Future<CachedResult<List<T>>> getAll();

  /// Obtém itens com query e cache
  Future<CachedResult<List<T>>> query(RemoteQuery query);

  /// Salva um item (cache + servidor)
  Future<String> put(T item);

  /// Atualiza um item (cache + servidor)
  Future<void> update(String id, T item);

  /// Remove um item (cache + servidor)
  Future<void> remove(String id);

  /// Obtém stream com cache + atualizações do servidor
  Stream<CachedResult<T?>> watchItem(String id);

  /// Obtém stream de lista com cache + atualizações
  Stream<CachedResult<List<T>>> watchAll();

  /// Obtém stream com query e cache
  Stream<CachedResult<List<T>>> watchQuery(RemoteQuery query);

  /// Força sincronização com o servidor
  Future<void> sync();

  /// Limpa o cache
  Future<void> clearCache();

  /// Obtém estatísticas do cache
  Future<CacheStats> getCacheStats();

  /// Métodos privados para implementação
  
  /// Salva item no cache com metadados
  Future<void> _putInCache(String id, T item) async {
    final now = DateTime.now();
    final metadata = CacheMetadata(
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(config.ttl),
      needsSync: false,
    );
    
    await cacheStore.put(id, item);
    await cacheStore.setMetadata(id, metadata);
  }

  /// Revalida item em background
  Future<void> _revalidateInBackground(String id) async {
    // Não aguarda para não bloquear a UI
    Future.microtask(() async {
      try {
        final remote = await remoteStore.get(id);
        if (remote != null) {
          await _putInCache(id, remote);
        }
      } catch (e) {
        // Log do erro mas não propaga
        print('Background revalidation failed for $id: $e');
      }
    });
  }
}

/// Resultado de operação com cache
class CachedResult<T> {
  final T data;
  final CacheSource source;
  final bool isStale;
  final Object? error;

  const CachedResult._(
    this.data,
    this.source,
    this.isStale,
    this.error,
  );

  /// Resultado do cache
  factory CachedResult.fromCache(
    T data, {
    bool isStale = false,
    Object? error,
  }) {
    return CachedResult._(data, CacheSource.cache, isStale, error);
  }

  /// Resultado da rede
  factory CachedResult.fromNetwork(T data) {
    return CachedResult._(data, CacheSource.network, false, null);
  }

  /// Resultado não encontrado
  factory CachedResult.notFound() {
    return CachedResult._(null as T, CacheSource.none, false, null);
  }

  /// Se tem dados válidos
  bool get hasData => data != null;

  /// Se veio do cache
  bool get isFromCache => source == CacheSource.cache;

  /// Se veio da rede
  bool get isFromNetwork => source == CacheSource.network;

  /// Se tem erro
  bool get hasError => error != null;
}

/// Fonte dos dados
enum CacheSource {
  cache,
  network,
  none,
}

/// Configuração do cache
class CacheConfig {
  final Duration ttl;
  final int maxSize;
  final bool enableBackgroundSync;
  final Duration syncInterval;
  final int maxRetries;
  final Duration retryDelay;

  const CacheConfig({
    this.ttl = const Duration(minutes: 30),
    this.maxSize = 1000,
    this.enableBackgroundSync = true,
    this.syncInterval = const Duration(minutes: 15),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
  });
}

/// Estatísticas do cache
class CacheStats {
  final int totalItems;
  final int expiredItems;
  final int pendingSyncItems;
  final double hitRate;
  final double missRate;
  final DateTime lastSync;

  const CacheStats({
    required this.totalItems,
    required this.expiredItems,
    required this.pendingSyncItems,
    required this.hitRate,
    required this.missRate,
    required this.lastSync,
  });
}