import 'package:flutter/material.dart';
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

/// Tela de cadastro de bar - Passo 2 (Endereço)
class Step2Page extends StatefulWidget {
  const Step2Page({super.key});

  @override
  State<Step2Page> createState() => _Step2PageState();
}

class _Step2PageState extends State<Step2Page> {
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();

  final _cepFormatter = Formatters.cepFormatter;

  // Lista de estados brasileiros
  final List<String> _states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  late final BarRegistrationViewModel _viewModel;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();
    _authViewModel = context.read<AuthViewModel>();

    // Carrega rascunhos salvos
    _loadDrafts();

    // Adiciona listeners para atualizar o ViewModel quando os valores mudarem
    _cepController.addListener(_updateCep);
    _streetController.addListener(_updateStreet);
    _numberController.addListener(_updateNumber);
    _complementController.addListener(_updateComplement);
    _cityController.addListener(_updateCity);
  }

  /// Carrega rascunhos salvos e atualiza os controladores
  Future<void> _loadDrafts() async {
    await _viewModel.loadDrafts();
    
    // Atualiza os controladores com os valores carregados
    _cepController.text = _viewModel.cep;
    _streetController.text = _viewModel.street;
    _numberController.text = _viewModel.number;
    _complementController.text = _viewModel.complement;
    _stateController.text = _viewModel.state;
    _cityController.text = _viewModel.city;
  }

  @override
  void dispose() {
    // Remove os listeners
    _cepController.removeListener(_updateCep);
    _streetController.removeListener(_updateStreet);
    _numberController.removeListener(_updateNumber);
    _complementController.removeListener(_updateComplement);
    _cityController.removeListener(_updateCity);

    // Dispose dos controladores
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _stateController.dispose();
    _cityController.dispose();

    super.dispose();
  }

  void _updateCep() {
    _viewModel.setCep(_cepController.text);
  }

  void _updateStreet() {
    _viewModel.setStreet(_streetController.text);
  }

  void _updateNumber() {
    _viewModel.setNumber(_numberController.text);
  }

  void _updateComplement() {
    _viewModel.setComplement(_complementController.text);
  }

  void _updateState(String value) {
    _viewModel.setState(value);
  }

  void _updateCity() {
    _viewModel.setCity(_cityController.text);
  }

  void _goToNextStep() {
    if (_viewModel.isStep2Valid) {
      context.pushNamed('registerStep3');
    }
  }

  /// Salva o Passo 2 para usuários de login social
  Future<void> _saveSocialLoginStep2() async {
    if (!_viewModel.isStep2Valid) return;

    try {
      debugPrint('💾 [STEP2_PAGE] Salvando dados do Passo 2...');
      // Salva os dados do Passo 2 como rascunho
      _viewModel.saveDraftStep2();
      
      // Cria o bar e salva os dados
      await _viewModel.createBarFromSocialLogin();
      
      // Mensagem de sucesso será exibida pelo ToastService no ViewModel
      
      debugPrint('✅ [STEP2_PAGE] Cadastro completo, navegando para Home');
      // Navega para a Home
      if (mounted) {
        context.goNamed('home');
      }
    } catch (e) {
      debugPrint('❌ [STEP2_PAGE] Erro ao salvar cadastro: $e');
      // Mensagem de erro será exibida pelo ToastService no ViewModel
    }
  }

  void _goToPreviousStep() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(
        title: AppStrings.registerBarStep2Title,
        showBackButton: true,
        onBackPressed: _goToPreviousStep,
      ),
      body: Consumer<BarRegistrationViewModel>(
        builder: (context, viewModel, _) {
          // Atualiza os controladores após o build para evitar setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_streetController.text != viewModel.street) {
              _streetController.text = viewModel.street;
            }
            if (_stateController.text != viewModel.state) {
              _stateController.text = viewModel.state;
            }
            if (_cityController.text != viewModel.city) {
              _cityController.text = viewModel.city;
            }
            if (_complementController.text != viewModel.complement) {
              _complementController.text = viewModel.complement;
            }
          });

          return LoadingOverlay(
            isLoading: viewModel.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spacing),
                  const StepProgressWidget(
              currentStep: 2,
              totalSteps: 2,
              title: 'Etapa 2 de 2: Endereço do estabelecimento',
            ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  Text(
                    AppStrings.registerBarStep2Subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  FormInputFieldWidget(
                    label: AppStrings.cepLabel,
                    hint: AppStrings.cepHint,
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cepFormatter],
                    validator: (value) => Validators.cep(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.streetLabel,
                    hint: AppStrings.streetHint,
                    controller: _streetController,
                    validator: (value) => Validators.required(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.numberLabel,
                    hint: AppStrings.numberHint,
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.required(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.complementLabel,
                    hint: AppStrings.complementHint,
                    controller: _complementController,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: AppStrings.stateLabel,
                      labelStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.fontSizeMedium,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: const BorderSide(
                          color: AppColors.error,
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
                    value: viewModel.state.isNotEmpty ? viewModel.state : null,
                    items: _states.map((state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateState(value);
                      }
                    },
                    hint: Text(AppStrings.stateHint),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    dropdownColor: AppColors.inputBackground,
                    isExpanded: true,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.cityLabel,
                    hint: AppStrings.cityHint,
                    controller: _cityController,
                    validator: (value) => Validators.required(value),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  ButtonWidget(
                    text: _authViewModel.isFromSocialProvider 
                        ? 'Salvar' 
                        : AppStrings.continueButton,
                    onPressed: viewModel.isStep2Valid 
                        ? (_authViewModel.isFromSocialProvider 
                            ? _saveSocialLoginStep2 
                            : _goToNextStep) 
                        : null,
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