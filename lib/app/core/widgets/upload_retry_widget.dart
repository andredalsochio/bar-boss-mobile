import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../services/upload_queue_service.dart';

/// Widget que exibe um banner para tentar novamente uploads falhados
class UploadRetryWidget extends StatelessWidget {
  final VoidCallback? onRetryAll;
  final String? eventId;
  
  const UploadRetryWidget({
    super.key,
    this.onRetryAll,
    this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadQueueService>(
      builder: (context, uploadService, child) {
        final failedItems = eventId != null 
            ? uploadService.getItemsByEvent(eventId!).where((item) => item.status == UploadStatus.failed).toList()
            : uploadService.failedItems;
            
        if (failedItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Falha no upload',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${failedItems.length} ${failedItems.length == 1 ? 'imagem falhou' : 'imagens falharam'} no upload',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              TextButton.icon(
                onPressed: onRetryAll,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  backgroundColor: Colors.red.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingSmall,
                    vertical: AppSizes.spacing4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget compacto para mostrar status de upload em listas
class UploadStatusIndicator extends StatelessWidget {
  final String eventId;
  final VoidCallback? onRetryAll;
  
  const UploadStatusIndicator({
    super.key,
    required this.eventId,
    this.onRetryAll,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadQueueService>(
      builder: (context, uploadService, child) {
        final items = uploadService.getItemsByEvent(eventId);
        final failedItems = items.where((item) => item.status == UploadStatus.failed).toList();
        final uploadingItems = items.where((item) => item.status == UploadStatus.uploading).toList();
        
        if (failedItems.isEmpty && uploadingItems.isEmpty) {
          return const SizedBox.shrink();
        }

        if (uploadingItems.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingSmall,
              vertical: AppSizes.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing4),
                Text(
                  'Enviando ${uploadingItems.length}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (failedItems.isNotEmpty) {
          return GestureDetector(
            onTap: onRetryAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingSmall,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 12,
                  ),
                  const SizedBox(width: AppSizes.spacing4),
                  Text(
                    '${failedItems.length} falharam',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing4),
                  Icon(
                    Icons.refresh,
                    color: Colors.red.shade600,
                    size: 12,
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}