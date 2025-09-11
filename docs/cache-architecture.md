# Arquitetura de Cache - Bar Boss Mobile

**Versão:** 1.0  
**Última Atualização:** 10 de Setembro de 2025

## Visão Geral

Este documento descreve a arquitetura de cache implementada no aplicativo Bar Boss Mobile, projetada para oferecer uma experiência offline-first com sincronização inteligente e alta performance.

## Componentes Principais

### 1. Cache Database (Drift)

**Localização**: `lib/app/data/cache/drift/cache_database.dart`

Banco de dados local usando Drift (SQLite) para armazenamento estruturado:

- **CachedEvents**: Cache de eventos com TTL e metadados
- **CachedBars**: Cache de dados de bares
- **CachedUsers**: Cache de informações de usuários
- **CachedImages**: Índice de imagens em cache com diferentes tamanhos
- **CachedData**: Cache genérico para dados diversos
- **CacheMetrics**: Métricas de performance do cache

### 2. Interfaces Base

**Localização**: `lib/app/domain/cache/`

#### CacheStore<T>
Interface base para operações de cache:
```dart
abstract class CacheStore<T> {
  Future<T?> get(String key);
  Future<void> put(String key, T value, {Duration? ttl});
  Future<void> remove(String key);
  Future<void> clear();
}
```

#### RemoteStore<T>
Interface para fontes de dados remotas:
```dart
abstract class RemoteStore<T> {
  Future<T?> fetch(String key);
  Future<void> save(String key, T value);
}
```

#### Repository<T>
Interface unificada combinando cache e remote:
```dart
abstract class Repository<T> {
  Future<T?> get(String key, {bool forceRefresh = false});
  Future<void> save(String key, T value);
}
```

### 3. Serviços de Cache

#### FirestoreCacheService
**Localização**: `lib/app/data/cache/services/firestore_cache_service.dart`

- Cache local para dados do Firestore
- Mapeamento automático DTO ⇄ Entidades
- Estratégia Stale-While-Revalidate
- Suporte a TTL configurável

#### ImageCacheService
**Localização**: `lib/app/data/cache/services/image_cache_service.dart`

- Cache de imagens em disco
- Suporte a múltiplos tamanhos (original, thumbnail, medium)
- Compressão automática
- Limpeza baseada em LRU
- **Integração**: Perfil do bar, fotos de eventos, avatars de usuários
- **Invalidação**: Automática após upload de nova foto
- **Fallback**: Placeholder durante carregamento, retry em falhas

#### SyncService
**Localização**: `lib/app/data/cache/services/sync_service.dart`

- Sincronização offline-first
- Detecção de conectividade
- Sincronização em background
- Resolução de conflitos

#### WriteQueueService
**Localização**: `lib/app/data/cache/services/write_queue_service.dart`

- Fila de operações write-behind
- Retry com exponential backoff
- Persistência de operações pendentes
- Processamento em lote

#### CachePolicyService
**Localização**: `lib/app/data/cache/services/cache_policy_service.dart`

- Gerenciamento de TTL
- Políticas de invalidação
- Estratégias LRU
- Limpeza automática

#### CacheMetricsService
**Localização**: `lib/app/data/cache/services/cache_metrics_service.dart`

- Coleta de métricas de performance
- Hit/miss rates
- Latência de operações
- Tamanho do cache

#### CacheRemoteConfigService
**Localização**: `lib/app/data/cache/services/remote_config_service.dart`

- Configuração dinâmica via Firebase Remote Config
- TTLs configuráveis
- Limites de cache ajustáveis
- Flags de feature

### 4. Providers

**Localização**: `lib/app/data/cache/providers/`

Providers para injeção de dependência usando Provider:

- `cache_database_providers.dart`: Database e DAOs
- `firestore_cache_providers.dart`: Serviços de cache Firestore
- `image_cache_providers.dart`: Serviço de cache de imagens
- `sync_providers.dart`: Serviços de sincronização
- `write_queue_providers.dart`: Fila de escrita
- `cache_policy_providers.dart`: Políticas de cache
- `cache_metrics_providers.dart`: Métricas
- `remote_config_providers.dart`: Remote Config

## Estratégias de Cache

### 1. Stale-While-Revalidate

- Retorna dados do cache imediatamente
- Atualiza em background se necessário
- Garante resposta rápida mesmo com dados ligeiramente desatualizados

### 2. Write-Behind

- Operações de escrita são enfileiradas
- Processamento assíncrono em background
- Retry automático em caso de falha
- Melhora a responsividade da UI

### 3. TTL Dinâmico

- TTL configurável via Remote Config
- Diferentes TTLs para diferentes tipos de dados:
  - Eventos: 1 hora (padrão)
  - Bares: 6 horas (padrão)
  - Usuários: 12 horas (padrão)
  - Imagens: 7 dias (padrão)

