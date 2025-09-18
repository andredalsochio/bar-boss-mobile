import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Serviço responsável pelo processamento e otimização de imagens
/// Resolve problemas de color space (Display P3 vs sRGB) no iOS
/// e converte formatos HEIC/HEIF para JPEG com perfil sRGB
class ImageProcessingService {
  static const int _defaultQuality = 85;
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  /// Processa uma imagem selecionada pelo usuário
  /// Converte HEIC → JPEG, aplica compressão e corrige color space
  static Future<File?> processSelectedImage(File originalFile) async {
    try {
      debugPrint('🖼️ Iniciando processamento da imagem: ${originalFile.path}');
      
      // Verifica se o arquivo existe
      if (!await originalFile.exists()) {
        debugPrint('❌ Arquivo não encontrado: ${originalFile.path}');
        return null;
      }

      // Obtém informações do arquivo original
      final originalSize = await originalFile.length();
      debugPrint('📊 Tamanho original: ${_formatFileSize(originalSize)}');

      // Processa a imagem
      final processedBytes = await _compressAndConvertImage(originalFile);
      if (processedBytes == null) {
        debugPrint('❌ Falha no processamento da imagem');
        return null;
      }

      // Salva o arquivo processado
      final processedFile = await _saveProcessedImage(processedBytes);
      if (processedFile == null) {
        debugPrint('❌ Falha ao salvar imagem processada');
        return null;
      }

      final processedSize = await processedFile.length();
      debugPrint('✅ Imagem processada com sucesso!');
      debugPrint('📊 Tamanho final: ${_formatFileSize(processedSize)}');
      debugPrint('📈 Redução: ${((originalSize - processedSize) / originalSize * 100).toStringAsFixed(1)}%');

      return processedFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro no processamento da imagem: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Comprime e converte a imagem para JPEG com perfil sRGB
  /// Resolve problemas de color space do iOS (Display P3 → sRGB)
  static Future<Uint8List?> _compressAndConvertImage(File file) async {
    try {
      // Primeira tentativa: compressão com conversão para JPEG
      // Isso força a conversão de HEIC → JPEG e aplica perfil sRGB
      var result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        quality: _defaultQuality,
        format: CompressFormat.jpeg, // Força conversão para JPEG
        autoCorrectionAngle: true, // Corrige orientação automaticamente
        keepExif: false, // Remove metadados EXIF para reduzir tamanho
      );

      if (result == null) {
        debugPrint('❌ Primeira tentativa de compressão falhou');
        return null;
      }

      // Verifica se o resultado ainda está muito grande
      if (result.length > _maxFileSizeBytes) {
        debugPrint('⚠️ Imagem ainda muito grande, aplicando compressão adicional');
        result = await _applyAdditionalCompression(result);
      }

      debugPrint('✅ Compressão concluída: ${_formatFileSize(result?.length ?? 0)}');
      return result;
    } on UnsupportedError catch (e) {
      // Fallback para dispositivos que não suportam o formato
      debugPrint('⚠️ Formato não suportado, tentando fallback: $e');
      return await _fallbackCompression(file);
    } catch (e) {
      debugPrint('❌ Erro na compressão: $e');
      return null;
    }
  }

  /// Aplica compressão adicional se a imagem ainda estiver muito grande
  static Future<Uint8List?> _applyAdditionalCompression(Uint8List imageBytes) async {
    try {
      // Reduz qualidade gradualmente até atingir o tamanho desejado
      for (int quality = 70; quality >= 30; quality -= 10) {
        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          minWidth: _maxWidth ~/ 1.5, // Reduz dimensões também
          minHeight: _maxHeight ~/ 1.5,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (result.length <= _maxFileSizeBytes) {
          debugPrint('✅ Compressão adicional bem-sucedida com qualidade $quality%');
          return result;
        }
      }

      debugPrint('⚠️ Não foi possível reduzir para o tamanho desejado');
      return imageBytes; // Retorna o melhor resultado obtido
    } catch (e) {
      debugPrint('❌ Erro na compressão adicional: $e');
      return imageBytes;
    }
  }

  /// Compressão de fallback para casos onde o formato principal falha
  static Future<Uint8List?> _fallbackCompression(File file) async {
    try {
      debugPrint('🔄 Executando compressão de fallback');
      
      return await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        quality: 60, // Qualidade mais baixa para garantir compatibilidade
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );
    } catch (e) {
      debugPrint('❌ Fallback também falhou: $e');
      return null;
    }
  }

  /// Salva a imagem processada em um arquivo temporário
  static Future<File?> _saveProcessedImage(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'processed_image_$timestamp.jpg';
      final filePath = path.join(tempDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      debugPrint('💾 Imagem salva em: $filePath');
      return file;
    } catch (e) {
      debugPrint('❌ Erro ao salvar imagem: $e');
      return null;
    }
  }

  /// Formata o tamanho do arquivo para exibição
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Limpa arquivos temporários antigos (mais de 1 hora)
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));

      for (final file in files) {
        if (file is File && file.path.contains('processed_image_')) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await file.delete();
            debugPrint('🗑️ Arquivo temporário removido: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erro na limpeza de arquivos temporários: $e');
    }
  }

  /// Valida se um arquivo é uma imagem válida
  static bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.heic', '.heif'];
    return validExtensions.contains(extension);
  }

  /// Obtém informações detalhadas de uma imagem
  static Future<Map<String, dynamic>?> getImageInfo(File file) async {
    try {
      if (!await file.exists()) return null;

      final size = await file.length();
      final extension = path.extension(file.path).toLowerCase();
      
      return {
        'path': file.path,
        'size': size,
        'sizeFormatted': _formatFileSize(size),
        'extension': extension,
        'isValid': isValidImageFile(file),
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter informações da imagem: $e');
      return null;
    }
  }
}