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
                Navigator.of(context).pop();
                final file = await pickImageFromCamera();
                if (context.mounted && file != null) {
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
                Navigator.of(context).pop();
                final file = await pickImageFromGallery();
                if (context.mounted && file != null) {
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
  static Future<File?> pickImageFromCamera() async {
    try {
      // Verifica permissão da câmera
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        debugPrint('Permissão da câmera negada: ${cameraPermission.toString()}');
        if (cameraPermission.isPermanentlyDenied) {
          debugPrint('Permissão da câmera permanentemente negada - usuário deve ir às configurações');
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
      // Verifica permissão da galeria (iOS 14+ usa photosAddOnly para seleção)
      Permission galleryPermission;
      if (Platform.isIOS) {
        galleryPermission = Permission.photos;
      } else {
        galleryPermission = Permission.storage;
      }
      
      final permissionStatus = await galleryPermission.request();
       if (!permissionStatus.isGranted) {
         debugPrint('Permissão da galeria negada: ${permissionStatus.toString()}');
         if (permissionStatus.isPermanentlyDenied) {
           debugPrint('Permissão da galeria permanentemente negada - usuário deve ir às configurações');
         }
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
  static Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    
    Permission galleryPermission;
    if (Platform.isIOS) {
      galleryPermission = Permission.photos;
    } else {
      galleryPermission = Permission.storage;
    }
    
    final photosStatus = await galleryPermission.status;
    
    return cameraStatus.isGranted && photosStatus.isGranted;
  }

  /// Solicita todas as permissões necessárias
  static Future<bool> requestPermissions() async {
    List<Permission> permissionsToRequest = [Permission.camera];
    
    if (Platform.isIOS) {
      permissionsToRequest.add(Permission.photos);
    } else {
      permissionsToRequest.add(Permission.storage);
    }
    
    final Map<Permission, PermissionStatus> permissions = await permissionsToRequest.request();

    return permissions.values.every((status) => status.isGranted);
  }

  /// Mostra dialog explicando por que as permissões são necessárias
  static Future<void> showPermissionDialog(BuildContext context) async {
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