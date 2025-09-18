# 📁 STORAGE_ARCHITECTURE.md - Bar Boss Mobile

**Versão:** 2.0  
**Última Atualização:** 15 de Setembro de 2025  
**Objetivo:** Arquitetura específica de armazenamento de imagens e cache local

---

## 📋 1. Visão Geral

Este documento define a arquitetura de armazenamento do Bar Boss Mobile, incluindo Firebase Storage, cache local com Drift, e estratégias de upload/download de imagens.

### Componentes Principais
- **Firebase Storage:** Armazenamento de imagens na nuvem
- **Drift (SQLite):** Cache local e dados offline
- **ImageCacheService:** Gerenciamento inteligente de cache de imagens
- **Upload Service:** Serviço unificado para upload de arquivos

---

## 🏗️ 2. Estrutura do Firebase Storage

### Organização de Pastas
```
gs://bar-boss-mobile.appspot.com/
├── users/
│   └── {userId}/
│       ├── profile/
│       │   ├── avatar_original.jpg
│       │   ├── avatar_thumbnail.jpg
│       │   └── avatar_medium.jpg
│       └── temp/
│           └── {timestamp}_upload.jpg
├── bars/
│   └── {barId}/
│       ├── profile/
│       │   ├── photo_original.jpg
│       │   ├── photo_thumbnail.jpg
│       │   └── photo_medium.jpg
│       ├── events/
│       │   └── {eventId}/
│       │       ├── banner_original.jpg
│       │       ├── banner_thumbnail.jpg
│       │       ├── promotion_1_original.jpg
│       │       ├── promotion_1_thumbnail.jpg
│       │       └── promotion_2_original.jpg
│       └── temp/
│           └── {timestamp}_upload.jpg
└── system/
    ├── placeholders/
    │   ├── bar_default.jpg
    │   ├── user_default.jpg
    │   └── event_default.jpg
    └── cache/
        └── {hash}_processed.jpg
```

### Convenções de Nomenclatura
- **Originais:** `{type}_original.{ext}`
- **Thumbnails:** `{type}_thumbnail.{ext}` (150x150px)
- **Medium:** `{type}_medium.{ext}` (500x500px)
- **Temporários:** `{timestamp}_{uuid}_upload.{ext}`

---

## 💾 3. Cache Local com Drift

### Estrutura do Banco Local
```dart
// lib/app/data/cache/drift/cache_database.dart
@DriftDatabase(tables: [
  CachedImages,
  CachedBars,
  CachedEvents,
  CachedUsers,
  CacheMetrics
])
class CacheDatabase extends _$CacheDatabase {
  // Implementação do banco local
}
```

### Tabela de Imagens Cacheadas
```dart
class CachedImages extends Table {
  TextColumn get id => text()();
  TextColumn get originalUrl => text()();
  TextColumn get localPath => text()();
  TextColumn get size => text()(); // original, thumbnail, medium
  IntColumn get fileSize => integer()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessed => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Estratégias de Cache
- **LRU (Least Recently Used):** Remove imagens menos acessadas
- **TTL (Time To Live):** Expiração automática baseada em tempo
- **Size-based:** Limite de tamanho total do cache (100MB padrão)
- **Preload:** Carregamento antecipado de imagens críticas

---

## 📤 4. Serviço de Upload

### Interface Unificada
```dart
// lib/app/data/services/storage_service.dart
abstract class StorageService {
  Future<UploadResult> uploadImage({
    required File imageFile,
    required String path,
    required ImageType type,
    bool generateThumbnails = true,
    ProgressCallback? onProgress,
  });
  
