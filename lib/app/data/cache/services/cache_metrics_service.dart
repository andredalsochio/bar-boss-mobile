import 'dart:async';

import 'package:drift/drift.dart';
import '../drift/cache_database.dart';

/// Tipos de métricas de cache
enum CacheMetricType {
  hit,
  miss,
  eviction,
  expiration,
  size,
  latency,
}

/// Entrada de métrica de cache
class CacheMetricEntry {
  final String key;
  final CacheMetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const CacheMetricEntry({
    required this.key,
    required this.type,
    required this.value,
    required this.timestamp,
    this.metadata,
  });
}

/// Estatísticas agregadas de cache
class CacheAggregatedStats {
  final int totalHits;
  final int totalMisses;
  final int totalEvictions;
  final int totalExpirations;
  final double averageLatency;
  final double hitRate;
  final double currentSizeMB;
  final DateTime periodStart;
  final DateTime periodEnd;

  const CacheAggregatedStats({
    required this.totalHits,
    required this.totalMisses,
    required this.totalEvictions,
    required this.totalExpirations,
    required this.averageLatency,
    required this.hitRate,
    required this.currentSizeMB,
    required this.periodStart,
    required this.periodEnd,
  });
}

/// Configuração do serviço de métricas
class CacheMetricsConfig {
  /// Intervalo de agregação de métricas
  final Duration aggregationInterval;
  
  /// Tempo de retenção das métricas
  final Duration retentionPeriod;
  
  /// Tamanho máximo do buffer de métricas em memória
  final int maxBufferSize;
  
  /// Intervalo de flush para o banco
  final Duration flushInterval;

  const CacheMetricsConfig({
    this.aggregationInterval = const Duration(minutes: 5),
    this.retentionPeriod = const Duration(days: 7),
    this.maxBufferSize = 1000,
    this.flushInterval = const Duration(seconds: 30),
  });
}

/// Serviço de métricas de cache
class CacheMetricsService {
  final CacheDatabase _database;
  final CacheMetricsConfig _config;
  
  // Buffer em memória para métricas
  final List<CacheMetricEntry> _metricsBuffer = [];
  
  // Timers para agregação e limpeza
  Timer? _flushTimer;
  Timer? _cleanupTimer;
  
  // Contadores em memória para performance
  int _sessionHits = 0;
  int _sessionMisses = 0;
  int _sessionEvictions = 0;
  int _sessionExpirations = 0;
  final List<double> _latencyBuffer = [];

  CacheMetricsService({
    required CacheDatabase database,
    CacheMetricsConfig? config,
  }) : _database = database,
       _config = config ?? const CacheMetricsConfig() {
    _startPeriodicFlush();
    _startPeriodicCleanup();
  }

