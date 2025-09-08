import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../drift/cache_database.dart';
import '../services/sync_service.dart';

/// Providers para o sistema de sincronização
class SyncProviders {
  static List<SingleChildWidget> get providers => [
    // SyncService
    ProxyProvider<CacheDatabase, SyncService>(
      create: (context) => SyncService(
        database: context.read<CacheDatabase>(),
        config: const SyncConfig(
          cacheTtl: Duration(hours: 1),
          staleTtl: Duration(minutes: 30),
          maxRetries: 3,
          retryDelay: Duration(seconds: 2),
          enableBackgroundSync: true,
        ),
      ),
      update: (context, database, previous) => 
          previous ?? SyncService(
            database: database,
            config: const SyncConfig(
              cacheTtl: Duration(hours: 1),
              staleTtl: Duration(minutes: 30),
              maxRetries: 3,
              retryDelay: Duration(seconds: 2),
              enableBackgroundSync: true,
            ),
          ),
    ),
  ];
}