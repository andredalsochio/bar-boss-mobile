import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../services/upload_queue_service.dart';

/// Widget para exibir uma imagem de promoção com suporte a placeholders durante upload
class PromotionImageWidget extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? eventId;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final bool showRemoveButton;
  final double width;
  final double height;

  const PromotionImageWidget({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.eventId,
    required this.index,
    this.onRemove,
    this.onRetry,
    this.showRemoveButton = true,
    this.width = 100,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadQueueService>(
      builder: (context, uploadService, child) {
        // Verifica se há um item na fila de upload para esta imagem
        UploadQueueItem? uploadItem;
        if (eventId != null) {
          final items = uploadService.getItemsByEvent(eventId!);
          // Procura por item que corresponde ao índice ou arquivo
          uploadItem = items.where((item) {
            if (imageFile != null) {
              return item.file.path == imageFile!.path;
            }
            return false;
          }).firstOrNull;
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
              child: _buildImageContent(context, uploadItem),
            ),
            if (showRemoveButton) _buildRemoveButton(context, uploadItem),
            if (uploadItem?.status == UploadStatus.failed) _buildRetryButton(context),
            if (uploadItem?.status == UploadStatus.uploading) _buildUploadingIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildImageContent(BuildContext context, UploadQueueItem? uploadItem) {
    // Se está fazendo upload ou pendente, mostra placeholder
    if (uploadItem != null && 
        (uploadItem.status == UploadStatus.pending || uploadItem.status == UploadStatus.uploading)) {
      return _buildPlaceholder(context);
    }

    // Se falhou, mostra placeholder com indicação de erro
    if (uploadItem?.status == UploadStatus.failed) {
      return _buildErrorPlaceholder(context);
    }

    // Se tem URL (upload concluído ou imagem existente), mostra a imagem
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder(context);
        },
      );
    }

    // Se tem arquivo local, mostra o arquivo
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    // Fallback para placeholder
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'Enviando...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.red[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'Erro',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, UploadQueueItem? uploadItem) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: () {
          // Se está fazendo upload, cancela o upload
          if (uploadItem != null) {
            context.read<UploadQueueService>().removeItem(uploadItem.id);
          }
          // Chama callback de remoção
          onRemove?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Positioned(
      bottom: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary(context),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}