  /// Inicia flush periódico das métricas
  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_config.flushInterval, (_) {
      _flushMetrics();
    });
  }

  /// Inicia limpeza periódica de métricas antigas
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_config.retentionPeriod, (_) {
      _cleanupOldMetrics();
    });
  }

  /// Para o serviço e cancela timers
  void dispose() {
    _flushTimer?.cancel();
    _cleanupTimer?.cancel();
    _flushMetrics(); // Flush final
  }

  /// Registra um hit de cache
  void recordHit(String key, {double? latencyMs}) {
    _sessionHits++;
    
    _addMetric(CacheMetricEntry(
      key: key,
      type: CacheMetricType.hit,
      value: 1,
      timestamp: DateTime.now(),
    ));
    
    if (latencyMs != null) {
      _recordLatency(key, latencyMs);
    }
  }

  /// Registra um miss de cache
  void recordMiss(String key, {double? latencyMs}) {
    _sessionMisses++;
    
    _addMetric(CacheMetricEntry(
      key: key,
      type: CacheMetricType.miss,
      value: 1,
      timestamp: DateTime.now(),
    ));
    
    if (latencyMs != null) {
      _recordLatency(key, latencyMs);
    }
  }

  /// Registra uma eviction de cache
  void recordEviction(String key, {String? reason}) {
    _sessionEvictions++;
    
    _addMetric(CacheMetricEntry(
      key: key,
      type: CacheMetricType.eviction,
      value: 1,
      timestamp: DateTime.now(),
      metadata: reason != null ? {'reason': reason} : null,
    ));
  }

  /// Registra uma expiração de cache
  void recordExpiration(String key) {
    _sessionExpirations++;
    
    _addMetric(CacheMetricEntry(
      key: key,
      type: CacheMetricType.expiration,
      value: 1,
      timestamp: DateTime.now(),
    ));
  }

  /// Registra latência de operação
  void _recordLatency(String key, double latencyMs) {
    _latencyBuffer.add(latencyMs);
    
    _addMetric(CacheMetricEntry(
      key: key,
      type: CacheMetricType.latency,
      value: latencyMs,
      timestamp: DateTime.now(),
    ));
  }

  /// Registra tamanho atual do cache
  void recordCacheSize(double sizeMB) {
    _addMetric(CacheMetricEntry(
      key: 'cache_size',
      type: CacheMetricType.size,
      value: sizeMB,
      timestamp: DateTime.now(),
    ));
  }

  /// Adiciona métrica ao buffer
  void _addMetric(CacheMetricEntry metric) {
    _metricsBuffer.add(metric);
    
    // Flush se buffer estiver cheio
    if (_metricsBuffer.length >= _config.maxBufferSize) {
      _flushMetrics();
    }
  }

  /// Flush das métricas para o banco
  Future<void> _flushMetrics() async {
    if (_metricsBuffer.isEmpty) return;
    
    try {
      final metricsToFlush = List<CacheMetricEntry>.from(_metricsBuffer);
      _metricsBuffer.clear();
      
      await _database.transaction(() async {
        for (final metric in metricsToFlush) {
          await _database.into(_database.cacheMetrics).insert(
            CacheMetricsCompanion(
              id: Value(_generateMetricId()),
              entityType: Value(metric.key),
              operation: Value(metric.type.name),
              timestamp: Value(metric.timestamp),
              latencyMs: Value(metric.type == CacheMetricType.latency ? metric.value.toInt() : null),
              sizeBytes: Value(metric.type == CacheMetricType.size ? (metric.value * 1024 * 1024).toInt() : null),
              metadata: Value(metric.metadata?.toString()),
            ),
          );
        }
      });
      
      // TODO: Implementar logging
      // Logger.debug('Flushed ${metricsToFlush.length} metrics to database');
      
    } catch (e) {
      // TODO: Implementar logging
      // Logger.error('Error flushing metrics: $e');
    }
  }

  /// Limpa métricas antigas
  Future<void> _cleanupOldMetrics() async {
    try {
      final cutoffDate = DateTime.now().subtract(_config.retentionPeriod);
      
      await (_database.delete(_database.cacheMetrics)
          ..where((tbl) => tbl.timestamp.isSmallerThan(Variable(cutoffDate))))
        .go();
      
      // TODO: Implementar logging
      // Logger.info('Cleaned up $deletedCount old metrics');
      
    } catch (e) {
      // TODO: Implementar logging
      // Logger.error('Error cleaning up metrics: $e');
    }
  }

  /// Obtém estatísticas da sessão atual
  CacheAggregatedStats getSessionStats() {
    final totalOperations = _sessionHits + _sessionMisses;
    final hitRate = totalOperations > 0 ? _sessionHits / totalOperations : 0.0;
    
    final averageLatency = _latencyBuffer.isNotEmpty
        ? _latencyBuffer.reduce((a, b) => a + b) / _latencyBuffer.length
        : 0.0;
    
    return CacheAggregatedStats(
      totalHits: _sessionHits,
      totalMisses: _sessionMisses,
      totalEvictions: _sessionEvictions,
      totalExpirations: _sessionExpirations,
      averageLatency: averageLatency,
      hitRate: hitRate,
      currentSizeMB: 0.0, // Será calculado externamente
      periodStart: DateTime.now(), // Simplificado
      periodEnd: DateTime.now(),
    );
  }

  /// Obtém estatísticas agregadas por período
  Future<CacheAggregatedStats> getAggregatedStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Busca métricas do período
      final metrics = await (_database.select(_database.cacheMetrics)
        ..where((tbl) => tbl.timestamp.isBetweenValues(startDate, endDate))).get();
      
      // Agrega por tipo
      int hits = 0;
      int misses = 0;
      int evictions = 0;
      int expirations = 0;
      final latencies = <double>[];
      
      for (final metric in metrics) {
        switch (metric.operation) {
          case 'hit':
            hits += 1;
            break;
          case 'miss':
            misses += 1;
            break;
          case 'eviction':
            evictions += 1;
            break;
          case 'expiration':
            expirations += 1;
            break;
          case 'latency':
            if (metric.latencyMs != null) {
              latencies.add(metric.latencyMs!.toDouble());
            }
            break;
        }
      }
      
      final totalOperations = hits + misses;
      final hitRate = totalOperations > 0 ? hits / totalOperations : 0.0;
      
      final averageLatency = latencies.isNotEmpty
          ? latencies.reduce((a, b) => a + b) / latencies.length
          : 0.0;
      
      return CacheAggregatedStats(
        totalHits: hits,
        totalMisses: misses,
        totalEvictions: evictions,
        totalExpirations: expirations,
        averageLatency: averageLatency,
        hitRate: hitRate,
        currentSizeMB: 0.0, // Será calculado externamente
        periodStart: startDate,
        periodEnd: endDate,
      );
      
    } catch (e) {
      // TODO: Implementar logging
      // Logger.error('Error getting aggregated stats: $e');
      
      return CacheAggregatedStats(
        totalHits: 0,
        totalMisses: 0,
        totalEvictions: 0,
        totalExpirations: 0,
        averageLatency: 0.0,
        hitRate: 0.0,
        currentSizeMB: 0.0,
        periodStart: startDate,
        periodEnd: endDate,
      );
    }
  }

  /// Força flush das métricas
  Future<void> forceFlush() async {
    await _flushMetrics();
  }

  /// Limpa todas as métricas
  Future<void> clearAllMetrics() async {
    _metricsBuffer.clear();
    _sessionHits = 0;
    _sessionMisses = 0;
    _sessionEvictions = 0;
    _sessionExpirations = 0;
    _latencyBuffer.clear();
    
    await _database.delete(_database.cacheMetrics).go();
  }

  /// Gera ID único para métrica
  String _generateMetricId() {
    return 'metric_${DateTime.now().millisecondsSinceEpoch}_${_metricsBuffer.length}';
  }

  /// Obtém configuração atual
  CacheMetricsConfig get config => _config;
}