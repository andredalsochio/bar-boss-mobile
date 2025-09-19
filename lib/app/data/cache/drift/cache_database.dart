import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'event_photos_table.dart';

part 'cache_database.g.dart';

/// Database principal para cache local usando Drift
/// Gerencia persistência de fotos de eventos e outros dados offline
@DriftDatabase(tables: [EventPhotos])
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

  /// Limpa cache antigo baseado em TTL
  Future<void> cleanOldCache() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    
    await (delete(eventPhotos)
      ..where((tbl) => tbl.createdAt.isSmallerThanValue(cutoffDate)))
      .go();
  }

  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    final totalPhotos = await eventPhotos.count().getSingle();
    final totalSizeQuery = selectOnly(eventPhotos)
      ..addColumns([eventPhotos.fileSize.sum()]);
    final result = await totalSizeQuery.getSingle();
    final totalSize = result.read(eventPhotos.fileSize.sum());

    return {
      'totalPhotos': totalPhotos,
      'totalSize': totalSize ?? 0,
      'lastCleanup': DateTime.now().toIso8601String(),
    };
  }
}

/// Configuração da conexão com o banco SQLite
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cache_database.sqlite'));
    
    return NativeDatabase.createInBackground(file);
  });
}