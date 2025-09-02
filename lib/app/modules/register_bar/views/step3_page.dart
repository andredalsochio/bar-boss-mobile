import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/error_message_widget.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';

/// Tela de cadastro de bar - Passo 3 (Senha)
class Step3Page extends StatefulWidget {
  const Step3Page({super.key});

  @override
  State<Step3Page> createState() => _Step3PageState();
}

class _Step3PageState extends State<Step3Page> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final BarRegistrationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();

    // Inicializa os controladores com os valores do ViewModel
    _passwordController.text = _viewModel.password;
    _confirmPasswordController.text = _viewModel.confirmPassword;

    // Adiciona listeners para atualizar o ViewModel quando os valores mudarem
    _passwordController.addListener(_updatePassword);
    _confirmPasswordController.addListener(_updateConfirmPassword);
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

  void _goToPreviousStep() {
    context.pop();
  }

  Future<void> _submitRegistration() async {
    if (!_viewModel.isStep3Valid) return;

    try {
      await _viewModel.registerBarAndUser();

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
      backgroundColor: AppColors.background,
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
                  Text(
                    AppStrings.registerBarStep3Subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  FormInputFieldWidget(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordHint,
                    controller: _passwordController,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.confirmPasswordLabel,
                    hint: AppStrings.confirmPasswordHint,
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: Validators.confirmPassword(_passwordController.text),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  ButtonWidget(
                    text: AppStrings.submitRegistrationButton,
                    onPressed: viewModel.isStep3Valid ? _submitRegistration : null,
                    isLoading: viewModel.isLoading,
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