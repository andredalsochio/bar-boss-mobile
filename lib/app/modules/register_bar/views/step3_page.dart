import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_password_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';

import 'package:bar_boss_mobile/app/core/widgets/step_progress_widget.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// Tela de cadastro de bar - Passo 3 (Senha)
class Step3Page extends StatefulWidget {
  const Step3Page({super.key});

  @override
  State<Step3Page> createState() => _Step3PageState();
}

class _Step3PageState extends State<Step3Page> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controle de exibição de erros
  bool _showPasswordError = false;
  bool _showConfirmPasswordError = false;

  late final BarRegistrationViewModel _viewModel;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();
    _authViewModel = context.read<AuthViewModel>();

    // Inicializa os controladores vazios
    _passwordController.text = '';
    _confirmPasswordController.text = '';

    // Adiciona listeners para atualizar o ViewModel quando os valores mudarem
    _passwordController.addListener(_updatePassword);
    _confirmPasswordController.addListener(_updateConfirmPassword);

    // Limpa os campos de senha no ViewModel após a construção do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.clearPasswordFields();
    });
  }

  @override
  void dispose() {
    // Remove os listeners
    _passwordController.removeListener(_updatePassword);
    _confirmPasswordController.removeListener(_updateConfirmPassword);

    // Dispose dos controladores
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _updatePassword() {
    _viewModel.setPassword(_passwordController.text);
  }

  void _updateConfirmPassword() {
    _viewModel.setConfirmPassword(_confirmPasswordController.text);
  }

  void _validateAndShowErrors() {
    setState(() {
      _showPasswordError = Validators.password(_passwordController.text) != null;
      _showConfirmPasswordError = Validators.confirmPassword(_passwordController.text)(_confirmPasswordController.text) != null;
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
        text = 'Crie uma senha segura';
        break;
      case StepValidationState.invalid:
        icon = Icons.error_outline;
        color = AppColors.error;
        text = 'Senhas inválidas ou não coincidem';
        break;
      case StepValidationState.validating:
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        text = 'Validando dados...';
        break;
      case StepValidationState.valid:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        text = 'Senhas válidas';
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

  void _goToPreviousStep() {
    // Verifica se há algo na pilha de navegação para fazer pop
    if (context.canPop()) {
      context.pop();
    } else {
      // Se não há nada para fazer pop, navega diretamente para o step2
      context.goNamed('registerStep2');
    }
  }

  Future<void> _submitRegistration() async {
    // Fecha o teclado antes de iniciar o processo de cadastro
    FocusScope.of(context).unfocus();
    
    if (!_viewModel.isStep3Valid) {
      _validateAndShowErrors();
      return;
    }

    try {
      // Verifica se é usuário de login social
      if (_authViewModel.isFromSocialProvider) {
        final uid = _authViewModel.currentUser?.uid ?? 'unknown';
        debugPrint('🚀 [FLOW] start | type=social | uid=$uid');
        // Para usuários de login social, usa o método específico
        await _viewModel.finalizeSocialLoginRegistration();
      } else {
        debugPrint('🚀 [FLOW] start | type=signup | uid=creating');
        // Para usuários de cadastro tradicional, usa o método padrão
        await _viewModel.registerBarAndUser();
      }

      if (!mounted) return;

      if (_viewModel.registrationState == RegistrationState.success) {
        // Mensagem de sucesso será exibida pelo ToastService no ViewModel

        // Navega para a tela inicial após o cadastro bem-sucedido
        context.goNamed('home');
      }
    } catch (e) {
      // O erro já é tratado no ViewModel
      debugPrint('Erro ao cadastrar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBarWidget(
        title: AppStrings.registerBarStep3Title,
        showBackButton: true,
        onBackPressed: _goToPreviousStep,
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
                    currentStep: 3,
                    totalSteps: 3,
                    title: 'Etapa 3 de 3: Criar senha',
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  Text(
                    AppStrings.registerBarStep3Subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  // Indicador de status de validação
                  _buildValidationStatusIndicator(context, viewModel.step3ValidationState),
                  const SizedBox(height: AppSizes.spacingLarge),
                  FormPasswordFieldWidget(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordHint,
                    controller: _passwordController,
                    validator: Validators.password,
                    showError: _showPasswordError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormPasswordFieldWidget(
                    label: AppStrings.confirmPasswordLabel,
                    hint: AppStrings.confirmPasswordHint,
                    controller: _confirmPasswordController,
                    validator: Validators.confirmPassword(_passwordController.text),
                    showError: _showConfirmPasswordError,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  ButtonWidget(
                    text: AppStrings.submitRegistrationButton,
                    onPressed: viewModel.step3ButtonState == ButtonState.disabled ? null : _submitRegistration,
                    isLoading: viewModel.step3ButtonState == ButtonState.loading,
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