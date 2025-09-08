import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Configurações de cache obtidas via Remote Config
class CacheRemoteConfig {
  // TTL configurations
  final Duration eventsTtl;
  final Duration barsTtl;
  final Duration usersTtl;
  final Duration imagesTtl;
  
  // Cache size limits
  final int maxCacheSizeMB;
  final int maxImageCacheSizeMB;
  final int maxEntries;
  
  // Sync configurations
  final Duration syncInterval;
  final bool enableBackgroundSync;
  final bool enablePrefetch;
  
  // Retry configurations
  final int maxRetries;
  final Duration initialRetryDelay;
  final double backoffMultiplier;
  
  // Metrics configurations
  final bool enableMetrics;
  final Duration metricsFlushInterval;
  final Duration metricsRetentionPeriod;

  const CacheRemoteConfig({
    required this.eventsTtl,
    required this.barsTtl,
    required this.usersTtl,
    required this.imagesTtl,
    required this.maxCacheSizeMB,
    required this.maxImageCacheSizeMB,
    required this.maxEntries,
    required this.syncInterval,
    required this.enableBackgroundSync,
    required this.enablePrefetch,
    required this.maxRetries,
    required this.initialRetryDelay,
    required this.backoffMultiplier,
    required this.enableMetrics,
    required this.metricsFlushInterval,
    required this.metricsRetentionPeriod,
  });
  
  /// Configuração padrão (fallback)
  static const CacheRemoteConfig defaultConfig = CacheRemoteConfig(
    eventsTtl: Duration(hours: 1),
    barsTtl: Duration(hours: 6),
    usersTtl: Duration(hours: 12),
    imagesTtl: Duration(days: 7),
    maxCacheSizeMB: 100,
    maxImageCacheSizeMB: 200,
    maxEntries: 10000,
    syncInterval: Duration(minutes: 15),
    enableBackgroundSync: true,
    enablePrefetch: true,
    maxRetries: 3,
    initialRetryDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    enableMetrics: true,
    metricsFlushInterval: Duration(minutes: 5),
    metricsRetentionPeriod: Duration(days: 7),
  );
}

