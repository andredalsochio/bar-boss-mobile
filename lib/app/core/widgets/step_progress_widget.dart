import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget que exibe o progresso das etapas de cadastro
class StepProgressWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;

  const StepProgressWidget({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
          ],
          Row(
            children: [
              Expanded(
                child: StepProgressIndicator(
                  totalSteps: totalSteps,
                  currentStep: currentStep,
                  size: 6,
                  padding: 2,
                  selectedColor: AppColors.primary(context),
                  unselectedColor: AppColors.border(context),
                  roundedEdges: const Radius.circular(3),
                ),
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              Text(
                '$currentStep/$totalSteps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}