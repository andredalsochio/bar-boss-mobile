import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../domain/cache/cache_interfaces.dart';
import '../services/image_cache_service_impl.dart';
import '../drift/cache_database.dart';

/// Providers para serviços de cache
class CacheProviders {
  static List<SingleChildWidget> get providers => [
    // Database
    Provider<CacheDatabase>(
      create: (_) => CacheDatabase(),
      dispose: (_, db) => db.close(),
    ),

    // Image Cache Service
    ProxyProvider<CacheDatabase, ImageCacheService>(
      create: (context) => ImageCacheServiceImpl(
        context.read<CacheDatabase>(),
      ),
      update: (context, database, previous) => 
          previous ?? ImageCacheServiceImpl(database),
    ),
  ];
}