### 4. LRU (Least Recently Used)

- Remove itens menos utilizados quando limite é atingido
- Baseado em último acesso
- Configurável via Remote Config

## Configuração via Remote Config

### Parâmetros Configuráveis

```yaml
# TTL configurations (em segundos)
cache_events_ttl_seconds: 3600      # 1 hora
cache_bars_ttl_seconds: 21600       # 6 horas
cache_users_ttl_seconds: 43200      # 12 horas
cache_images_ttl_seconds: 604800    # 7 dias

# Cache size limits
cache_max_size_mb: 100
cache_max_image_size_mb: 200
cache_max_entries: 10000

# Sync configurations
cache_sync_interval_seconds: 900     # 15 minutos
cache_enable_background_sync: true
cache_enable_prefetch: true

# Retry configurations
cache_max_retries: 3
cache_initial_retry_delay_seconds: 1
cache_backoff_multiplier: 2.0

# Metrics configurations
cache_enable_metrics: true
cache_metrics_flush_interval_seconds: 300  # 5 minutos
cache_metrics_retention_days: 7
```

## Métricas e Observabilidade

### Métricas Coletadas

- **Hit Rate**: Percentual de acertos no cache
- **Miss Rate**: Percentual de falhas no cache
- **Latência**: Tempo de resposta das operações
- **Tamanho**: Uso de memória e disco
- **Evictions**: Número de itens removidos
- **Expirations**: Número de itens expirados

### Agregação

- Métricas agregadas em intervalos de 5 minutos
- Retenção de 7 dias (configurável)
- Flush automático para o banco

## Fluxo de Dados

### Leitura (Get)

1. Verifica cache local
2. Se encontrado e válido (TTL), retorna
3. Se não encontrado ou expirado:
   - Retorna dados do cache (se disponível)
   - Busca dados remotos em background
   - Atualiza cache com novos dados

### Escrita (Put)

1. Salva no cache local imediatamente
2. Adiciona operação à fila de escrita
3. Processa fila em background
4. Retry automático em caso de falha

### Upload de Imagens (Perfil do Bar)

```dart
// 1. Upload para Firebase Storage
final downloadUrl = await storageService.uploadImage(imageFile);

// 2. Atualizar Firestore
await firestoreService.updateBar(barId, {'photoUrl': downloadUrl});

// 3. Invalidar cache da imagem anterior
await imageCacheService.invalidate('bar_photo_$barId');

// 4. Pré-carregar nova imagem no cache
await imageCacheService.preload(downloadUrl, 'bar_photo_$barId');
```

### Sincronização

1. Monitora conectividade
2. Sincroniza dados pendentes quando online
3. Resolve conflitos usando timestamp
4. Atualiza cache com dados mais recentes

## Integração com a Aplicação

### Setup no AppWidget

```dart
MultiProvider(
  providers: [
    ...CacheDatabaseProviders.providers,
    ...FirestoreCacheProviders.providers,
    ...ImageCacheProviders.providers,
    ...SyncProviders.providers,
    ...WriteQueueProviders.providers,
    ...CachePolicyProviders.providers,
    ...CacheMetricsProviders.providers,
    ...RemoteConfigProviders.providers,
  ],
  child: MyApp(),
)
```

### Uso nos ViewModels

```dart
class EventsViewModel extends ChangeNotifier {
  final Repository<Event> _eventsRepository;
  
  Future<List<Event>> getEvents() async {
    // Dados retornados do cache imediatamente
    // Atualização em background se necessário
    return await _eventsRepository.getAll();
  }
}

class BarProfileViewModel extends ChangeNotifier {
  final BarRepository _repository;
  final ImageCacheService _imageCache;
  
  Future<void> uploadBarPhoto(File imageFile) async {
    setLoading(true);
    try {
      // Upload e atualização com invalidação de cache
      final photoUrl = await _repository.uploadBarPhoto(imageFile);
      
      // Cache da nova imagem
      await _imageCache.cacheFromUrl(photoUrl, 'bar_photo_${bar.id}');
      
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}
```

## Benefícios

1. **Performance**: Resposta imediata com dados em cache
2. **Offline-First**: Funciona sem conexão
3. **Sincronização Inteligente**: Atualiza apenas quando necessário
4. **Configurabilidade**: Ajustes via Remote Config
5. **Observabilidade**: Métricas detalhadas de performance
6. **Escalabilidade**: Suporte a grandes volumes de dados
7. **Manutenibilidade**: Arquitetura modular e testável

## Considerações de Performance

- Cache em memória para dados frequentemente acessados
- Compressão de imagens automática
- Limpeza automática baseada em LRU
- Processamento em background para não bloquear UI
- Batch operations para melhor throughput

## Segurança

- Dados sensíveis não são armazenados em cache
- Criptografia de dados em repouso (SQLite)
- Validação de integridade dos dados
- Limpeza automática de dados expirados