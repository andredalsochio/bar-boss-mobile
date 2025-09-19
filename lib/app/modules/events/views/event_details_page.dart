import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/image_viewer_page.dart';
import 'package:bar_boss_mobile/app/core/widgets/promotion_image_widget.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Tela de detalhes do evento (somente visualização)
class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late EventsViewModel _viewModel;
  bool _isLoading = true;
  EventModel? _event;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<EventsViewModel>(context, listen: false);
    
    // Carrega os detalhes após o build inicial para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventDetails();
    });
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _viewModel.loadEventById(widget.eventId);
      _event = _viewModel.currentEvent;
    } catch (e) {
      debugPrint('Erro ao carregar detalhes do evento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar detalhes do evento'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        backgroundColor: AppColors.primary(context),
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // Botão para editar o evento
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.pushReplacementNamed(
                'eventEdit',
                pathParameters: {'id': widget.eventId},
              );
            },
            tooltip: 'Editar evento',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            tooltip: AppStrings.deleteEventTooltip,
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _event == null
              ? _buildErrorState()
              : _buildEventDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconSizeLarge,
            color: AppColors.textSecondary(context),
          ),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'Evento não encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: AppSizes.spacing32),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        children: [
          // Card 1 - Data do Evento
          _buildDateCard(),
          const SizedBox(height: AppSizes.spacing16),
          
          // Card 2 - Atrações
          _buildAttractionsCard(),
          const SizedBox(height: AppSizes.spacing16),
          
          // Card 3 - Imagens de Promoção
          if (_event!.promoImages?.isNotEmpty == true)
            _buildPromotionImagesCard(),
          if (_event!.promoImages?.isNotEmpty == true)
            const SizedBox(height: AppSizes.spacing16),
          
          // Card 4 - Detalhes da Promoção
          if (_event!.description?.isNotEmpty == true)
            _buildPromotionDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');
    final formattedDate = dateFormat.format(_event!.startAt);
  
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary(context),
                  size: AppSizes.iconSize24,
                ),
                const SizedBox(width: AppSizes.spacing8),
                const Text(
                  'Dia do evento',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: AppColors.primary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
                border: Border.all(
                  color: AppColors.primary(context).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppSizes.fontSize16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttractionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: AppColors.primary(context),
                  size: AppSizes.iconSize24,
                ),
                const SizedBox(width: AppSizes.spacing8),
                const Text(
                  'Atrações',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            if (_event!.attractions?.isEmpty == true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
                ),
                child: Text(
                  'Nenhuma atração cadastrada',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize14,
                    color: AppColors.textSecondary(context),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                children: _event!.attractions!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attraction = entry.value;
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      bottom: index < _event!.attractions!.length - 1
                          ? AppSizes.spacing8
                          : 0,
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
                      border: Border.all(
                        color: AppColors.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary(context),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: AppSizes.fontSize12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        Expanded(
                          child: Text(
                            attraction,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSize14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionImagesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: AppColors.primary(context),
                  size: AppSizes.iconSize24,
                ),
                const SizedBox(width: AppSizes.spacing8),
                const Text(
                  'Imagens de promoção',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _event!.promoImages!.length,
                itemBuilder: (context, index) {
                  final imageUrl = _event!.promoImages![index];
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(
                      right: index < _event!.promoImages!.length - 1
                          ? AppSizes.spacing8
                          : 0,
                    ),
                    child: PromotionImageWidget(
                      imageUrl: imageUrl,
                      eventId: _event!.id,
                      index: index,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImageViewerPage(
                              imageUrls: _event!.promoImages!,
                              initialIndex: index,
                              heroTag: 'promo_image',
                            ),
                          ),
                        );
                      },
                      // Na página de detalhes, não permitimos remoção
                      onRemove: null,
                      onRetry: null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppColors.primary(context),
                  size: AppSizes.iconSize24,
                ),
                const SizedBox(width: AppSizes.spacing8),
                const Text(
                  'Detalhes da promoção',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Text(
                _event!.description!,
                style: const TextStyle(
                  fontSize: AppSizes.fontSize14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.'),
          actions: [
            Consumer<EventsViewModel>(
              builder: (context, viewModel, child) {
                return ButtonWidget(
                  text: 'Excluir',
                  onPressed: viewModel.isLoading
                       ? null
                       : () async {
                           // Armazena referências do contexto antes das operações assíncronas
                           final navigator = Navigator.of(context);
                           final router = GoRouter.of(context);
                           
                           try {
                             // Carrega o evento antes de excluir
                             await viewModel.loadEvent(widget.eventId);
                             await viewModel.deleteEvent();
                              if (mounted) {
                                navigator.pop(); // Fecha o dialog
                                router.pop(); // Volta para a tela anterior
                              }
                            } catch (e) {
                              if (mounted) {
                                navigator.pop(); // Fecha o dialog
                                ToastService.instance.showError(
                                  message: AppStrings.deleteEventErrorMessage,
                                );
                              }
                            }
                         },
                  backgroundColor: AppColors.error,
                  isLoading: viewModel.isLoading,
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing8),
             Align(
               alignment: Alignment.center,
               child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
                           ),
             ),
          ],
        );
      },
    );
  }
}        Navigator.of(context).pop(); // Fecha o dialog
                                ToastService.instance.showError(
                                  message: AppStrings.deleteEventErrorMessage,
                                );
                              }
                            }
                         },
                  backgroundColor: AppColors.error,
                  isLoading: viewModel.isLoading,
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing8),
             Align(
               alignment: Alignment.center,
               child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
                           ),
             ),
          ],
        );
      },
    );
  }
}