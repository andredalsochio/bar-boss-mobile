import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../drift/cache_database.dart';
import '../services/write_queue_service.dart';

/// Providers para o sistema de fila de escrita
class WriteQueueProviders {
  static List<SingleChildWidget> get providers => [
    ProxyProvider<CacheDatabase, WriteQueueService>(
      create: (context) => WriteQueueService(
        database: context.read<CacheDatabase>(),
        config: const WriteQueueConfig(
          maxRetries: 3,
          batchSize: 10,
          processingInterval: Duration(seconds: 30),
          backoffMultiplier: 2.0,
          maxRetryDelay: Duration(minutes: 5),
        ),
      ),
      update: (context, database, previous) => previous ?? WriteQueueService(
        database: database,
        config: const WriteQueueConfig(
          maxRetries: 3,
          batchSize: 10,
          processingInterval: Duration(seconds: 30),
          backoffMultiplier: 2.0,
          maxRetryDelay: Duration(minutes: 5),
        ),
      ),
    ),
  ];
}