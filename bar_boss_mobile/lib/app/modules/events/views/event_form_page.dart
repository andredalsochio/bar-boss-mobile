import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/error_message_widget.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';

/// Tela de formulário de evento (criar/editar)
class EventFormPage extends StatefulWidget {
  final String? eventId;
  final bool readOnly;

  const EventFormPage({Key? key, this.eventId, this.readOnly = false}) : super(key: key);

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

    _initForm();
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_viewModel.eventDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                onSurface: AppColors.textPrimary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
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

      Fluttertoast.showToast(
        msg: _isEditing
            ? AppStrings.eventUpdatedSuccessMessage
            : AppStrings.eventCreatedSuccessMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.success,
        textColor: AppColors.white,
      );

      context.pop();
    } catch (e) {
      debugPrint('Erro ao salvar evento: $e');
    }
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

      Fluttertoast.showToast(
        msg: AppStrings.eventDeletedSuccessMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.success,
        textColor: AppColors.white,
      );

      context.pop();
    } catch (e) {
      debugPrint('Erro ao excluir evento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(
        title: _isEditing
            ? AppStrings.editEventTitle
            : AppStrings.newEventTitle,
        showBackButton: true,
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(
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
                    _buildDatePicker(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Atrações
                    _buildAttractionsSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Promoções
                    _buildPromotionsSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Acesso VIP
                    _buildVipAccessSection(context, viewModel),
                    const SizedBox(height: AppSizes.spacingLarge),

                    // Mensagem de erro
                    if (viewModel.state == EventsState.error && viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
                        child: ErrorMessageWidget(
                          message: viewModel.errorMessage!,
                        ),
                      ),

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

  Widget _buildDatePicker(BuildContext context, EventsViewModel viewModel) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(viewModel.eventDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.eventDateLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
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
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: viewModel.isDateValid ? AppColors.border : AppColors.error,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontSizeMedium,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
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
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: AppSizes.borderWidth,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
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
                      icon: const Icon(
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        // Imagens de promoção (placeholder)
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(
              color: AppColors.border,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              AppStrings.promotionImagesPlaceholder,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSizeMedium,
              ),
            ),
          ),
        ),
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

  Widget _buildVipAccessSection(BuildContext context, EventsViewModel viewModel) {
    return Row(
      children: [
        Checkbox(
          value: viewModel.allowVipAccess,
          onChanged: (value) => viewModel.setAllowVipAccess(value ?? false),
          activeColor: AppColors.primary,
        ),
        const SizedBox(width: AppSizes.spacingSmall),
        Text(
          AppStrings.allowVipAccessLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontSizeMedium,
          ),
        ),
      ],
    );
  }
}