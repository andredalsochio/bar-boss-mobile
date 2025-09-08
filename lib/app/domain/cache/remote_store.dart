/// Interface genérica para operações remotas (Firebase, API, etc.)
/// Abstrai a implementação específica do backend
abstract class RemoteStore<T> {
  /// Obtém um item do servidor pelo ID
  Future<T?> get(String id);

  /// Obtém múltiplos itens do servidor pelos IDs
  Future<List<T>> getMultiple(List<String> ids);

  /// Obtém todos os itens do servidor
  Future<List<T>> getAll();

  /// Obtém itens com filtros/query
  Future<List<T>> query(RemoteQuery query);

  /// Salva um item no servidor
  Future<String> put(T item);

  /// Atualiza um item no servidor
  Future<void> update(String id, T item);

  /// Remove um item do servidor
  Future<void> remove(String id);

  /// Obtém stream de mudanças do servidor
  Stream<List<T>> watch();

  /// Obtém stream de um item específico
  Stream<T?> watchItem(String id);

  /// Obtém stream com query/filtros
  Stream<List<T>> watchQuery(RemoteQuery query);

  /// Verifica se um item existe no servidor
  Future<bool> exists(String id);

  /// Obtém metadados do servidor (ETag, última modificação, etc.)
  Future<RemoteMetadata?> getMetadata(String id);

  /// Faz upload de arquivo/imagem
  Future<String> uploadFile(String path, List<int> data, {
    String? contentType,
    Map<String, String>? metadata,
  });

  /// Faz download de arquivo/imagem
  Future<List<int>> downloadFile(String path);

  /// Remove arquivo do servidor
  Future<void> removeFile(String path);

  /// Obtém URL de download do arquivo
  Future<String> getFileUrl(String path);
}

/// Query para operações remotas
class RemoteQuery {
  final Map<String, dynamic> filters;
  final List<String> orderBy;
  final int? limit;
  final String? startAfter;
  final bool descending;

  const RemoteQuery({
    this.filters = const {},
    this.orderBy = const [],
    this.limit,
    this.startAfter,
    this.descending = false,
  });

  RemoteQuery copyWith({
    Map<String, dynamic>? filters,
    List<String>? orderBy,
    int? limit,
    String? startAfter,
    bool? descending,
  }) {
    return RemoteQuery(
      filters: filters ?? this.filters,
      orderBy: orderBy ?? this.orderBy,
      limit: limit ?? this.limit,
      startAfter: startAfter ?? this.startAfter,
      descending: descending ?? this.descending,
    );
  }
}

/// Metadados do servidor para controle de versão e cache
class RemoteMetadata {
  final String? etag;
  final DateTime? lastModified;
  final int? version;
  final int? generation;
  final Map<String, String> customMetadata;

  const RemoteMetadata({
    this.etag,
    this.lastModified,
    this.version,
    this.generation,
    this.customMetadata = const {},
  });

  RemoteMetadata copyWith({
    String? etag,
    DateTime? lastModified,
    int? version,
    int? generation,
    Map<String, String>? customMetadata,
  }) {
    return RemoteMetadata(
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      version: version ?? this.version,
      generation: generation ?? this.generation,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etag': etag,
      'lastModified': lastModified?.toIso8601String(),
      'version': version,
      'generation': generation,
      'customMetadata': customMetadata,
    };
  }

  factory RemoteMetadata.fromJson(Map<String, dynamic> json) {
    return RemoteMetadata(
      etag: json['etag'],
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified']) 
          : null,
      version: json['version'],
      generation: json['generation'],
      customMetadata: Map<String, String>.from(
        json['customMetadata'] ?? {},
      ),
    );
  }
}