  Future<void> deleteImage(String path);
  Future<String?> getDownloadUrl(String path);
}
```

### Implementação Firebase
```dart
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImageCacheService _cacheService;
  
  @override
  Future<UploadResult> uploadImage({
    required File imageFile,
    required String path,
    required ImageType type,
    bool generateThumbnails = true,
    ProgressCallback? onProgress,
  }) async {
    // 1. Validar arquivo
    _validateImage(imageFile);
    
    // 2. Gerar versões (original, thumbnail, medium)
    final versions = await _generateImageVersions(imageFile, type);
    
    // 3. Upload paralelo das versões
    final uploadTasks = versions.map((version) => 
      _uploadSingleVersion(version, path, onProgress)
    );
    
    final results = await Future.wait(uploadTasks);
    
    // 4. Atualizar cache local
    await _updateLocalCache(results);
    
    return UploadResult(
      originalUrl: results.first.downloadUrl,
      thumbnailUrl: results.last.downloadUrl,
      mediumUrl: results[1].downloadUrl,
    );
  }
}
```

### Upload Paralelo e Otimizado
- **Compressão automática:** Reduz tamanho sem perder qualidade
- **Upload paralelo:** Múltiplas versões simultaneamente
- **Progress tracking:** Feedback em tempo real
- **Retry automático:** Reenvio em caso de falha
- **Validação:** Formato, tamanho e dimensões

---

## 🖼️ 5. Gerenciamento de Imagens

### ImageCacheService
```dart
// lib/app/data/cache/services/image_cache_service.dart
class ImageCacheService {
  final CacheDatabase _database;
  final Directory _cacheDir;
  
  // Buscar imagem (cache-first)
  Future<File?> getImage(String url, {ImageSize size = ImageSize.original}) async {
    // 1. Verificar cache local
    final cached = await _getCachedImage(url, size);
    if (cached != null && await cached.exists()) {
      await _updateLastAccessed(url, size);
      return cached;
    }
    
    // 2. Download e cache
    return await _downloadAndCache(url, size);
  }
  
  // Pré-carregar imagens críticas
  Future<void> preloadImages(List<String> urls) async {
    final tasks = urls.map((url) => getImage(url, size: ImageSize.thumbnail));
    await Future.wait(tasks);
  }
  
