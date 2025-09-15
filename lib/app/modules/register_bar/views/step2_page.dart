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
  
  // Variáveis para controlar exibição de erros
  bool _showCepError = false;
  bool _showStreetError = false;
  bool _showNumberError = false;
  bool _showStateError = false;
  bool _showCityError = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();
    _authViewModel = context.read<AuthViewModel>();



    // Adiciona listeners para atualizar o ViewModel quando os valores mudarem
    _cepController.addListener(_updateCep);
    _streetController.addListener(_updateStreet);
    _numberController.addListener(_updateNumber);
    _complementController.addListener(_updateComplement);
    _cityController.addListener(_updateCity);
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
  
  void _validateAndShowErrors() {
    setState(() {
      _showCepError = Validators.cep(_cepController.text) != null;
      _showStreetError = Validators.required(_streetController.text) != null;
      _showNumberError = Validators.required(_numberController.text) != null;
      _showStateError = _stateController.text.isEmpty;
      _showCityError = Validators.required(_cityController.text) != null;
    });
  }

  void _goToNextStep() async {
    // Valida o Step 2 antes de prosseguir
    if (!_viewModel.isStep2Valid) {
      _validateAndShowErrors();
      return;
    }

    if (_authViewModel.isFromSocialProvider) {
      // Verifica se o usuário já possui senha configurada
      final hasPassword = await _viewModel.hasPasswordProvider();
      
      if (!mounted) return;
      
      if (hasPassword) {
        // Se já tem senha, finaliza o cadastro sem mostrar o Step 3
        debugPrint('🔍 [Step2Page] Usuário já possui senha, finalizando cadastro sem Step 3...');
        await _viewModel.finalizeSocialLoginRegistrationWithoutPassword();
      } else {
        // Se não tem senha, vai para o Step 3 normalmente
        debugPrint('🔍 [Step2Page] Usuário não possui senha, indo para Step 3...');
        context.pushNamed('registerStep3');
      }
    } else {
      // Para usuários de cadastro normal, vai para o Step 3
      context.pushNamed('registerStep3');
    }
  }

  /// Salva o Passo 2 para usuários de login social
  Future<void> _saveSocialLoginStep2() async {
    if (!_viewModel.isStep2Valid) {
      _validateAndShowErrors();
      return;
    }

    // Verifica se o usuário já possui senha configurada
    final hasPassword = await _viewModel.hasPasswordProvider();
    
    if (hasPassword) {
      // Se já tem senha, finaliza o cadastro sem mostrar o Step 3
      debugPrint('🔍 [Step2Page] Usuário já possui senha, finalizando cadastro sem Step 3...');
      await _viewModel.finalizeSocialLoginRegistrationWithoutPassword();
      
      // Navega para a home após sucesso
      if (mounted && _viewModel.registrationState == RegistrationState.success) {
        context.goNamed('home');
      }
    } else {
      // Se não tem senha, vai para o Step 3 normalmente
      debugPrint('🔍 [Step2Page] Usuário não possui senha, indo para Step 3...');
      if (mounted) context.pushNamed('registerStep3');
    }
  }

  void _goToPreviousStep() {
    // Verifica se há algo na pilha de navegação para fazer pop
    if (context.canPop()) {
      context.pop();
    } else {
      // Se não há nada para fazer pop, navega diretamente para o step2
      context.goNamed('registerStep1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
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
              totalSteps: 3,
              title: 'Etapa 2 de 3: Endereço do estabelecimento',
            ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  Text(
                    AppStrings.registerBarStep2Subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary(context),
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
                    showError: _showCepError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.streetLabel,
                    hint: AppStrings.streetHint,
                    controller: _streetController,
                    validator: (value) => Validators.required(value),
                    showError: _showStreetError,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.numberLabel,
                    hint: AppStrings.numberHint,
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.required(value),
                    showError: _showNumberError,
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
                      labelStyle: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: AppSizes.fontSizeMedium,
                        ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: BorderSide(
                            color: AppColors.border(context),
                            width: AppSizes.borderWidth,
                          ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: BorderSide(
                            color: _showStateError ? AppColors.error : AppColors.border(context),
                            width: AppSizes.borderWidth,
                          ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: BorderSide(
                            color: _showStateError ? AppColors.error : AppColors.primary(context),
                            width: AppSizes.borderWidth,
                          ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        borderSide: BorderSide(
                            color: AppColors.error,
                            width: AppSizes.borderWidth,
                          ),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground(context),
                      contentPadding: EdgeInsets.symmetric(
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
                    style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: AppSizes.fontSizeMedium,
                      ),
                    dropdownColor: AppColors.inputBackground(context),
                    isExpanded: true,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.cityLabel,
                    hint: AppStrings.cityHint,
                    controller: _cityController,
                    validator: (value) => Validators.required(value),
                    showError: _showCityError,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  ButtonWidget(
                    text: _authViewModel.isFromSocialProvider 
                        ? 'Salvar' 
                        : AppStrings.continueButton,
                    onPressed: _authViewModel.isFromSocialProvider 
                        ? _saveSocialLoginStep2 
                        : _goToNextStep,
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