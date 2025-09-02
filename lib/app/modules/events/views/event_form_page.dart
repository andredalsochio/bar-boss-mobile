import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dart:io';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/complete_profile_bottom_sheet.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

/// Tela de formulário de evento (criar/editar)
class EventFormPage extends StatefulWidget {
  final String? eventId;
  final bool readOnly;

  const EventFormPage({super.key, this.eventId, this.readOnly = false});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  late final EventsViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _promotionDetailsController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<EventsViewModel>();
    _isEditing = widget.eventId != null;

    // Inicializa o formulário após o build inicial para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initForm();
    });
  }

  Future<void> _initForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing && widget.eventId != null) {
        await _viewModel.loadEvent(widget.eventId!);
        _promotionDetailsController.text = _viewModel.promotionDetails;
      } else {
        _viewModel.initNewEvent();
        _promotionDetailsController.text = '';
      }
    } catch (e) {
      debugPrint('Erro ao inicializar formulário: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promotionDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = _viewModel.eventDate ?? DateTime.now();
    final BuildContext currentContext = context;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary(context),
                onPrimary: AppColors.white,
                onSurface: AppColors.textPrimary(context),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary(context),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (builderContext, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary(context),
                onPrimary: AppColors.white,
                onSurface: AppColors.textPrimary(context),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary(context),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime newDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        _viewModel.setEventDate(newDateTime);
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _viewModel.saveEvent();

      if (!mounted) return;

      // Verificar se houve erro no ViewModel
      if (_viewModel.state == EventsState.error) {
        return;
      }

      // Verificar se o perfil está incompleto após criar evento
      if (!_isEditing && mounted) {
        final homeViewModel = context.read<HomeViewModel>();
        await homeViewModel.loadCurrentBar();
        
        if (!homeViewModel.isProfileComplete) {
          await _showCompleteProfileBottomSheet(homeViewModel);
        }
      }

      if (!mounted) return;
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Erro ao salvar evento: $e');
      
      if (!mounted) return;
      

    }
  }

  Future<void> _showCompleteProfileBottomSheet(HomeViewModel homeViewModel) async {
    CompleteProfileBottomSheet.show(
      context,
      completedSteps: homeViewModel.completedSteps,
      totalSteps: 2,
    );
  }

  Future<void> _deleteEvent() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteEventConfirmationTitle),
        content: Text(AppStrings.deleteEventConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(AppStrings.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _viewModel.deleteEvent();

      if (!mounted) return;

      

      if (!mounted) return;
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Erro ao excluir evento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBarWidget(
        title: _isEditing
            ? AppStrings.editEventTitle
            : AppStrings.newEventTitle,
        showBackButton: true,
        actions: _isEditing
            ? [
                IconButton(
                  icon: Icon(
                      Icons.delete,
                      color: AppColors.error,
                    ),
                  onPressed: _deleteEvent,
                  tooltip: AppStrings.deleteEventTooltip,
                ),
              ]
            : null,
      ),
      body: Consumer<EventsViewModel>(
        builder: (context, viewModel, _) {
          if (_isLoading) {
            return const LoadingWidget();
          }

          return LoadingOverlay(
            isLoading: viewModel.isLoading,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data do evento
                    _buildDateSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Atrações
                    _buildAttractionsSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Promoções
                    _buildPromotionsSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Botão de salvar
                    ButtonWidget(
                      text: _isEditing
                          ? AppStrings.saveChangesButton
                          : AppStrings.createEventButton,
                      onPressed: viewModel.isFormValid ? _saveEvent : null,
                      isLoading: viewModel.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, EventsViewModel viewModel) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = viewModel.eventDate != null 
        ? dateFormat.format(viewModel.eventDate!) 
        : 'Selecione a data do evento';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.eventDateLabel,
          style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.inputHorizontalPadding,
              vertical: AppSizes.inputVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputBackground(context),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: viewModel.isDateValid ? AppColors.border(context) : AppColors.error,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: viewModel.eventDate != null 
                        ? AppColors.textPrimary(context)
            : AppColors.textSecondary(context),
                    fontSize: AppSizes.fontSizeMedium,
                  ),
                ),
                  Icon(
                  Icons.calendar_today,
                  color: AppColors.primary(context),
                  size: AppSizes.iconSizeSmall,
                ),
              ],
            ),
          ),
        ),
        if (!viewModel.isDateValid)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingSmall),
            child: Text(
              AppStrings.invalidDateErrorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppSizes.fontSizeSmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttractionsSection(BuildContext context, EventsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.attractionsLabel,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: AppColors.primary(context),
              ),
              onPressed: viewModel.addAttraction,
              tooltip: AppStrings.addAttractionTooltip,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.attractions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: viewModel.attractions[index],
                      decoration: InputDecoration(
                        hintText: AppStrings.attractionHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(
                            color: AppColors.border(context),
                            width: AppSizes.borderWidth,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.inputHorizontalPadding,
                          vertical: AppSizes.inputVerticalPadding,
                        ),
                      ),
                      onChanged: (value) => viewModel.updateAttraction(index, value),
                    ),
                  ),
                  if (viewModel.attractions.length > 1)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: AppColors.error,
                      ),
                      onPressed: () => viewModel.removeAttraction(index),
                      tooltip: AppStrings.removeAttractionTooltip,
                    ),
                ],
              ),
            );
          },
        ),
        if (!viewModel.areAttractionsValid)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingSmall),
            child: Text(
              AppStrings.invalidAttractionsErrorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppSizes.fontSizeSmall,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromotionsSection(BuildContext context, EventsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.promotionsLabel,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        // Seção de imagens
        _buildImageSection(viewModel),
        const SizedBox(height: AppSizes.spacingMedium),
        // Detalhes da promoção
        FormInputFieldWidget(
          label: AppStrings.promotionDetailsLabel,
          hint: AppStrings.promotionDetailsHint,
          controller: _promotionDetailsController,
          maxLines: 3,
          onChanged: viewModel.setPromotionDetails,
        ),
      ],
    );
  }

  Widget _buildImageSection(EventsViewModel viewModel) {
    return Column(
      children: [
        // Grid de imagens selecionadas
        if (viewModel.promotionImages.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: viewModel.promotionImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          viewModel.promotionImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => viewModel.removePromotionImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.white,
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
        
        const SizedBox(height: 12),
        
        // Botões para adicionar imagens
        if (viewModel.promotionImages.length < 3)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => viewModel.addPromotionImageFromGallery(),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary(context),
                    side: BorderSide(color: AppColors.primary(context)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => viewModel.addPromotionImageFromCamera(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary(context),
                    side: BorderSide(color: AppColors.primary(context)),
                  ),
                ),
              ),
            ],
          ),
        
        // Placeholder quando não há imagens
        if (viewModel.promotionImages.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputBackground(context),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: AppColors.border(context),
                width: AppSizes.borderWidth,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.promotionImagesPlaceholder,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }


}
// Remover imports não utilizados se necessário, baseado na análise.