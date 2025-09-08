import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';

/// Widget de loading para operações assíncronas
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  
  const LoadingWidget({
    Key? key,
    this.message,
    this.isFullScreen = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final loadingContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
        ),
        if (message != null) ...[  
          const SizedBox(height: 16),
          Text(
            message ?? AppStrings.loadingMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ],
    );
    
    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: loadingContent),
      );
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loadingContent,
      ),
    );
  }
}

/// Widget de overlay de loading para bloquear a tela durante operações
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  
  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: LoadingWidget(message: loadingMessage),
          ),
      ],
    );
  }
}