import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'cache_database.g.dart';

/// Tabela para cache de eventos
class CachedEvents extends Table {
  TextColumn get id => text()();
  TextColumn get barId => text()();
  TextColumn get title => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get description => text()();
  TextColumn get attractions => text()(); // JSON array
  TextColumn get coverImageUrl => text().nullable()();
  BoolColumn get published => boolean().withDefault(const Constant(false))();
  TextColumn get promoDetails => text()();
  TextColumn get promoImages => text()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdByUid => text()();
  TextColumn get updatedByUid => text()();
  
  // Metadados de cache
  DateTimeColumn get cacheCreatedAt => dateTime()();
  DateTimeColumn get cacheUpdatedAt => dateTime()();
  DateTimeColumn get cacheExpiresAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
    Index('idx_cached_events_bar_id', barId.name),
    Index('idx_cached_events_start_at', startAt.name),
    Index('idx_cached_events_published', published.name),
    Index('idx_cached_events_needs_sync', needsSync.name),
    Index('idx_cached_events_expires_at', cacheExpiresAt.name),
  ];
}

/// Tabela para cache de bares
class CachedBars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get cnpj => text()();
  TextColumn get contactEmail => text()();
  TextColumn get responsibleName => text()();
  TextColumn get phone => text()();
  TextColumn get cep => text()();
  TextColumn get street => text()();
  TextColumn get number => text()();
  TextColumn get complement => text()();
  TextColumn get neighborhood => text()();
  TextColumn get city => text()();
  TextColumn get state => text()();
  TextColumn get primaryOwnerUid => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  // Metadados de cache
  DateTimeColumn get cacheCreatedAt => dateTime()();
  DateTimeColumn get cacheUpdatedAt => dateTime()();
  DateTimeColumn get cacheExpiresAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
    Index('idx_cached_bars_primary_owner_uid', primaryOwnerUid.name),
    Index('idx_cached_bars_cnpj', cnpj.name),
    Index('idx_cached_bars_contact_email', contactEmail.name),
    Index('idx_cached_bars_needs_sync', needsSync.name),
    Index('idx_cached_bars_expires_at', cacheExpiresAt.name),
  ];
}

/// Tabela para cache de usuários
class CachedUsers extends Table {
  TextColumn get uid => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  BoolColumn get emailVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  // Metadados de cache
  DateTimeColumn get cacheCreatedAt => dateTime()();
  DateTimeColumn get cacheUpdatedAt => dateTime()();
  DateTimeColumn get cacheExpiresAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {uid};

  List<Index> get indexes => [
    Index('idx_cached_users_email', email.name),
    Index('idx_cached_users_needs_sync', needsSync.name),
    Index('idx_cached_users_expires_at', cacheExpiresAt.name),
  ];
}

/// Tabela para cache de imagens
class CachedImages extends Table {
  TextColumn get id => text()();
  TextColumn get remoteUrl => text()();
  TextColumn get localPath => text()();
  TextColumn get size => text()(); // 'original', 'thumbnail', 'medium'
  IntColumn get fileSizeBytes => integer()();
  TextColumn get contentType => text()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();
  
  // Metadados de cache
  DateTimeColumn get cacheCreatedAt => dateTime()();
  DateTimeColumn get cacheUpdatedAt => dateTime()();
  DateTimeColumn get cacheExpiresAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
    Index('idx_cached_images_remote_url', remoteUrl.name),
    Index('idx_cached_images_size', size.name),
    Index('idx_cached_images_last_accessed', lastAccessedAt.name),
    Index('idx_cached_images_expires_at', cacheExpiresAt.name),
  ];
}

/// Tabela para fila de sincronização
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'event', 'bar', 'user', 'image'
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get data => text().nullable()(); // JSON data
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get error => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
    Index('idx_sync_queue_entity', entityType.name),
    Index('idx_sync_queue_next_attempt', nextAttemptAt.name),
    Index('idx_sync_queue_completed', completed.name),
  ];
}

/// Tabela para cache genérico de dados
class CachedData extends Table {
  TextColumn get key => text()();
  TextColumn get data => text()(); // JSON data
  DateTimeColumn get lastUpdated => dateTime()();
  DateTimeColumn get lastAccessed => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get etag => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {key};

  List<Index> get indexes => [
    Index('idx_cached_data_last_updated', lastUpdated.name),
    Index('idx_cached_data_expires_at', expiresAt.name),
  ];
}

/// Tabela para métricas de cache
class CacheMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get operation => text()(); // 'hit', 'miss', 'put', 'remove'
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get latencyMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON metadata

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
    Index('idx_cache_metrics_entity_type', entityType.name),
    Index('idx_cache_metrics_operation', operation.name),
    Index('idx_cache_metrics_timestamp', timestamp.name),
  ];
}

/// Database principal do cache
@DriftDatabase(tables: [
  CachedEvents,
  CachedBars,
  CachedUsers,
  CachedImages,
  CachedData,
  SyncQueue,
  CacheMetrics,
])
class CacheDatabase extends _$CacheDatabase {
  CacheDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Futuras migrações serão implementadas aqui
      },
    );
  }

  /// Limpa dados expirados de todas as tabelas
  Future<void> cleanupExpiredData() async {
    final now = DateTime.now();
    
    await batch((batch) {
      batch.deleteWhere(
        cachedEvents,
        (tbl) => tbl.cacheExpiresAt.isNotNull() & 
                 tbl.cacheExpiresAt.isSmallerThanValue(now),
      );
      batch.deleteWhere(
        cachedBars,
        (tbl) => tbl.cacheExpiresAt.isNotNull() & 
                 tbl.cacheExpiresAt.isSmallerThanValue(now),
      );
      batch.deleteWhere(
        cachedUsers,
        (tbl) => tbl.cacheExpiresAt.isNotNull() & 
                 tbl.cacheExpiresAt.isSmallerThanValue(now),
      );
      batch.deleteWhere(
        cachedImages,
        (tbl) => tbl.cacheExpiresAt.isNotNull() & 
                 tbl.cacheExpiresAt.isSmallerThanValue(now),
      );
    });
  }

  /// Obtém estatísticas do cache
  Future<Map<String, int>> getCacheStats() async {
    final eventsCount = await (select(cachedEvents)..limit(1)).get().then((r) => r.length);
    final barsCount = await (select(cachedBars)..limit(1)).get().then((r) => r.length);
    final usersCount = await (select(cachedUsers)..limit(1)).get().then((r) => r.length);
    final imagesCount = await (select(cachedImages)..limit(1)).get().then((r) => r.length);
    
    return {
      'events': eventsCount,
      'bars': barsCount,
      'users': usersCount,
      'images': imagesCount,
    };
  }
}

/// Abre conexão com o banco de dados
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cache_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}