/// Serviço para gerenciar configurações de cache via Firebase Remote Config
class CacheRemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  
  // Stream controller para notificar mudanças de configuração
  final StreamController<CacheRemoteConfig> _configController = 
      StreamController<CacheRemoteConfig>.broadcast();
  
  // Configuração atual em cache
  CacheRemoteConfig _currentConfig = CacheRemoteConfig.defaultConfig;
  
  // Timer para fetch periódico
  Timer? _fetchTimer;

  CacheRemoteConfigService(this._remoteConfig) {
    _initializeRemoteConfig();
  }

  /// Stream de mudanças de configuração
  Stream<CacheRemoteConfig> get configStream => _configController.stream;
  
  /// Configuração atual
  CacheRemoteConfig get currentConfig => _currentConfig;

  /// Inicializa o Remote Config com valores padrão
  Future<void> _initializeRemoteConfig() async {
    try {
      // Define valores padrão
      await _remoteConfig.setDefaults({
        // TTL configurations (em segundos)
        'cache_events_ttl_seconds': 3600, // 1 hora
        'cache_bars_ttl_seconds': 21600, // 6 horas
        'cache_users_ttl_seconds': 43200, // 12 horas
        'cache_images_ttl_seconds': 604800, // 7 dias
        
        // Cache size limits
        'cache_max_size_mb': 100,
        'cache_max_image_size_mb': 200,
        'cache_max_entries': 10000,
        
        // Sync configurations
        'cache_sync_interval_seconds': 900, // 15 minutos
        'cache_enable_background_sync': true,
        'cache_enable_prefetch': true,
        
        // Retry configurations
        'cache_max_retries': 3,
        'cache_initial_retry_delay_seconds': 1,
        'cache_backoff_multiplier': 2.0,
        
        // Metrics configurations
        'cache_enable_metrics': true,
        'cache_metrics_flush_interval_seconds': 300, // 5 minutos
        'cache_metrics_retention_days': 7,
      });
      
      // Configura fetch settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      
      // Fetch inicial
      await _fetchAndActivate();
      
      // Inicia fetch periódico
      _startPeriodicFetch();
      
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      // TODO: Implementar logging - Erro ao inicializar Remote Config: $e
      _currentConfig = CacheRemoteConfig.defaultConfig;
      _configController.add(_currentConfig);
    }
  }

  /// Faz fetch e ativa as configurações
  Future<void> _fetchAndActivate() async {
    try {
      final fetchResult = await _remoteConfig.fetchAndActivate();
      
      if (fetchResult) {
        _updateCurrentConfig();
      }
    } catch (e) {
      // TODO: Implementar logging - Erro ao fazer fetch do Remote Config: $e
    }
  }

  /// Atualiza a configuração atual com os valores do Remote Config
  void _updateCurrentConfig() {
    try {
      final newConfig = CacheRemoteConfig(
        eventsTtl: Duration(
          seconds: _remoteConfig.getInt('cache_events_ttl_seconds'),
        ),
        barsTtl: Duration(
          seconds: _remoteConfig.getInt('cache_bars_ttl_seconds'),
        ),
        usersTtl: Duration(
          seconds: _remoteConfig.getInt('cache_users_ttl_seconds'),
        ),
        imagesTtl: Duration(
          seconds: _remoteConfig.getInt('cache_images_ttl_seconds'),
        ),
        maxCacheSizeMB: _remoteConfig.getInt('cache_max_size_mb'),
        maxImageCacheSizeMB: _remoteConfig.getInt('cache_max_image_size_mb'),
        maxEntries: _remoteConfig.getInt('cache_max_entries'),
        syncInterval: Duration(
          seconds: _remoteConfig.getInt('cache_sync_interval_seconds'),
        ),
        enableBackgroundSync: _remoteConfig.getBool('cache_enable_background_sync'),
        enablePrefetch: _remoteConfig.getBool('cache_enable_prefetch'),
        maxRetries: _remoteConfig.getInt('cache_max_retries'),
        initialRetryDelay: Duration(
          seconds: _remoteConfig.getInt('cache_initial_retry_delay_seconds'),
        ),
        backoffMultiplier: _remoteConfig.getDouble('cache_backoff_multiplier'),
        enableMetrics: _remoteConfig.getBool('cache_enable_metrics'),
        metricsFlushInterval: Duration(
          seconds: _remoteConfig.getInt('cache_metrics_flush_interval_seconds'),
        ),
        metricsRetentionPeriod: Duration(
          days: _remoteConfig.getInt('cache_metrics_retention_days'),
        ),
      );
      
      _currentConfig = newConfig;
      _configController.add(_currentConfig);
      
    } catch (e) {
      // TODO: Implementar logging - Erro ao atualizar configuração: $e
    }
  }

  /// Inicia fetch periódico das configurações
  void _startPeriodicFetch() {
    _fetchTimer?.cancel();
    _fetchTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _fetchAndActivate();
    });
  }

  /// Força um fetch manual das configurações
  Future<void> forceFetch() async {
    await _fetchAndActivate();
  }

  /// Obtém uma configuração específica por chave
  T getConfig<T>(String key, T defaultValue) {
    try {
      if (T == String) {
        return _remoteConfig.getString(key) as T;
      } else if (T == int) {
        return _remoteConfig.getInt(key) as T;
      } else if (T == double) {
        return _remoteConfig.getDouble(key) as T;
      } else if (T == bool) {
        return _remoteConfig.getBool(key) as T;
      }
    } catch (e) {
      // TODO: Implementar logging - Erro ao obter configuração $key: $e
    }
    
    return defaultValue;
  }

  /// Libera recursos
  void dispose() {
    _fetchTimer?.cancel();
    _configController.close();
  }
}