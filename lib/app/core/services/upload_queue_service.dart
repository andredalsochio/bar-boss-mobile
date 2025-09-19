import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:bar_boss_mobile/app/core/services/image_processing_service.dart';

/// Estados possíveis de um item na fila de upload
enum UploadStatus { pending, uploading, done, failed }

/// Item da fila de upload
class UploadQueueItem {
  final String id;
  final File file;
  final String eventId;
  UploadStatus status;
  String? downloadUrl;
  String? errorMessage;
  int retryCount;
  
  UploadQueueItem({
    required this.id,
    required this.file,
    required this.eventId,
    this.status = UploadStatus.pending,
    this.downloadUrl,
    this.errorMessage,
    this.retryCount = 0,
  });
  
  UploadQueueItem copyWith({
    UploadStatus? status,
    String? downloadUrl,
    String? errorMessage,
    int? retryCount,
  }) {
    return UploadQueueItem(
      id: id,
      file: file,
      eventId: eventId,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Serviço para gerenciar fila de upload de imagens em segundo plano
class UploadQueueService extends ChangeNotifier {
  static const int maxRetries = 2;
  static const int maxConcurrentUploads = 2;
  
  final List<UploadQueueItem> _queue = [];
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  int _activeUploads = 0;
  bool _isProcessing = false;
  
  /// Lista de itens na fila
  List<UploadQueueItem> get queue => List.unmodifiable(_queue);
  
  /// Indica se há uploads em andamento
  bool get hasActiveUploads => _activeUploads > 0;
  
  /// Indica se está processando a fila
  bool get isProcessing => _isProcessing;
  
  /// Lista de itens falhados
  List<UploadQueueItem> get failedItems => _queue.where((item) => item.status == UploadStatus.failed).toList();
  
  /// Indica se há itens falhados
  bool get hasFailedItems => failedItems.isNotEmpty;
  
  /// Adiciona arquivos à fila de upload
  Future<List<String>> enqueue(List<File> files, String eventId) async {
    debugPrint('📤 [UploadQueue] Enfileirando ${files.length} arquivos para evento $eventId');
    
    final itemIds = <String>[];
    
    for (final file in files) {
      final itemId = _uuid.v4();
      final item = UploadQueueItem(
        id: itemId,
        file: file,
        eventId: eventId,
      );
      
      _queue.add(item);
      itemIds.add(itemId);
      
      debugPrint('📤 [UploadQueue] Item $itemId adicionado à fila');
    }
    
    notifyListeners();
    
    // Inicia o processamento se não estiver rodando
    if (!_isProcessing) {
      _processQueue();
    }
    
    return itemIds;
  }
  
  /// Obtém itens da fila por evento
  List<UploadQueueItem> getItemsByEvent(String eventId) {
    return _queue.where((item) => item.eventId == eventId).toList();
  }
  
  /// Reenviar item falhado
  Future<void> retryItem(String itemId) async {
    final itemIndex = _queue.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    
    final item = _queue[itemIndex];
    if (item.status != UploadStatus.failed) return;
    
    debugPrint('🔄 [UploadQueue] Reenviando item $itemId (tentativa ${item.retryCount + 1})');
    
    _queue[itemIndex] = item.copyWith(
      status: UploadStatus.pending,
      errorMessage: null,
    );
    
    notifyListeners();
    
    if (!_isProcessing) {
      _processQueue();
    }
  }
  
  /// Reenviar todos os itens falhados
  Future<void> retryAllFailed() async {
    final failed = failedItems;
    if (failed.isEmpty) return;
    
    debugPrint('🔄 [UploadQueue] Reenviando ${failed.length} itens falhados');
    
    for (final item in failed) {
      final itemIndex = _queue.indexWhere((queueItem) => queueItem.id == item.id);
      if (itemIndex != -1) {
        _queue[itemIndex] = item.copyWith(
          status: UploadStatus.pending,
          errorMessage: null,
        );
      }
    }
    
    notifyListeners();
    
    if (!_isProcessing) {
      _processQueue();
    }
  }
  
  /// Remove item da fila
  void removeItem(String itemId) {
    final itemIndex = _queue.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    
    final item = _queue[itemIndex];
    
    // Se estiver fazendo upload, não pode remover
    if (item.status == UploadStatus.uploading) {
      debugPrint('⚠️ [UploadQueue] Não é possível remover item em upload: $itemId');
      return;
    }
    
    // Se já foi enviado, remove do Storage e Firestore
    if (item.status == UploadStatus.done && item.downloadUrl != null) {
      _deleteUploadedImage(item);
    }
    
    _queue.removeAt(itemIndex);
    notifyListeners();
    
    debugPrint('🗑️ [UploadQueue] Item $itemId removido da fila');
  }
  
  /// Processa a fila de upload
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    debugPrint('⚙️ [UploadQueue] Iniciando processamento da fila');
    
    while (_queue.any((item) => item.status == UploadStatus.pending) && 
           _activeUploads < maxConcurrentUploads) {
      
      final pendingItem = _queue.firstWhere(
        (item) => item.status == UploadStatus.pending,
        orElse: () => throw StateError('Nenhum item pendente encontrado'),
      );
      
      _uploadItem(pendingItem);
    }
    
    // Aguarda todos os uploads terminarem
    while (_activeUploads > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    _isProcessing = false;
    debugPrint('✅ [UploadQueue] Processamento da fila concluído');
  }
  
  /// Faz upload de um item específico
  Future<void> _uploadItem(UploadQueueItem item) async {
    final itemIndex = _queue.indexWhere((i) => i.id == item.id);
    if (itemIndex == -1) return;
    
    _activeUploads++;
    _queue[itemIndex] = item.copyWith(status: UploadStatus.uploading);
    notifyListeners();
    
    debugPrint('📤 [UploadQueue] Iniciando upload do item ${item.id}');
    
    try {
      // Processa a imagem
      File processedFile = item.file;
      if (!item.file.path.contains('processed_')) {
        final newProcessedFile = await ImageProcessingService.processSelectedImage(item.file);
        if (newProcessedFile != null) {
          processedFile = newProcessedFile;
        }
      }
      
      // Upload para o Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
      final storageRef = _storage
          .ref()
          .child('events')
          .child(item.eventId)
          .child('images')
          .child(fileName);
      
      final uploadTask = storageRef.putFile(processedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Salva na subcoleção do Firestore
      await _firestore
          .collection('events')
          .doc(item.eventId)
          .collection('images')
          .doc(item.id)
          .set({
        'id': item.id,
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Atualiza o item como concluído
      _queue[itemIndex] = item.copyWith(
        status: UploadStatus.done,
        downloadUrl: downloadUrl,
      );
      
      debugPrint('✅ [UploadQueue] Upload concluído: ${item.id} -> $downloadUrl');
      
      // Limpa arquivos temporários
      await ImageProcessingService.cleanupTempFiles();
      
    } catch (e) {
      debugPrint('❌ [UploadQueue] Erro no upload do item ${item.id}: $e');
      
      // Verifica se deve tentar novamente
      if (item.retryCount < maxRetries) {
        _queue[itemIndex] = item.copyWith(
          status: UploadStatus.pending,
          retryCount: item.retryCount + 1,
          errorMessage: e.toString(),
        );
        debugPrint('🔄 [UploadQueue] Item ${item.id} será reenviado (tentativa ${item.retryCount + 1})');
      } else {
        _queue[itemIndex] = item.copyWith(
          status: UploadStatus.failed,
          errorMessage: e.toString(),
        );
        debugPrint('💥 [UploadQueue] Item ${item.id} falhou definitivamente após $maxRetries tentativas');
      }
    } finally {
      _activeUploads--;
      notifyListeners();
    }
  }
  
  /// Remove imagem do Storage e Firestore
  Future<void> _deleteUploadedImage(UploadQueueItem item) async {
    try {
      if (item.downloadUrl != null) {
        // Remove do Storage
        final ref = _storage.refFromURL(item.downloadUrl!);
        await ref.delete();
        
        // Remove do Firestore
        await _firestore
            .collection('events')
            .doc(item.eventId)
            .collection('images')
            .doc(item.id)
            .delete();
        
        debugPrint('🗑️ [UploadQueue] Imagem removida: ${item.id}');
      }
    } catch (e) {
      debugPrint('⚠️ [UploadQueue] Erro ao remover imagem ${item.id}: $e');
    }
  }
  
  /// Limpa itens concluídos da fila
  void clearCompletedItems() {
    _queue.removeWhere((item) => item.status == UploadStatus.done);
    notifyListeners();
    debugPrint('🧹 [UploadQueue] Itens concluídos removidos da fila');
  }
  
  /// Obtém estatísticas da fila
  Map<String, int> getQueueStats() {
    final stats = <String, int>{
      'pending': 0,
      'uploading': 0,
      'done': 0,
      'failed': 0,
    };
    
    for (final item in _queue) {
      switch (item.status) {
        case UploadStatus.pending:
          stats['pending'] = stats['pending']! + 1;
          break;
        case UploadStatus.uploading:
          stats['uploading'] = stats['uploading']! + 1;
          break;
        case UploadStatus.done:
          stats['done'] = stats['done']! + 1;
          break;
        case UploadStatus.failed:
          stats['failed'] = stats['failed']! + 1;
          break;
      }
    }
    
    return stats;
  }
}