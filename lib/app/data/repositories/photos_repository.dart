import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/event_photo.dart';
import 'event_photos_repository.dart';

/// Repository para gerenciar upload e sincronização de fotos
/// Coordena entre cache local (EventPhotosRepository) e Firebase (Storage + Firestore)
class PhotosRepository {
  final EventPhotosRepository _eventPhotosRepository;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  PhotosRepository({
    required EventPhotosRepository eventPhotosRepository,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _eventPhotosRepository = eventPhotosRepository,
        _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  /// Obtém todas as fotos de um evento
  Future<List<EventPhoto>> getEventPhotos(String eventId) async {
    return await _eventPhotosRepository.getEventPhotos(eventId);
  }

  /// Adiciona uma nova foto ao evento
  /// 1. Salva no cache local primeiro
  /// 2. Agenda upload em background
  Future<String> uploadPhoto({
    required String eventId,
    required File imageFile,
    String? description,
  }) async {
    try {
      // 1. Salvar no cache local primeiro e obter foto
      final photo = await _eventPhotosRepository.addPhoto(
        eventId: eventId,
        imageFile: imageFile,
        metadata: description != null ? {'description': description} : null,
      );
      
      // 2. Obter informações da imagem
      final imageBytes = await imageFile.readAsBytes();
      
      // 3. Definir caminho no Storage
      final fileName = '${photo.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'events/$eventId/photos/$fileName';
      
      // 4. Fazer upload para Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'photoId': photo.id,
            'originalName': path.basename(imageFile.path),
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // 5. Monitorar progresso do upload
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        _eventPhotosRepository.updatePhotoStatus(
          photo.id,
          EventPhotoUploadStatus.uploading,
          progress: progress.toInt(),
        );
      });

      // 6. Aguardar conclusão e obter URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 7. Atualizar status no cache local
      await _eventPhotosRepository.updatePhotoStatus(
        photo.id,
        EventPhotoUploadStatus.completed,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
      );

      // 8. Salvar metadados no Firestore
      await _firestore.collection('event_photos').doc(photo.id).set({
        'eventId': eventId,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'originalName': path.basename(imageFile.path),
        'fileSize': imageBytes.length,
        'mimeType': 'image/jpeg',
        'description': description,
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return photo.id;
    } catch (e) {
      debugPrint('Erro no upload da foto: $e');
      rethrow;
    }
  }

  /// Remove uma foto do evento
  Future<void> deletePhoto(String photoId) async {
    try {
      await _eventPhotosRepository.removePhoto(photoId);
    } catch (e) {
      debugPrint('Erro ao remover foto: $e');
      rethrow;
    }
  }

  /// Sincroniza fotos pendentes com Firebase
  Future<void> syncPendingPhotos() async {
    try {
      debugPrint('Iniciando sincronização de fotos pendentes...');
      
      // 1. Obter fotos com status pendente ou com erro
      final pendingPhotos = await _eventPhotosRepository.getPendingPhotos();
      
      if (pendingPhotos.isEmpty) {
        debugPrint('Nenhuma foto pendente para sincronizar');
        return;
      }
      
      debugPrint('Encontradas ${pendingPhotos.length} fotos pendentes');
      
      // 2. Processar cada foto pendente
      for (final photo in pendingPhotos) {
        try {
          await _syncSinglePhoto(photo);
        } catch (e) {
          debugPrint('Erro ao sincronizar foto ${photo.id}: $e');
          // Marcar como erro mas continuar com as outras
          await _eventPhotosRepository.updatePhotoStatus(
            photo.id,
            EventPhotoUploadStatus.failed,
          );
        }
      }
      
      debugPrint('Sincronização de fotos pendentes concluída');
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
    }
  }

  /// Sincroniza uma única foto
  Future<void> _syncSinglePhoto(EventPhoto photo) async {
    // Verificar se o arquivo local ainda existe
    final localFile = File(photo.localPath);
    if (!await localFile.exists()) {
      debugPrint('Arquivo local não encontrado: ${photo.localPath}');
      await _eventPhotosRepository.updatePhotoStatus(
        photo.id,
        EventPhotoUploadStatus.failed,
      );
      return;
    }

    // Atualizar status para uploading
    await _eventPhotosRepository.updatePhotoStatus(
      photo.id,
      EventPhotoUploadStatus.uploading,
      progress: 0,
    );

    // Ler bytes do arquivo
    final imageBytes = await localFile.readAsBytes();
    
    // Definir caminho no Storage
    final fileName = '${photo.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'events/${photo.eventId}/photos/$fileName';
    
    // Fazer upload para Storage
    final storageRef = _storage.ref().child(storagePath);
    final uploadTask = storageRef.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'eventId': photo.eventId,
          'photoId': photo.id,
          'originalName': path.basename(photo.localPath),
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    // Monitorar progresso do upload
    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
      _eventPhotosRepository.updatePhotoStatus(
        photo.id,
        EventPhotoUploadStatus.uploading,
        progress: progress.toInt(),
      );
    });

    // Aguardar conclusão e obter URL
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Atualizar status no cache local
    await _eventPhotosRepository.updatePhotoStatus(
      photo.id,
      EventPhotoUploadStatus.completed,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );

    // Salvar metadados no Firestore
    await _firestore.collection('event_photos').doc(photo.id).set({
      'eventId': photo.eventId,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'originalName': path.basename(photo.localPath),
      'fileSize': imageBytes.length,
      'mimeType': 'image/jpeg',
      'description': photo.metadata?['description'],
      'uploadedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Foto ${photo.id} sincronizada com sucesso');
  }

  /// Limpa fotos antigas do cache local
  Future<void> cleanupOldPhotos({int maxAgeInDays = 30}) async {
    try {
      await _eventPhotosRepository.cleanupOldPhotos(maxAgeInDays: maxAgeInDays);
    } catch (e) {
      debugPrint('Erro na limpeza: $e');
    }
  }

  /// Obtém estatísticas de armazenamento
  Future<StorageStats> getStorageStats() async {
    try {
      // Obter todas as fotos do cache local
      final allPhotos = await _eventPhotosRepository.getAllPhotos();
      
      int totalPhotos = allPhotos.length;
      int totalSize = 0;
      int pendingUploads = 0;
      
      // Calcular estatísticas
      for (final photo in allPhotos) {
        // Contar uploads pendentes
        if (photo.uploadStatus == EventPhotoUploadStatus.pending ||
            photo.uploadStatus == EventPhotoUploadStatus.failed) {
          pendingUploads++;
        }
        
        // Calcular tamanho total (se o arquivo local existe)
        if (photo.localPath.isNotEmpty) {
          final file = File(photo.localPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            totalSize += fileSize;
          }
        }
      }
      
      return StorageStats(
        totalPhotos: totalPhotos,
        totalSize: totalSize,
        pendingUploads: pendingUploads,
      );
    } catch (e) {
      debugPrint('Erro ao obter estatísticas: $e');
      return StorageStats(totalPhotos: 0, totalSize: 0, pendingUploads: 0);
    }
  }
}

/// Classe para estatísticas de armazenamento
class StorageStats {
  final int totalPhotos;
  final int totalSize; // em bytes
  final int pendingUploads;

  StorageStats({
    required this.totalPhotos,
    required this.totalSize,
    required this.pendingUploads,
  });

  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}