  // Limpeza automática
  Future<void> cleanupCache() async {
    await _removeExpiredImages();
    await _enforceSizeLimit();
    await _removeLRUImages();
  }
}
```

### Tamanhos de Imagem
```dart
enum ImageSize {
  original,   // Tamanho original (máx 2MB)
  medium,     // 500x500px (máx 200KB)
  thumbnail,  // 150x150px (máx 50KB)
}
```

### Estratégias de Carregamento
- **Progressive loading:** Thumbnail → Medium → Original
- **Placeholder:** Imagem padrão durante carregamento
- **Lazy loading:** Carregamento sob demanda
- **Batch loading:** Múltiplas imagens em lote

---

## 🔐 6. Regras de Segurança

### Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Função para verificar propriedade do usuário
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Função para verificar membro do bar
    function isBarMember(barId) {
      return request.auth != null && 
             exists(/databases/(default)/documents/bars/$(barId)/members/$(request.auth.uid));
    }
    
    // Perfil de usuários
    match /users/{userId}/{allPaths=**} {
      allow read, write: if isOwner(userId);
    }
    
    // Dados de bares
    match /bars/{barId}/{allPaths=**} {
      allow read: if isBarMember(barId);
      allow write: if isBarMember(barId) && 
                      resource.size < 5 * 1024 * 1024; // 5MB máximo
    }
    
    // Arquivos temporários (1 hora de vida)
    match /temp/{allPaths=**} {
      allow write: if request.auth != null && 
                      resource.size < 10 * 1024 * 1024; // 10MB máximo
      allow read: if request.auth != null;
    }
    
    // Recursos do sistema (somente leitura)
    match /system/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### Validações de Upload
- **Formatos permitidos:** JPG, PNG, WebP
- **Tamanho máximo:** 5MB por arquivo
- **Dimensões mínimas:** 100x100px
- **Dimensões máximas:** 4096x4096px
- **Rate limiting:** 10 uploads por minuto por usuário

---

## 📊 7. Monitoramento e Métricas

### Métricas Coletadas
```dart
class CacheMetrics {
  final int hitCount;        // Cache hits
  final int missCount;       // Cache misses
  final int totalRequests;   // Total de requisições
  final double hitRate;      // Taxa de acerto
  final int cacheSize;       // Tamanho atual do cache
  final int totalFiles;      // Número de arquivos
  final DateTime lastCleanup; // Última limpeza
}
```

### Alertas e Limites
- **Cache hit rate < 70%:** Revisar estratégia de cache
- **Cache size > 150MB:** Limpeza forçada
- **Upload failures > 5%:** Investigar conectividade
- **Download latency > 3s:** Otimizar compressão

### Logs de Auditoria
```dart
class StorageAuditLog {
  final String userId;
  final String action;       // upload, download, delete
  final String filePath;
  final int fileSize;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;
}
```

---

## ⚡ 8. Otimizações de Performance

### Compressão Inteligente
```dart
class ImageCompressor {
  static Future<File> compress(File image, ImageSize targetSize) async {
    switch (targetSize) {
      case ImageSize.thumbnail:
        return await _compressToThumbnail(image); // 150x150, 50KB
      case ImageSize.medium:
        return await _compressToMedium(image);    // 500x500, 200KB
      case ImageSize.original:
        return await _compressOriginal(image);    // Máx 2MB, qualidade 85%
    }
  }
}
```

### Upload Inteligente
- **Delta sync:** Upload apenas de mudanças
- **Deduplicação:** Evita uploads duplicados via hash
- **Background upload:** Upload em segundo plano
- **Bandwidth adaptation:** Ajusta qualidade conforme conexão

### Cache Warming
```dart
class CacheWarmingService {
  // Pré-carrega imagens críticas na inicialização
  Future<void> warmupCache() async {
    final criticalImages = [
      'system/placeholders/bar_default.jpg',
      'system/placeholders/user_default.jpg',
      'system/placeholders/event_default.jpg',
    ];
    
    await _imageCache.preloadImages(criticalImages);
  }
}
```

---

## 🔄 9. Sincronização e Backup

### Estratégia de Sincronização
- **Upload-first:** Prioriza upload de dados locais
- **Conflict resolution:** Timestamp-based para conflitos
- **Partial sync:** Sincroniza apenas mudanças
- **Retry logic:** Exponential backoff para falhas

### Backup Automático
- **Incremental:** Backup apenas de mudanças
- **Scheduled:** Backup diário em horário de baixo uso
- **Versioning:** Mantém 3 versões de cada arquivo
- **Compression:** Compressão para reduzir custos

---

## 🧪 10. Testes e Validação

### Testes de Upload
```dart
group('Storage Service Tests', () {
  test('should upload image with thumbnails', () async {
    final result = await storageService.uploadImage(
      imageFile: testImage,
      path: 'test/upload.jpg',
      type: ImageType.barProfile,
    );
    
    expect(result.originalUrl, isNotNull);
    expect(result.thumbnailUrl, isNotNull);
    expect(result.mediumUrl, isNotNull);
  });
});
```

### Testes de Cache
```dart
group('Image Cache Tests', () {
  test('should cache and retrieve image', () async {
    await cacheService.cacheImage(testUrl, testFile);
    final cached = await cacheService.getImage(testUrl);
    
    expect(cached, isNotNull);
    expect(await cached!.exists(), isTrue);
  });
});
```

### Testes de Performance
- **Load testing:** 100 uploads simultâneos
- **Memory testing:** Uso de memória durante cache
- **Network testing:** Comportamento offline/online
- **Storage testing:** Limites de armazenamento

---

## 📚 11. Documentação Relacionada

Para informações complementares, consulte:

- **[FIRESTORE_SCHEMA.md](./FIRESTORE_SCHEMA.md)**: Estrutura de dados
- **[FIRESTORE_RULES.md](./FIRESTORE_RULES.md)**: Regras de segurança
- **[BUSINESS_RULES_AUTH.md](./BUSINESS_RULES_AUTH.md)**: Regras de autenticação
- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras gerais do projeto
- **[cache-architecture.md](./docs/cache-architecture.md)**: Arquitetura detalhada de cache
- **[FIREBASE_BACKEND_GUIDE.md](./FIREBASE_BACKEND_GUIDE.md)**: Configuração do Firebase
- **[bar-profile-feature.md](./docs/bar-profile-feature.md)**: Implementação de perfil com fotos

---

## 🔄 12. Histórico de Mudanças

### v2.0 (15/09/2025)
- Atualização completa da arquitetura de storage
- Integração com cache local Drift
- Implementação de upload paralelo
- Adição de métricas e monitoramento
- Regras de segurança aprimoradas

### v1.0 (10/09/2025)
- Versão inicial da arquitetura
- Estrutura básica do Firebase Storage
- Cache simples de imagens

---

**📝 Nota:** Este documento deve ser atualizado sempre que houver mudanças na arquitetura de armazenamento ou nas estratégias de cache.