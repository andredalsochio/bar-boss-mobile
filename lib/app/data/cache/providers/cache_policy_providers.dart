import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/cache_policy_service.dart';
import '../drift/cache_database.dart';

/// Providers para o sistema de políticas de cache
class CachePolicyProviders {
  static List<SingleChildWidget> get providers => [
    // Provider para CachePolicyService
    ProxyProvider<CacheDatabase, CachePolicyService>(
      create: (context) => CachePolicyService(
        database: Provider.of<CacheDatabase>(context, listen: false),
        config: const CachePolicyConfig(
          defaultTtl: Duration(hours: 2),
          maxSizeInMB: 150,
          maxEntries: 1500,
          evictionPolicy: CacheEvictionPolicy.lru,
          cleanupInterval: Duration(minutes: 10),
          cleanupThreshold: 0.75,
        ),
      ),
      update: (context, database, previous) => previous ?? CachePolicyService(
        database: database,
        config: const CachePolicyConfig(
          defaultTtl: Duration(hours: 2),
          maxSizeInMB: 150,
          maxEntries: 1500,
          evictionPolicy: CacheEvictionPolicy.lru,
          cleanupInterval: Duration(minutes: 10),
          cleanupThreshold: 0.75,
        ),
      ),
      dispose: (context, service) => service.dispose(),
    ),
  ];
}