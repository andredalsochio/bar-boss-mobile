import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/button_widget.dart';
import '../../../core/widgets/form_input_field_widget.dart';
import '../models/event_model.dart';
import '../viewmodels/events_viewmodel.dart';

class EventFormPage extends StatefulWidget {
  final EventModel? event;
  final String? eventId;

  const EventFormPage({super.key, this.event, this.eventId});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  late EventsViewModel _viewModel;
  final TextEditingController _promoDetailsController = TextEditingController();
  final TextEditingController _attractionController = TextEditingController();
  
  // Lista de controllers para as atrações
  final List<TextEditingController> _attractionControllers = [];

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<EventsViewModel>(context, listen: false);
    
    // Adiciona listener para atualizar o contador de caracteres
    _promoDetailsController.addListener(() {
      setState(() {});
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  void _initializeForm() async {
    if (widget.event != null) {
      await _viewModel.loadEvent(widget.event!.id);
      // Atualiza o controller após carregar o evento
      _promoDetailsController.text = _viewModel.promotionDetails;
    } else if (widget.eventId != null) {
      // Carrega evento pelo ID
      await _viewModel.loadEventById(widget.eventId!);
      // Atualiza o controller após carregar o evento
      _promoDetailsController.text = _viewModel.promotionDetails;
    } else {
      _viewModel.initNewEvent();
    }
  }

  @override
  void dispose() {
    _promoDetailsController.dispose();
    _attractionController.dispose();
    
    // Dispose de todos os controllers de atrações
    for (final controller in _attractionControllers) {
      controller.dispose();
    }
    _attractionControllers.clear();
    
    super.dispose();
  }
  
  /// Sincroniza os controllers com a lista de atrações do ViewModel
  void _syncAttractionControllers() {
    final attractions = _viewModel.attractions;
    
    // Remove controllers extras
    while (_attractionControllers.length > attractions.length) {
      _attractionControllers.removeLast().dispose();
    }
    
    // Adiciona controllers faltantes
    while (_attractionControllers.length < attractions.length) {
      _attractionControllers.add(TextEditingController());
    }
    
    // Atualiza o texto dos controllers
    for (int i = 0; i < attractions.length; i++) {
      if (_attractionControllers[i].text != attractions[i]) {
        _attractionControllers[i].text = attractions[i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.event != null ? 'Editar Evento' : 'Novo Evento',
          style: const TextStyle(
            fontSize: AppSizes.fontSize18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primary(context),
        ),
      ),
      body: Consumer<EventsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == EventsState.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.state == EventsState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.errorMessage ?? 'Erro desconhecido',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  ButtonWidget(
                    text: 'Tentar novamente',
                    onPressed: _initializeForm,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              children: [
                // Card 1 - Data do Evento
                _buildDateCard(viewModel),
                const SizedBox(height: AppSizes.spacing16),
                
                // Card 2 - Atrações
                _buildAttractionsCard(viewModel),
                const SizedBox(height: AppSizes.spacing16),
                
                // Card 3 - Imagens de Promoção
                _buildPromotionImagesCard(viewModel),
                const SizedBox(height: AppSizes.spacing16),
                
                // Card 4 - Detalhes da Promoção
                _buildPromotionDetailsCard(viewModel),
                const SizedBox(height: AppSizes.spacing32),
                
                // Botões de ação
                _buildActionButtons(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateCard(EventsViewModel viewModel) {
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
            InkWell(
              onTap: () => _selectDate(context, viewModel),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.spacing16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border(context)),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppColors.primary(context),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Text(
                      viewModel.eventDate != null
                          ? '${viewModel.eventDate!.day.toString().padLeft(2, '0')}/${viewModel.eventDate!.month.toString().padLeft(2, '0')}/${viewModel.eventDate!.year}'
                          : 'Selecionar data',
                      style: TextStyle(
                        fontSize: AppSizes.fontSize16,
                        color: viewModel.eventDate != null
                             ? Colors.black
                             : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttractionsCard(EventsViewModel viewModel) {
    // Sincroniza os controllers com as atrações do ViewModel
    _syncAttractionControllers();
    
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
            const SizedBox(height: AppSizes.spacing8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.attractions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FormInputFieldWidget(
                          label: 'Atração ${index + 1}',
                          hint: 'Nome da atração',
                          controller: _attractionControllers[index],
                          onChanged: (value) {
                            viewModel.updateAttraction(index, value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing8),
                      IconButton(
                        onPressed: () {
                          viewModel.removeAttraction(index);
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing8),
            ButtonWidget(
              text: 'Adicionar atração',
              onPressed: () {
                viewModel.addAttraction();
              },
              isOutlined: true,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionImagesCard(EventsViewModel viewModel) {
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
            // Exibe imagens existentes e novas imagens
            if (viewModel.existingPromotionImages.isNotEmpty || viewModel.promotionImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.existingPromotionImages.length + viewModel.promotionImages.length,
                  itemBuilder: (context, index) {
                    final isExistingImage = index < viewModel.existingPromotionImages.length;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSizes.spacing8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                            child: isExistingImage
                                ? Image.network(
                                    viewModel.existingPromotionImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  )
                                : Image.file(
                                    viewModel.promotionImages[index - viewModel.existingPromotionImages.length],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                if (isExistingImage) {
                                  viewModel.removeExistingPromotionImage(index);
                                } else {
                                  viewModel.removePromotionImage(index - viewModel.existingPromotionImages.length);
                                }
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: 'Câmera',
                    onPressed: () {
                      viewModel.addPromotionImageFromCamera();
                    },
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: ButtonWidget(
                    text: 'Galeria',
                    onPressed: () {
                      viewModel.addPromotionImageFromGallery();
                    },
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionDetailsCard(EventsViewModel viewModel) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormInputFieldWidget(
                  label: 'Detalhes da promoção',
                  hint: 'Descreva os detalhes da promoção...',
                  controller: _promoDetailsController,
                  maxLines: 3,
                  maxLength: 100,
                  onChanged: (value) {
                    viewModel.setPromotionDetails(value);
                  },
                ),
                const SizedBox(height: AppSizes.spacing4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_promoDetailsController.text.length}/100',
                    style: TextStyle(
                      fontSize: AppSizes.fontSize12,
                      color: _promoDetailsController.text.length > 100 
                          ? Colors.red 
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(EventsViewModel viewModel) {
    return Column(
      children: [
        ButtonWidget(
          text: widget.event != null ? 'Salvar alterações' : 'Criar evento',
          onPressed: viewModel.isLoading ? null : () async {
            await viewModel.saveEvent();
            if (mounted && viewModel.state == EventsState.success) {
              Navigator.of(context).pop();
            }
          },
          isLoading: viewModel.isLoading,
          isFullWidth: true,
        ),
        if (widget.event != null) ...[
          const SizedBox(height: AppSizes.spacing16),
          ButtonWidget(
            text: 'Excluir evento',
            onPressed: viewModel.isLoading ? null : () async {
              final confirmed = await _showDeleteConfirmation();
              if (confirmed == true) {
                await viewModel.deleteEvent();
                if (mounted && viewModel.state == EventsState.success) {
                  Navigator.of(context).pop();
                }
              }
            },
            isOutlined: true,
            isFullWidth: true,
            textColor: Colors.red,
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, EventsViewModel viewModel) async {
    final DateTime? picked;
    
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Cupertino date picker para iOS
      picked = await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (BuildContext context) {
          final DateTime minimumDate = DateTime.now();
          DateTime tempDate = viewModel.eventDate ?? minimumDate;
          
          // Garante que a data inicial não seja anterior à data mínima
          if (tempDate.isBefore(minimumDate)) {
            tempDate = minimumDate;
          }
          
          return Container(
            height: 300,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context),
                    border: const Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      CupertinoButton(
                        onPressed: () => Navigator.of(context).pop(tempDate),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: tempDate,
                    minimumDate: minimumDate,
                    maximumDate: minimumDate.add(const Duration(days: 365)),
                    onDateTimeChanged: (DateTime date) {
                      tempDate = date;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Material date picker para Android
      final DateTime minimumDate = DateTime.now();
      DateTime initialDate = viewModel.eventDate ?? minimumDate;
      
      // Garante que a data inicial não seja anterior à data mínima
      if (initialDate.isBefore(minimumDate)) {
        initialDate = minimumDate;
      }
      
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: minimumDate,
        lastDate: minimumDate.add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary(context),
              ),
            ),
            child: child!,
          );
        },
      );
    }
    
    if (picked != null) {
      viewModel.setEventDate(picked);
    }
  }

  Future<bool?> _showDeleteConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir este evento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}