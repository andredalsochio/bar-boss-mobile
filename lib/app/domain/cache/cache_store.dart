/// Interface genérica para operações de cache local
/// Abstrai a implementação específica (Drift, Hive, etc.)
abstract class CacheStore<T> {
  /// Obtém um item do cache pelo ID
  Future<T?> get(String id);

  /// Obtém múltiplos itens do cache pelos IDs
  Future<List<T>> getMultiple(List<String> ids);

  /// Obtém todos os itens do cache
  Future<List<T>> getAll();

  /// Salva um item no cache
  Future<void> put(String id, T item);

  /// Salva múltiplos itens no cache
  Future<void> putMultiple(Map<String, T> items);

  /// Remove um item do cache
  Future<void> remove(String id);

  /// Remove múltiplos itens do cache
  Future<void> removeMultiple(List<String> ids);

  /// Limpa todo o cache
  Future<void> clear();

  /// Verifica se um item existe no cache
  Future<bool> exists(String id);

  /// Obtém o tamanho do cache (número de itens)
  Future<int> size();

  /// Obtém stream de mudanças no cache
  Stream<List<T>> watch();

  /// Obtém stream de um item específico
  Stream<T?> watchItem(String id);

  /// Obtém metadados do cache (TTL, última atualização, etc.)
  Future<CacheMetadata?> getMetadata(String id);

  /// Define metadados do cache
  Future<void> setMetadata(String id, CacheMetadata metadata);

  /// Remove itens expirados baseado no TTL
  Future<void> removeExpired();

  /// Obtém itens que precisam ser sincronizados
  Future<List<String>> getPendingSync();

  /// Marca item como sincronizado
  Future<void> markSynced(String id);

  /// Marca item como pendente de sincronização
  Future<void> markPendingSync(String id);
}

/// Metadados do cache para controle de TTL e sincronização
class CacheMetadata {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool needsSync;
  final int version;
  final String? etag;

  const CacheMetadata({
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.needsSync = false,
    this.version = 1,
    this.etag,
  });

  /// Verifica se o item está expirado
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Cria uma cópia com novos valores
  CacheMetadata copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? needsSync,
    int? version,
    String? etag,
  }) {
    return CacheMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      needsSync: needsSync ?? this.needsSync,
      version: version ?? this.version,
      etag: etag ?? this.etag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'needsSync': needsSync,
      'version': version,
      'etag': etag,
    };
  }

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      needsSync: json['needsSync'] ?? false,
      version: json['version'] ?? 1,
      etag: json['etag'],
    );
  }
}