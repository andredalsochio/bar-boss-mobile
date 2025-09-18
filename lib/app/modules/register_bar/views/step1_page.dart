import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/utils/formatters.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';

import 'package:bar_boss_mobile/app/core/widgets/step_progress_widget.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';

/// Tela de cadastro de bar - Passo 1 (Informações de contato)
class Step1Page extends StatefulWidget {
  const Step1Page({super.key});

  @override
  State<Step1Page> createState() => _Step1PageState();
}

class _Step1PageState extends State<Step1Page> {
  final _emailController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nameController = TextEditingController();
  final _responsibleNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _cnpjFormatter = Formatters.cnpjFormatter;
  final _phoneFormatter = Formatters.phoneFormatter;

  late final BarRegistrationViewModel _viewModel;
  bool _isUserAuthenticated = false;
  
  // Controle de exibição de erros
  bool _showEmailError = false;
  bool _showCnpjError = false;
  bool _showNameError = false;
  bool _showResponsibleNameError = false;
  bool _showPhoneError = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();

    // Verifica se o usuário está autenticado e preenche o email automaticamente
    final authViewModel = context.read<AuthViewModel>();
    final currentUserEmail = authViewModel.currentUser?.email;
    _isUserAuthenticated = currentUserEmail != null && currentUserEmail.isNotEmpty;
    
    // Debug: Log de entrada do fluxo
    final flowType = _isUserAuthenticated ? 'SOCIAL' : 'CLÁSSICO';
    final uid = authViewModel.currentUser?.uid ?? 'null';
    debugPrint('🚀 [STEP1_PAGE] === INICIANDO FLUXO $flowType ===');
    debugPrint('📱 [STEP1_PAGE] Tela carregada | fluxo=$flowType | uid=$uid');
    
