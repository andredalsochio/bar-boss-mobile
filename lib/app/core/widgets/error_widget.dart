import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';

/// Widget para exibição de erros no aplicativo
class ErrorDisplayWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool isFullScreen;
  final IconData icon;
  
  const ErrorDisplayWidget({
    Key? key,
    this.message,
    this.onRetry,
    this.isFullScreen = false,
    this.icon = Icons.error_outline,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final errorContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppSizes.iconSize48,
          color: AppColors.error,
        ),
        const SizedBox(height: AppSizes.spacing16),
        Text(
          message ?? AppStrings.genericErrorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppSizes.fontSize16,
            color: AppColors.textPrimary,
          ),
        ),
        if (onRetry != null) ...[  
          const SizedBox(height: AppSizes.spacing24),
          ButtonWidget(
            text: AppStrings.retryButton,
            onPressed: onRetry,
            isFullWidth: false,
            icon: Icons.refresh,
          ),
        ],
      ],
    );
    
    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: errorContent),
      );
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        margin: const EdgeInsets.all(AppSizes.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: errorContent,
      ),
    );
  }
}

/// Widget para exibição de estado vazio (sem dados)
class EmptyStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData icon;
  
  const EmptyStateWidget({
    Key? key,
    this.message,
    this.onAction,
    this.actionLabel,
    this.icon = Icons.inbox_outlined,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconSize48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              message ?? AppStrings.noDataMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSize16,
                color: AppColors.textSecondary,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[  
              const SizedBox(height: AppSizes.spacing24),
              ButtonWidget(
                text: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}