import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/cache/cache_store.dart';
import '../../data/firebase/firebase_image_storage_repository.dart';

/// Estados possíveis de um upload
enum UploadStatus {
  pending,    // Na fila, aguardando processamento
  uploading,  // Upload em andamento
  done,       // Upload concluído com sucesso
  failed,     // Upload falhou
}

/// Modelo para representar uma foto de evento
class EventPhoto {
  final String id;
  final String eventId;
  final String localPath;
  final String? storagePath;
  final String? url;
  final UploadStatus status;
  final DateTime createdAt;
  final String? errorMessage;

  EventPhoto({
    required this.id,
    required this.eventId,
    required this.localPath,
    this.storagePath,
    this.url,
    required this.status,
    required this.createdAt,
    this.errorMessage,
  });

  EventPhoto copyWith({
    String? id,
    String? eventId,
    String? localPath,
    String? storagePath,
    String? url,
    UploadStatus? status,
    DateTime? createdAt,
    String? errorMessage,
  }) {
    return EventPhoto(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      url: url ?? this.url,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Gerenciador de uploads de fotos com fila e persistência
class UploadManager extends ChangeNotifier {
  final FirebaseImageStorageRepository _storageRepository;
  final CacheStore<EventPhoto> _cacheStore;
  
  // Controle de concorrência
  static const int _maxConcurrentUploads = 2;
  int _activeUploads = 0;
  
  // Fila de uploads pendentes
  final List<EventPhoto> _uploadQueue = [];
  
  // Timer para retry automático
  Timer? _retryTimer;
  
  UploadManager(this._storageRepository, this._cacheStore) {
    _initializeFromCache();
  }

  /// Inicializa o manager carregando uploads pendentes do cache
  Future<void> _initializeFromCache() async {
    try {
      final cachedPhotos = await _cacheStore.getAll();
      final pendingPhotos = cachedPhotos.where(
        (photo) => photo.status == UploadStatus.pending || 
                   photo.status == UploadStatus.uploading
      ).toList();
      
      _uploadQueue.addAll(pendingPhotos);
      _processQueue();
    } catch (e) {
      debugPrint('Erro ao carregar uploads do cache: $e');
    }
  }

  /// Adiciona fotos à fila de upload
  Future<void> enqueue(List<File> files, String eventId) async {
    final photos = files.map((file) {
      final id = DateTime.now().millisecondsSinceEpoch.toString() + 
                 file.path.hashCode.toString();
      return EventPhoto(
        id: id,
        eventId: eventId,
        localPath: file.path,
        status: UploadStatus.pending,
        createdAt: DateTime.now(),
      );
    }).toList();

    // Adiciona à fila
    _uploadQueue.addAll(photos);
    
    // Salva no cache local
    for (final photo in photos) {
      await _cacheStore.put(photo.id, photo);
    }
    
    notifyListeners();
    _processQueue();
  }

  /// Processa a fila de uploads
  Future<void> _processQueue() async {
    while (_uploadQueue.isNotEmpty && _activeUploads < _maxConcurrentUploads) {
      final photo = _uploadQueue.removeAt(0);
      _activeUploads++;
      
      // Processa upload em paralelo
      _processUpload(photo).then((_) {
        _activeUploads--;
        _processQueue(); // Continua processando a fila
      });
    }
  }

  /// Processa um upload individual
  Future<void> _processUpload(EventPhoto photo) async {
    try {
      // Atualiza status para uploading
      final updatedPhoto = photo.copyWith(status: UploadStatus.uploading);
      await _cacheStore.put(photo.id, updatedPhoto);
      notifyListeners();

      // Realiza o upload
      final file = File(photo.localPath);
      final storagePath = 'events/${photo.eventId}/photos/${photo.id}.jpg';
      
      final url = await _storageRepository.uploadImage(
        file,
        storagePath,
      );

      // Upload bem-sucedido
      final completedPhoto = updatedPhoto.copyWith(
        status: UploadStatus.done,
        storagePath: storagePath,
        url: url,
      );
      
      await _cacheStore.put(photo.id, completedPhoto);
      notifyListeners();
      
    } catch (e) {
      debugPrint('Erro no upload da foto ${photo.id}: $e');
      
      // Marca como falhou
      final failedPhoto = photo.copyWith(
        status: UploadStatus.failed,
        errorMessage: e.toString(),
      );
      
      await _cacheStore.put(photo.id, failedPhoto);
      notifyListeners();
      
      // Agenda retry automático
      _scheduleRetry(failedPhoto);
    }
  }

  /// Agenda retry automático com backoff exponencial
  void _scheduleRetry(EventPhoto photo) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      retry(photo.id);
    });
  }

  /// Tenta novamente um upload que falhou
  Future<void> retry(String photoId) async {
    try {
      final photo = await _cacheStore.get(photoId);
      if (photo != null && photo.status == UploadStatus.failed) {
        final retryPhoto = photo.copyWith(status: UploadStatus.pending);
        await _cacheStore.put(photoId, retryPhoto);
        _uploadQueue.add(retryPhoto);
        notifyListeners();
        _processQueue();
      }
    } catch (e) {
      debugPrint('Erro ao tentar novamente upload $photoId: $e');
    }
  }

  /// Remove uma foto da fila e do storage se necessário
  Future<void> removePhoto(String photoId) async {
    try {
      final photo = await _cacheStore.get(photoId);
      if (photo == null) return;

      // Remove da fila se ainda estiver pendente
      _uploadQueue.removeWhere((p) => p.id == photoId);

      // Remove do storage se já foi feito upload
      if (photo.storagePath != null) {
        await _storageRepository.deleteImage(photo.storagePath!);
      }

      // Remove do cache local
      await _cacheStore.remove(photoId);
      notifyListeners();
      
    } catch (e) {
      debugPrint('Erro ao remover foto $photoId: $e');
    }
  }

  /// Observa fotos de um evento específico
  Stream<List<EventPhoto>> watch(String eventId) {
    return _cacheStore.watch().map((photos) => 
      photos.where((photo) => photo.eventId == eventId).toList()
    );
  }

  /// Obtém fotos de um evento específico
  Future<List<EventPhoto>> getPhotos(String eventId) async {
    final allPhotos = await _cacheStore.getAll();
    return allPhotos.where((photo) => photo.eventId == eventId).toList();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}