    if (_isUserAuthenticated) {
      _emailController.text = currentUserEmail!;
      // Usa addPostFrameCallback para evitar notifyListeners durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.setEmailSilent(currentUserEmail);
        debugPrint('🔐 [STEP1_PAGE] Fluxo Social - Email preenchido e travado | email=${currentUserEmail.substring(0, 3)}***');
      });
    } else {
      debugPrint('📝 [STEP1_PAGE] Fluxo Clássico - Email livre para edição');
    }

    // Adiciona listeners para atualizar o ViewModel quando os valores mudarem
    _emailController.addListener(_updateEmail);
    _cnpjController.addListener(_updateCnpj);
    _nameController.addListener(_updateName);
    _responsibleNameController.addListener(_updateResponsibleName);
    _phoneController.addListener(_updatePhone);
  }



  @override
  void dispose() {
    // Remove os listeners
    _emailController.removeListener(_updateEmail);
    _cnpjController.removeListener(_updateCnpj);
    _nameController.removeListener(_updateName);
    _responsibleNameController.removeListener(_updateResponsibleName);
    _phoneController.removeListener(_updatePhone);

    // Dispose dos controladores
    _emailController.dispose();
    _cnpjController.dispose();
    _nameController.dispose();
    _responsibleNameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  void _updateEmail() {
    _viewModel.setEmail(_emailController.text);
  }

  void _updateCnpj() {
    _viewModel.setCnpj(_cnpjController.text);
  }

  void _updateName() {
    _viewModel.setName(_nameController.text);
  }

  void _updateResponsibleName() {
    _viewModel.setResponsibleName(_responsibleNameController.text);
  }

  void _updatePhone() {
    _viewModel.setPhone(_phoneController.text);
  }
  
  void _validateAndShowErrors() {
    setState(() {
      _showEmailError = Validators.email(_emailController.text) != null;
      _showCnpjError = Validators.cnpj(_cnpjController.text) != null;
      _showNameError = Validators.required(_nameController.text) != null;
      _showResponsibleNameError = Validators.required(_responsibleNameController.text) != null;
      _showPhoneError = Validators.phone(_phoneController.text) != null;
    });
  }

  Widget _buildValidationStatusIndicator(BuildContext context, StepValidationState state) {
    IconData icon;
    Color color;
    String text;

    switch (state) {
      case StepValidationState.initial:
        icon = Icons.info_outline;
        color = AppColors.textSecondary(context);
        text = 'Preencha os dados abaixo';
        break;
      case StepValidationState.invalid:
        icon = Icons.error_outline;
        color = AppColors.error;
        text = 'Dados incompletos ou inválidos';
        break;
      case StepValidationState.validating:
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        text = 'Validando dados...';
        break;
      case StepValidationState.valid:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        text = 'Dados válidos';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMedium,
        vertical: AppSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSizes.spacingSmall),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToNextStep() async {
    debugPrint('🔘 [STEP1_PAGE] Botão Continuar pressionado');
    debugPrint('🔘 [STEP1_PAGE] Email: "${_viewModel.email}"');
    debugPrint('🔘 [STEP1_PAGE] CNPJ: "${_viewModel.cnpj}"');
    debugPrint('🔘 [STEP1_PAGE] Nome do bar: "${_viewModel.name}"');
    debugPrint('🔘 [STEP1_PAGE] Nome responsável: "${_viewModel.responsibleName}"');
    debugPrint('🔘 [STEP1_PAGE] Telefone: "${_viewModel.phone}"');
    debugPrint('🔘 [STEP1_PAGE] isStep1Valid: ${_viewModel.isStep1Valid}');
    
    // Fechar o teclado
    FocusScope.of(context).unfocus();

    // Primeiro, valida o formato dos dados
    if (!_viewModel.isStep1Valid) {
      debugPrint('❌ [STEP1_PAGE] Step1 inválido, exibindo erros');
      _validateAndShowErrors();
      return;
    }

    final flowType = _isUserAuthenticated ? 'SOCIAL' : 'CLÁSSICO';
    debugPrint('✅ [STEP1_PAGE] Step1 válido, iniciando validação de unicidade...');
    debugPrint('🔍 [STEP1_PAGE] Fluxo $flowType - Validando disponibilidade...');
    
    // Executa validação de unicidade (fluxo Social/Clássico)
    await _viewModel.validateStep1Uniqueness();
    
    // Verifica se pode prosseguir após validação de unicidade
    if (!_viewModel.canProceedToStep2) {
      debugPrint('❌ [STEP1_PAGE] Não pode prosseguir - erro de unicidade: ${_viewModel.uniquenessError}');
      return;
    }

    debugPrint('✅ [STEP1_PAGE] Validação de unicidade aprovada, navegando para Step2');
    debugPrint('🧭 [NAV] step1 -> step2');
    if (mounted) {
      context.pushNamed('registerStep2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBarWidget(
        title: AppStrings.registerBarStep1Title,
        showBackButton: true,
      ),
      body: Consumer<BarRegistrationViewModel>(
        builder: (context, viewModel, _) {
          return LoadingOverlay(
            isLoading: viewModel.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spacing),
                  const StepProgressWidget(
              currentStep: 1,
              totalSteps: 3,
              title: 'Etapa 1 de 3: Informações de contato',
            ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  Text(
                    AppStrings.registerBarStep1Subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  // Indicador de status de validação
                  _buildValidationStatusIndicator(context, viewModel.step1ValidationState),
                  const SizedBox(height: AppSizes.spacingLarge),
                  FormInputFieldWidget(
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !_isUserAuthenticated, // Desabilitado apenas se usuário estiver autenticado
                    inputFormatters: [LowerCaseTextFormatter()],
                    showError: _showEmailError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.cnpjLabel,
                    hint: AppStrings.cnpjHint,
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cnpjFormatter],
                    validator: (value) => Validators.cnpj(value),
                    showError: _showCnpjError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.barNameLabel,
                    hint: AppStrings.barNameHint,
                    controller: _nameController,
                    validator: (value) => Validators.required(value),
                    showError: _showNameError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.responsibleNameLabel,
                    hint: AppStrings.responsibleNameHint,
                    controller: _responsibleNameController,
                    validator: (value) => Validators.required(value),
                    showError: _showResponsibleNameError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.phoneLabel,
                    hint: AppStrings.phoneHint,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                    validator: (value) => Validators.phone(value),
                    showError: _showPhoneError,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  // Exibe erro de unicidade se houver
                  if (viewModel.hasUniquenessError) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.spacingSmall),
                          Expanded(
                            child: Text(
                              viewModel.uniquenessError!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingMedium),
                  ],

                  ButtonWidget(
                    text: AppStrings.continueButton,
                    onPressed: viewModel.step1ButtonState == ButtonState.disabled ? null : _goToNextStep,
                    isLoading: viewModel.step1ButtonState == ButtonState.loading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Formatter para converter texto para minúsculas
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}