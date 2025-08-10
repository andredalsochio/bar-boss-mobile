import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget para exibir mensagens de erro
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final bool showIcon;
  final VoidCallback? onRetry;
  
  const ErrorMessageWidget({
    Key? key,
    required this.message,
    this.showIcon = true,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
        border: Border.all(
          color: AppColors.error,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) ...[  
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: AppSizes.iconSize16,
            ),
            const SizedBox(width: AppSizes.spacing8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSize12,
                    color: AppColors.error,
                  ),
                ),
                if (onRetry != null) ...[  
                  const SizedBox(height: AppSizes.spacing8),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      'Tentar novamente',
                      style: TextStyle(
                        fontSize: AppSizes.fontSize12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para exibir mensagem de erro em campos de formulário
class FormFieldErrorWidget extends StatelessWidget {
  final String? errorText;
  
  const FormFieldErrorWidget({
    Key? key,
    required this.errorText,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (errorText == null || errorText!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spacing4, left: AppSizes.spacing4),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconSize12,
          ),
          const SizedBox(width: AppSizes.spacing4),
          Expanded(
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: AppSizes.fontSize10,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}