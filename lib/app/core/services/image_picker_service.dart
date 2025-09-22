import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço para seleção de imagens da câmera ou galeria
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Mostra um dialog para o usuário escolher entre câmera ou galeria
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar foto'),
          content: const Text('Escolha a origem da imagem:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final file = await pickImageFromCamera(context);
                if (context.mounted) {
                  Navigator.of(context).pop(file);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Câmera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final file = await pickImageFromGallery();
                if (context.mounted) {
                  Navigator.of(context).pop(file);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Galeria'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Seleciona imagem da câmera
  static Future<File?> pickImageFromCamera(BuildContext context) async {
    try {
      // No iOS, deixamos o image_picker gerenciar as permissões da câmera
      // Só mostramos dialog de configurações se for permanentemente negado
      if (Platform.isIOS) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          return File(image.path);
        }
        return null;
      }

      // Para Android, mantemos a verificação de permissão
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        debugPrint('Permissão da câmera negada: ${cameraPermission.toString()}');
        if (cameraPermission.isPermanentlyDenied && context.mounted) {
          await _showPermissionDialog(context, 'câmera');
        }
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao selecionar imagem da câmera: $e');
      return null;
    }
  }

  /// Seleciona imagem da galeria
  static Future<File?> pickImageFromGallery() async {
    try {
      // No iOS 14+, o PHPicker não requer permissão prévia
      // Deixamos o image_picker gerenciar tudo
      if (Platform.isIOS) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          return File(image.path);
        }
        return null;
      }

      // Para Android, verificamos permissão de storage
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted && !storagePermission.isLimited) {
        debugPrint('Permissão da galeria negada: ${storagePermission.toString()}');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao selecionar imagem da galeria: $e');
      return null;
    }
  }

  /// Verifica se as permissões necessárias estão concedidas
  /// No iOS, sempre retorna true pois o PHPicker não requer permissão prévia
  static Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      // No iOS 14+, o PHPicker não requer permissão prévia para galeria
      // e a câmera é gerenciada pelo próprio image_picker
      return true;
    }

    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    
    return cameraStatus.isGranted && 
           (storageStatus.isGranted || storageStatus.isLimited);
  }

  /// Solicita todas as permissões necessárias
  /// No iOS, sempre retorna true pois o PHPicker gerencia as permissões
  static Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      // No iOS, deixamos o image_picker gerenciar as permissões
      return true;
    }

    final Map<Permission, PermissionStatus> permissions = 
        await [Permission.camera, Permission.storage].request();

    return permissions.values.every((status) => 
        status.isGranted || status.isLimited);
  }

  /// Mostra dialog específico para permissão permanentemente negada
  static Future<void> _showPermissionDialog(BuildContext context, String permissionType) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão necessária'),
          content: Text(
            'Para usar a $permissionType, você precisa permitir o acesso nas configurações do dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Abrir configurações'),
            ),
          ],
        );
      },
    );
  }

  /// Mostra dialog explicando por que as permissões são necessárias
  /// Mantido para compatibilidade, mas no iOS não é mais necessário
  static Future<void> showPermissionDialog(BuildContext context) async {
    if (Platform.isIOS) {
      // No iOS, não precisamos mais deste dialog pois o PHPicker gerencia tudo
      return;
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissões necessárias'),
          content: const Text(
            'Para alterar a foto do perfil, precisamos de acesso à câmera e galeria do seu dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Abrir configurações'),
            ),
          ],
        );
      },
    );
  }
}