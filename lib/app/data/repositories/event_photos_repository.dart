import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../models/event_photo.dart' as models;
import '../cache/drift/cache_database.dart';

/// Repositório para gerenciar fotos de eventos
/// Combina persistência local (Drift) com sincronização Firebase
class EventPhotosRepository {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final CacheDatabase _database;
  final Uuid _uuid;
  
  // TODO: Adicionar referência ao banco Drift quando implementado
  // final CacheDatabase _localDb;

  EventPhotosRepository({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    CacheDatabase? database,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? CacheDatabase(),
        _uuid = const Uuid();

  /// Adiciona uma nova foto ao evento
  /// Processa a imagem, salva localmente e agenda upload
  Future<models.EventPhoto> addPhoto({
    required String eventId,
    required File imageFile,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Gera ID único para a foto
      final photoId = _uuid.v4();
      
      // Processa a imagem (redimensiona se necessário)
      final processedFile = await _processImage(imageFile);
      
      // Obtém informações da imagem
      final fileStats = await processedFile.stat();
      
      // Cria o modelo EventPhoto
      final photo = models.EventPhoto(
        id: photoId,
        eventId: eventId,
        localPath: processedFile.path,
        fileSize: fileStats.size,
        mimeType: _getMimeType(processedFile.path),
        // Dimensões serão obtidas durante o processamento se necessário
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      // Salvar no banco local (Drift)
      await _database.into(_database.eventPhotos).insert(
        EventPhotosCompanion.insert(
          id: photo.id,
          eventId: photo.eventId,
          localPath: photo.localPath,
          uploadStatus: Value(photo.uploadStatus.index),
          createdAt: Value(photo.createdAt),
        ),
      );
      
      // Agenda upload em background
      _scheduleUpload(photo);
      
      return photo;
    } catch (e) {
      debugPrint('Erro ao adicionar foto: $e');
      rethrow;
    }
  }

  /// Obtém todas as fotos de um evento
  Future<List<models.EventPhoto>> getEventPhotos(String eventId) async {
    try {
      // 1. Buscar do cache local primeiro
      final localQuery = _database.select(_database.eventPhotos)
        ..where((tbl) => tbl.eventId.equals(eventId))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
      
      final localPhotos = await localQuery.get();
      
      // 2. Converter dados do Drift para modelo
      final photos = localPhotos.map((data) => models.EventPhoto(
        id: data.id,
        eventId: data.eventId,
        localPath: data.localPath,
        downloadUrl: data.downloadUrl,
        storagePath: data.storagePath,
        uploadStatus: models.EventPhotoUploadStatus.values[data.uploadStatus],
        uploadProgress: data.uploadProgress.toInt(),
        fileSize: data.fileSize,
        mimeType: data.mimeType,
        width: data.width,
        height: data.height,
        retryCount: data.retryCount,
        lastRetryAt: data.lastRetryAt,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        metadata: data.metadata != null ? jsonDecode(data.metadata!) : null,
      )).toList();
      
      // 3. TODO: Sincronizar com Firestore em background se necessário
      
      return photos;
    } catch (e) {
      debugPrint('Erro ao buscar fotos: $e');
      return [];
    }
  }

  /// Obtém todas as fotos pendentes de upload
  Future<List<models.EventPhoto>> getPendingPhotos() async {
    try {
      // Buscar fotos com status pending ou failed
      final pendingQuery = _database.select(_database.eventPhotos)
        ..where((tbl) => tbl.uploadStatus.isIn([
          models.EventPhotoUploadStatus.pending.index,
          models.EventPhotoUploadStatus.failed.index,
        ]))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
      
      final pendingPhotos = await pendingQuery.get();
      
      // Converter dados do Drift para modelo
      final photos = pendingPhotos.map((data) => models.EventPhoto(
        id: data.id,
        eventId: data.eventId,
        localPath: data.localPath,
        downloadUrl: data.downloadUrl,
        storagePath: data.storagePath,
        uploadStatus: models.EventPhotoUploadStatus.values[data.uploadStatus],
        uploadProgress: data.uploadProgress.toInt(),
        fileSize: data.fileSize,
        mimeType: data.mimeType,
        width: data.width,
        height: data.height,
        retryCount: data.retryCount,
        lastRetryAt: data.lastRetryAt,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        metadata: data.metadata != null ? jsonDecode(data.metadata!) : null,
      )).toList();
      
      return photos;
    } catch (e) {
      debugPrint('Erro ao buscar fotos pendentes: $e');
      return [];
    }
  }

  /// Obtém todas as fotos do banco local
  Future<List<models.EventPhoto>> getAllPhotos() async {
    try {
      final query = _database.select(_database.eventPhotos);
      final results = await query.get();
      
      // Converter para modelo de domínio
      return results.map((row) => models.EventPhoto(
        id: row.id,
        eventId: row.eventId,
        localPath: row.localPath,
        downloadUrl: row.downloadUrl,
        storagePath: row.storagePath,
        uploadStatus: models.EventPhotoUploadStatus.values[row.uploadStatus],
        uploadProgress: row.uploadProgress.toInt(),
        fileSize: row.fileSize,
        mimeType: row.mimeType,
        width: row.width,
        height: row.height,
        retryCount: row.retryCount,
        lastRetryAt: row.lastRetryAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        metadata: row.metadata != null ? jsonDecode(row.metadata!) : null,
      )).toList();
    } catch (e) {
      debugPrint('Erro ao buscar todas as fotos: $e');
      return [];
    }
  }

  /// Remove uma foto do evento
  Future<void> removePhoto(String photoId) async {
    try {
      // 1. Buscar dados da foto no cache local
      final photoQuery = _database.select(_database.eventPhotos)
        ..where((tbl) => tbl.id.equals(photoId));
      
      final photoData = await photoQuery.getSingleOrNull();
      
      if (photoData == null) {
        debugPrint('Foto não encontrada: $photoId');
        return;
      }
      
      // 2. Remover arquivo local se existir
      final localFile = File(photoData.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
      
      // 3. Remover do cache local
      await (_database.delete(_database.eventPhotos)
        ..where((tbl) => tbl.id.equals(photoId))).go();
      
      // 4. Remover do Firebase Storage se foi feito upload
      if (photoData.storagePath != null) {
        try {
          await _storage.ref(photoData.storagePath!).delete();
        } catch (e) {
          debugPrint('Erro ao remover do Storage: $e');
        }
      }
      
      // 5. Remover do Firestore se foi sincronizado
      if (photoData.downloadUrl != null) {
        try {
          await _firestore
              .collection('events')
              .doc(photoData.eventId)
              .collection('photos')
              .doc(photoId)
              .delete();
        } catch (e) {
          debugPrint('Erro ao remover do Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Erro ao remover foto: $e');
      rethrow;
    }
  }

  /// Faz upload de uma foto para o Firebase Storage
  Future<models.EventPhoto> uploadPhoto(models.EventPhoto photo) async {
    try {
      if (!photo.fileExists) {
        throw Exception('Arquivo local não encontrado: ${photo.localPath}');
      }

      final file = File(photo.localPath);
      final fileName = '${photo.id}.${_getFileExtension(photo.localPath)}';
      final storagePath = 'events/${photo.eventId}/photos/$fileName';
      
      // Referência do Storage
      final storageRef = _storage.ref(storagePath);
      
      // Inicia upload com callback de progresso
      final uploadTask = storageRef.putFile(file);
      
      // Monitora progresso
      uploadTask.snapshotEvents.listen((snapshot) {
        // TODO: Atualizar progresso no banco local
        // final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).round();
        // _localDb.updatePhotoProgress(photo.id, progress);
      });
      
      // Aguarda conclusão
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Atualiza modelo com dados do upload
      final updatedPhoto = photo.markAsCompleted(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
      );
      
      // Salva no Firestore
      await _firestore
          .collection('events')
          .doc(photo.eventId)
          .collection('photos')
          .doc(photo.id)
          .set(updatedPhoto.toJson());
      
      // TODO: Atualiza banco local
      // await _localDb.updateEventPhoto(updatedPhoto);
      
      return updatedPhoto;
    } catch (e) {
      debugPrint('Erro no upload da foto: $e');
      
      // Marca como falha
      photo.markAsFailed();
      
      // TODO: Atualiza banco local
      // await _localDb.updateEventPhoto(photo);
      
      rethrow;
    }
  }

  /// Agenda upload em background (será chamado pelo UploadManager)
  void _scheduleUpload(models.EventPhoto photo) {
    // TODO: Integrar com UploadManager
    // UploadManager.instance.schedulePhotoUpload(photo);
  }

  /// Processa uma imagem antes do upload
  /// Redimensiona, comprime e otimiza para web
  Future<File> _processImage(File originalFile) async {
    try {
      // Comprime a imagem usando flutter_image_compress
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        '${originalFile.parent.path}/compressed_${_uuid.v4()}.jpg',
        quality: 85,
        minWidth: 800,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      
      if (compressedFile == null) {
        throw Exception('Não foi possível comprimir a imagem');
      }
      
      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Erro ao processar imagem: $e');
      // Em caso de erro, retorna o arquivo original
      return originalFile;
    }
  }

  /// Obtém tipo MIME baseado na extensão do arquivo
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Obtém extensão do arquivo
  String _getFileExtension(String filePath) {
    return path.extension(filePath).replaceFirst('.', '');
  }

  /// Sincroniza fotos pendentes com o servidor
  Future<void> syncPendingPhotos() async {
    try {
      // TODO: Buscar fotos pendentes do banco local
      // final pendingPhotos = await _localDb.getPendingPhotos();
      
      // for (final photo in pendingPhotos) {
      //   if (photo.needsUpload && photo.fileExists) {
      //     await uploadPhoto(photo);
      //   }
      // }
    } catch (e) {
      debugPrint('Erro ao sincronizar fotos pendentes: $e');
    }
  }

  /// Atualiza o status de upload de uma foto
  Future<void> updatePhotoStatus(
    String photoId,
    models.EventPhotoUploadStatus status, {
    int? progress,
    String? downloadUrl,
    String? storagePath,
  }) async {
    try {
      // Preparar dados para atualização
      final updateData = <String, dynamic>{
        'uploadStatus': status.index,
        'updatedAt': DateTime.now(),
      };
      
      if (progress != null) updateData['uploadProgress'] = progress;
      if (downloadUrl != null) updateData['downloadUrl'] = downloadUrl;
      if (storagePath != null) updateData['storagePath'] = storagePath;
      
      // Atualizar no cache local
      final updateQuery = _database.update(_database.eventPhotos)
        ..where((tbl) => tbl.id.equals(photoId));
      
      await updateQuery.write(EventPhotosCompanion(
         uploadStatus: Value(status.index),
         uploadProgress: progress != null ? Value(progress.toDouble()) : const Value.absent(),
         downloadUrl: downloadUrl != null ? Value(downloadUrl) : const Value.absent(),
         storagePath: storagePath != null ? Value(storagePath) : const Value.absent(),
         updatedAt: Value(DateTime.now()),
       ));
    } catch (e) {
      debugPrint('Erro ao atualizar status de upload: $e');
      rethrow;
    }
  }

  /// Limpa cache de fotos antigas
  Future<void> cleanupOldPhotos({int maxAgeInDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      
      // 1. Buscar fotos antigas
      final oldPhotosQuery = _database.select(_database.eventPhotos)
        ..where((tbl) => tbl.createdAt.isSmallerThanValue(cutoffDate));
      
      final oldPhotos = await oldPhotosQuery.get();
      
      // 2. Remover arquivos locais
      for (final photo in oldPhotos) {
        try {
          final localFile = File(photo.localPath);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (e) {
          debugPrint('Erro ao remover arquivo local: ${photo.localPath} - $e');
        }
      }
      
      // 3. Remover registros do banco
      await (_database.delete(_database.eventPhotos)
        ..where((tbl) => tbl.createdAt.isSmallerThanValue(cutoffDate))).go();
      
      debugPrint('Limpeza concluída: ${oldPhotos.length} fotos antigas removidas');
    } catch (e) {
      debugPrint('Erro ao limpar cache de fotos: $e');
    }
  }
}