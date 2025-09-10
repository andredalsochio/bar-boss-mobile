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

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarRegistrationViewModel>();

    // Verifica se o usuário está autenticado e preenche o email automaticamente
    final authViewModel = context.read<AuthViewModel>();
    final currentUserEmail = authViewModel.currentUser?.email;
    _isUserAuthenticated = currentUserEmail != null && currentUserEmail.isNotEmpty;
    
    if (_isUserAuthenticated) {
      _emailController.text = currentUserEmail!;
      _viewModel.setEmail(currentUserEmail);
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

  Future<void> _goToNextStep() async {
    debugPrint('🔘 [STEP1_PAGE] Botão Continuar pressionado');
    debugPrint('🔘 [STEP1_PAGE] Email: "${_viewModel.email}"');
    debugPrint('🔘 [STEP1_PAGE] CNPJ: "${_viewModel.cnpj}"');
    debugPrint('🔘 [STEP1_PAGE] Nome do bar: "${_viewModel.name}"');
    debugPrint('🔘 [STEP1_PAGE] Nome responsável: "${_viewModel.responsibleName}"');
    debugPrint('🔘 [STEP1_PAGE] Telefone: "${_viewModel.phone}"');
    debugPrint('🔘 [STEP1_PAGE] isStep1Valid: ${_viewModel.isStep1Valid}');
    
    if (!_viewModel.isStep1Valid) {
      debugPrint('❌ [STEP1_PAGE] Step1 inválido, não prosseguindo');
      debugPrint('❌ [STEP1_PAGE] Validações individuais:');
      debugPrint('❌ [STEP1_PAGE] - Email válido: ${_viewModel.isEmailValid}');
      debugPrint('❌ [STEP1_PAGE] - CNPJ válido: ${_viewModel.isCnpjValid}');
      debugPrint('❌ [STEP1_PAGE] - Nome válido: ${_viewModel.isNameValid}');
      debugPrint('❌ [STEP1_PAGE] - Nome responsável válido: ${_viewModel.isResponsibleNameValid}');
      debugPrint('❌ [STEP1_PAGE] - Telefone válido: ${_viewModel.isPhoneValid}');
      return;
    }

    debugPrint('✅ [STEP1_PAGE] Step1 válido, iniciando validação assíncrona...');
    final isValid = await _viewModel.validateStep1AndCheckEmail();
    
    debugPrint('🔍 [STEP1_PAGE] Resultado da validação assíncrona: $isValid');
    debugPrint('🔍 [STEP1_PAGE] Widget ainda montado: $mounted');
    
    if (isValid && mounted) {
      debugPrint('💾 [STEP1_PAGE] Salvando dados do Passo 1...');
      
      try {
        // Verifica se o usuário já tem um bar cadastrado (login social)
        // através do AuthRepository e UserRepository
        final authRepository = context.read<AuthRepository>();
        final userRepository = context.read<UserRepository>();
        final currentUser = authRepository.currentUser;
        
        if (currentUser != null) {
           final userProfile = await userRepository.getMe();
           final hasExistingBar = userProfile?.currentBarId != null && userProfile!.currentBarId!.isNotEmpty;
           
           debugPrint('🔍 [STEP1_PAGE] Usuário tem bar existente: $hasExistingBar (currentBarId: ${userProfile?.currentBarId})');
           
           // Se sim, salva no Firestore para atualizar o banner
           // Verifica se usuário tem bar existente
           if (hasExistingBar) {
            debugPrint('🏢 [STEP1_PAGE] Usuário tem bar existente, salvando no Firestore...');
            await _viewModel.saveStep1(userProfile.currentBarId!);
          } else {
            debugPrint('📝 [STEP1_PAGE] Usuário sem bar, dados validados.');
          }
        } else {
          debugPrint('📝 [STEP1_PAGE] Usuário não autenticado, dados validados.');
        }
     } catch (e) {
       debugPrint('⚠️ [STEP1_PAGE] Erro ao verificar bar existente: $e');
       // Em caso de erro, apenas continua
     }
      
      debugPrint('✅ [STEP1_PAGE] Dados salvos, navegando para Step2');
      if (mounted) {
        context.pushNamed('registerStep2');
      }
    } else {
      debugPrint('❌ [STEP1_PAGE] Validação falhou ou widget desmontado');
      if (!isValid) {
        debugPrint('❌ [STEP1_PAGE] Erro na validação: ${_viewModel.errorMessage}');
      }
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
                  const SizedBox(height: AppSizes.spacingLarge),
                  FormInputFieldWidget(
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !_isUserAuthenticated, // Desabilitado apenas se usuário estiver autenticado
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.cnpjLabel,
                    hint: AppStrings.cnpjHint,
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cnpjFormatter],
                    validator: (value) => Validators.cnpj(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.barNameLabel,
                    hint: AppStrings.barNameHint,
                    controller: _nameController,
                    validator: (value) => Validators.required(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.responsibleNameLabel,
                    hint: AppStrings.responsibleNameHint,
                    controller: _responsibleNameController,
                    validator: (value) => Validators.required(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.phoneLabel,
                    hint: AppStrings.phoneHint,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                    validator: (value) => Validators.phone(value),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),

                  ButtonWidget(
                    text: AppStrings.continueButton,
                    onPressed: viewModel.isStep1Valid ? _goToNextStep : null,
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