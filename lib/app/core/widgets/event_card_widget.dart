import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Widget de card de evento
class EventCardWidget extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;

  final VoidCallback? onTap;
  final bool showActions;
  
  const EventCardWidget({
    super.key,
    required this.event,
    this.onViewDetails,
    this.onEdit,

    this.onTap,
    this.showActions = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(event.startAt);
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: AppSizes.elevation2,
        margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com data
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary(context) : AppColors.textPrimary(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.borderRadius4),
                topRight: Radius.circular(AppSizes.borderRadius4),
              ),
            ),
            child: Text(
              isToday
                  ? 'Hoje - ${_formatDateWithWeekday(event.startAt)}'
                  : _formatDateWithWeekday(event.startAt),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontSize14,
              ),
            ),
          ),
          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Atrações
                if (event.attractions?.isNotEmpty == true) ..._buildAttractions(context),
                
                // Indicadores
                Row(
                  children: [
                    if (event.description?.isNotEmpty == true)
                      _buildIndicator(
                        Icons.local_offer,
                        AppStrings.promotionsAvailable,
                        AppColors.success,
                      ),


                  ],
                ),
                
                if (showActions) ...[  
                  const SizedBox(height: AppSizes.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        AppStrings.viewDetailsButton,
                        Icons.visibility,
                        onViewDetails,
                      ),
                      _buildActionButton(
                        context,
                        AppStrings.editEventButton,
                        Icons.edit,
                        onEdit,
                      ),

                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary(context),
            size: AppSizes.iconSize24,
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontSize10,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicator(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: AppSizes.iconSize16,
        ),
        const SizedBox(width: AppSizes.spacing4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSize12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildAttractions(BuildContext context) {
    return [
      ...event.attractions?.map((attraction) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
        child: Text(
          attraction,
          style: TextStyle(
            fontSize: AppSizes.fontSize16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )) ?? [],
      const SizedBox(height: AppSizes.spacing8),
    ];
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  String _formatDateWithWeekday(DateTime date) {
    final weekdays = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday ${date.day.toString().padLeft(2, '0')}';
  }
}