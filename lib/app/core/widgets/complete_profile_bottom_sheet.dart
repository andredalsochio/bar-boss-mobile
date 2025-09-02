import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Bottom sheet para lembrar de completar o perfil após criar evento
class CompleteProfileBottomSheet extends StatelessWidget {
  final int completedSteps;
  final int totalSteps;

  const CompleteProfileBottomSheet({
    super.key,
    required this.completedSteps,
    required this.totalSteps,
  });

  /// Mostra o bottom sheet
  static void show(
    BuildContext context, {
    required int completedSteps,
    required int totalSteps,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompleteProfileBottomSheet(
        completedSteps: completedSteps,
        totalSteps: totalSteps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.all(AppSizes.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual do bottom sheet
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: AppSizes.spacingLarge),
          
          // Ícone
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.primary(context),
            ),
          ),
          
          const SizedBox(height: AppSizes.spacingLarge),
          
          // Título
          Text(
            'Evento criado com sucesso!',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSizes.spacingMedium),
          
          // Subtítulo
          Text(
            'Complete seu perfil ($completedSteps/$totalSteps) para aproveitar todos os recursos do app',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSizes.spacingLarge),
          
          // Barra de progresso
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.border(context),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completedSteps / totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.primary(context),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.spacingLarge),
          
          // Botões
          Row(
            children: [
              // Botão "Depois"
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary(context),
                    side: BorderSide(color: AppColors.border(context)),
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.spacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Depois',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppSizes.spacingMedium),
              
              // Botão "Completar agora"
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pushNamed('barProfile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.spacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Completar agora',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Espaçamento para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}