import 'package:provider/provider.dart';
import '../services/cache_metrics_service.dart';
import '../drift/cache_database.dart';

/// Providers para o serviço de métricas de cache
class CacheMetricsProviders {
  static List<ProxyProvider> get providers => [
    ProxyProvider<CacheDatabase, CacheMetricsService>(
      create: (context) => CacheMetricsService(
        database: Provider.of<CacheDatabase>(context, listen: false),
        config: CacheMetricsConfig(
          aggregationInterval: Duration(minutes: 5),
          retentionPeriod: Duration(days: 30),
          maxBufferSize: 1000,
          flushInterval: Duration(seconds: 30),
        ),
      ),
      update: (context, database, previous) => previous ?? CacheMetricsService(
        database: database,
        config: CacheMetricsConfig(
          aggregationInterval: Duration(minutes: 5),
          retentionPeriod: Duration(days: 30),
          maxBufferSize: 1000,
          flushInterval: Duration(seconds: 30),
        ),
      ),
      dispose: (context, service) => service.dispose(),
    ),
  ];
}