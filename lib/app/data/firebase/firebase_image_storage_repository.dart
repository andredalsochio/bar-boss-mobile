import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Implementação concreta do ImageStorageRepository usando Firebase Storage
class FirebaseImageStorageRepository {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  FirebaseImageStorageRepository({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<String?> uploadImage(
    File imageFile, 
    String path, {
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('Iniciando upload de imagem: $path');
      
      // Verifica autenticação
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verifica se o arquivo existe
      if (!await imageFile.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }

      // Verifica tamanho do arquivo (máximo 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo permitido: 10MB');
      }

      // Cria referência no Firebase Storage
      final ref = _storage.ref().child(path);
      
      // Prepara metadados
      final settableMetadata = SettableMetadata(
        contentType: _getContentType(imageFile.path),
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      // Faz upload
      final uploadTask = ref.putFile(imageFile, settableMetadata);
      final snapshot = await uploadTask;
      
      // Obtém URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Upload concluído com sucesso: $downloadUrl');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      debugPrint('Erro do Firebase no upload: ${e.message}');
      throw Exception('Erro no upload: ${e.message}');
    } catch (e) {
      debugPrint('Erro inesperado no upload: $e');
      throw Exception('Erro inesperado no upload');
    }
  }

  Future<String?> uploadImageBytes(
    Uint8List imageBytes, 
    String path, {
    Map<String, String>? metadata,
  }) async {
    try {
      debugPrint('Iniciando upload de imagem por bytes: $path');
      
      // Verifica autenticação
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verifica tamanho
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo permitido: 10MB');
      }

      // Cria referência
      final ref = _storage.ref().child(path);
      
      // Prepara metadados
      final settableMetadata = SettableMetadata(
        contentType: _getContentTypeFromPath(path),
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'migratedImage': 'true', // Marca como imagem migrada
          ...?metadata,
        },
      );

      // Faz upload
      final uploadTask = ref.putData(imageBytes, settableMetadata);
      final snapshot = await uploadTask;
      
      // Obtém URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Upload por bytes concluído: $downloadUrl');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      debugPrint('Erro do Firebase no upload por bytes: ${e.message}');
      throw Exception('Erro no upload: ${e.message}');
    } catch (e) {
      debugPrint('Erro inesperado no upload por bytes: $e');
      throw Exception('Erro inesperado no upload');
    }
  }

  Future<List<String>> uploadImages(
    List<File> imageFiles, 
    String basePath, {
    Map<String, String>? metadata,
  }) async {
    final results = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = 'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = '$basePath/$fileName';
      
      try {
        final url = await uploadImage(file, fullPath, metadata: metadata);
        if (url != null) {
          results.add(url);
        }
      } catch (e) {
        debugPrint('Erro no upload da imagem $i: $e');
        // Continua com as outras imagens
      }
    }
    
    return results;
  }

  Future<bool> deleteImage(String path) async {
    try {
      debugPrint('Deletando imagem: $path');
      
      // Extrai o caminho da URL
      final ref = _storage.refFromURL(path);
      await ref.delete();
      
      debugPrint('Imagem deletada com sucesso');
      return true;
      
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('Imagem não encontrada para deletar: $path');
        return true; // Considera sucesso se já não existe
      }
      
      debugPrint('Erro do Firebase ao deletar: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Erro inesperado ao deletar: $e');
      return false;
    }
  }

  Future<List<String>> deleteImages(List<String> imageUrls) async {
    final deletedUrls = <String>[];
    
    for (final url in imageUrls) {
      try {
        final success = await deleteImage(url);
        if (success) {
          deletedUrls.add(url);
        }
      } catch (e) {
        debugPrint('Erro ao deletar imagem $url: $e');
      }
    }
    
    return deletedUrls;
  }

  Future<String?> getImageUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL da imagem: $e');
      return null;
    }
  }

  Future<String?> migrateImage(String sourceUrl, String destinationPath) async {
    try {
      debugPrint('Migrando imagem de $sourceUrl para $destinationPath');
      
      // Baixa a imagem da URL original
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar imagem original: ${response.statusCode}');
      }
      
      // Faz upload dos bytes para o novo local
      final newUrl = await uploadImageBytes(
        response.bodyBytes,
        destinationPath,
        metadata: {
          'originalUrl': sourceUrl,
          'migrationDate': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('Migração concluída: $newUrl');
      return newUrl;
      
    } catch (e) {
      debugPrint('Erro na migração de imagem: $e');
      return null;
    }
  }

  Future<bool> imageExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getImageMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'bucket': metadata.bucket,
        'fullPath': metadata.fullPath,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('Erro ao obter metadados: $e');
      return null;
    }
  }

  Future<String?> getTemporaryUrl(
    String path, 
    Duration expirationDuration,
  ) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
      // Nota: Firebase Storage URLs não expiram por padrão
      // Para URLs temporárias, seria necessário usar Firebase Functions
    } catch (e) {
      debugPrint('Erro ao gerar URL temporária: $e');
      return null;
    }
  }

  Future<List<String>> listImages(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();
      
      final urls = <String>[];
      for (final item in result.items) {
        try {
          final url = await item.getDownloadURL();
          urls.add(url);
        } catch (e) {
          debugPrint('Erro ao obter URL do item ${item.fullPath}: $e');
        }
      }
      
      return urls;
    } catch (e) {
      debugPrint('Erro ao listar imagens: $e');
      return [];
    }
  }

  Future<String?> copyImage(String sourcePath, String destinationPath) async {
    try {
      // Firebase Storage não tem operação de cópia nativa
      // Precisamos baixar e fazer upload novamente
      final sourceRef = _storage.ref().child(sourcePath);
      final data = await sourceRef.getData();
      
      if (data == null) {
        throw Exception('Dados da imagem de origem não encontrados');
      }
      
      return await uploadImageBytes(data, destinationPath);
    } catch (e) {
      debugPrint('Erro ao copiar imagem: $e');
      return null;
    }
  }

  // Métodos auxiliares privados
  
  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  
  String _getContentTypeFromPath(String path) {
    final extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  

}