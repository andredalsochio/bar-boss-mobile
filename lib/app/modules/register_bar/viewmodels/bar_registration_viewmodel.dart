import 'package:flutter/foundation.dart';
import 'package:search_cep/search_cep.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/storage/draft_storage.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';

/// Estados possíveis do cadastro de bar
enum RegistrationState { initial, loading, success, error }

/// ViewModel para o cadastro de bar
class BarRegistrationViewModel extends ChangeNotifier {
  final BarRepositoryDomain _barRepository;
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  // Estado atual do cadastro
  RegistrationState _registrationState = RegistrationState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  // Dados do bar - Passo 1 (Informações de contato)
  String _email = '';
  String _cnpj = '';
  String _name = '';
  String _responsibleName = '';
  String _phone = '';

  // Validação do Passo 1
  bool _isEmailValid = false;
  bool _isCnpjValid = false;
  bool _isNameValid = false;
  bool _isResponsibleNameValid = false;
  bool _isPhoneValid = false;

  // Dados do bar - Passo 2 (Endereço)
  String _cep = '';
  String _street = '';
  String _number = '';
  String _complement = '';
  String _stateUf = '';
  String _city = '';

  // Validação do Passo 2
  bool _isCepValid = false;
  bool _isStreetValid = false;
  bool _isNumberValid = false;
  bool _isStateValid = false;
  bool _isCityValid = false;

  // Dados do bar - Passo 3 (Senha)
  String _password = '';
  String _confirmPassword = '';

  // Validação do Passo 3
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  BarRegistrationViewModel({
    required BarRepositoryDomain barRepository,
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _barRepository = barRepository,
       _authRepository = authRepository,
       _userRepository = userRepository;

  // Getters para o estado
  RegistrationState get registrationState => _registrationState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Getters para os dados do Passo 1
  String get email => _email;
  String get cnpj => _cnpj;
  String get name => _name;
  String get responsibleName => _responsibleName;
  String get phone => _phone;

  // Getters para validação do Passo 1
  bool get isEmailValid => _isEmailValid;
  bool get isCnpjValid => _isCnpjValid;
  bool get isNameValid => _isNameValid;
  bool get isResponsibleNameValid => _isResponsibleNameValid;
  bool get isPhoneValid => _isPhoneValid;
  bool get isStep1Valid =>
      _isEmailValid &&
      _isCnpjValid &&
      _isNameValid &&
      _isResponsibleNameValid &&
      _isPhoneValid;

  // Getters para os dados do Passo 2
  String get cep => _cep;
  String get street => _street;
  String get number => _number;
  String get complement => _complement;
  String get state => _stateUf;
  String get city => _city;

  // Getters para validação do Passo 2
  bool get isCepValid => _isCepValid;
  bool get isStreetValid => _isStreetValid;
  bool get isNumberValid => _isNumberValid;
  bool get isStateValid => _isStateValid;
  bool get isCityValid => _isCityValid;
  bool get isStep2Valid =>
      _isCepValid &&
      _isStreetValid &&
      _isNumberValid &&
      _isStateValid &&
      _isCityValid;

  // Getters para os dados do Passo 3
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  // Getters para validação do Passo 3
  bool get isPasswordValid => _isPasswordValid;
  bool get isConfirmPasswordValid => _isConfirmPasswordValid;
  bool get isStep3Valid => _isPasswordValid && _isConfirmPasswordValid;

  // Setters para os dados do Passo 1
  void setEmail(String value) {
    _email = value;
    _validateEmail();
    _saveDraftStep1();
    notifyListeners();
  }

  void setCnpj(String value) {
    _cnpj = value;
    _validateCnpj();
    _saveDraftStep1();
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    _validateName();
    _saveDraftStep1();
    notifyListeners();
  }

  void setResponsibleName(String value) {
    _responsibleName = value;
    _validateResponsibleName();
    _saveDraftStep1();
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    _validatePhone();
    _saveDraftStep1();
    notifyListeners();
  }

  // Setters para os dados do Passo 2
  void setCep(String value) {
    _cep = value;
    _validateCep();
    _saveDraftStep2();
    notifyListeners();

    // Se o CEP for válido, busca o endereço
    if (_isCepValid) {
      _searchCep();
    }
  }

  void setStreet(String value) {
    _street = value;
    _validateStreet();
    _saveDraftStep2();
    notifyListeners();
  }

  void setNumber(String value) {
    _number = value;
    _validateNumber();
    _saveDraftStep2();
    notifyListeners();
  }

  void setComplement(String value) {
    _complement = value;
    _saveDraftStep2();
    notifyListeners();
  }

  void setState(String value) {
    _stateUf = value;
    _validateState();
    _saveDraftStep2();
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    _validateCity();
    _saveDraftStep2();
    notifyListeners();
  }

  // Setters para os dados do Passo 3
  void setPassword(String value) {
    _password = value;
    _validatePassword();
    _validateConfirmPassword(); // Valida novamente a confirmação de senha
    _saveDraftStep3();
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _validateConfirmPassword();
    _saveDraftStep3();
    notifyListeners();
  }

  // Métodos de validação do Passo 1
  void _validateEmail() {
    _isEmailValid =
        _email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);
  }

  /// Valida o Passo 1 com verificações assíncronas de email e CNPJ
  /// Retorna true se tudo estiver válido e não houver duplicatas
  Future<bool> validateStep1AndCheckEmail() async {
    debugPrint('🔍 [VIEWMODEL] validateStep1AndCheckEmail INICIADO');
    debugPrint('🔍 [VIEWMODEL] Email a verificar: "$_email"');
    debugPrint('🔍 [VIEWMODEL] CNPJ a verificar: "$_cnpj"');
    debugPrint('🔍 [VIEWMODEL] isStep1Valid: $isStep1Valid');
    
    if (!isStep1Valid) {
      debugPrint('❌ [VIEWMODEL] Step 1 inválido - campos obrigatórios não preenchidos');
      debugPrint('❌ [VIEWMODEL] Validações individuais:');
      debugPrint('❌ [VIEWMODEL] - Email válido: $isEmailValid');
      debugPrint('❌ [VIEWMODEL] - CNPJ válido: $isCnpjValid');
      debugPrint('❌ [VIEWMODEL] - Nome válido: $isNameValid');
      debugPrint('❌ [VIEWMODEL] - Nome responsável válido: $isResponsibleNameValid');
      debugPrint('❌ [VIEWMODEL] - Telefone válido: $isPhoneValid');
      _setError('Preencha todos os campos obrigatórios');
      return false;
    }

    debugPrint('✅ [VIEWMODEL] Campos válidos, iniciando verificações assíncronas...');
    _setLoading(true);
    _clearError();

    try {
      // Verificar se o usuário está autenticado e se o email é o mesmo
      final currentUser = _authRepository.currentUser;
      final isCurrentUserEmail = currentUser != null && currentUser.email == _email;
      
      debugPrint('🔍 [VIEWMODEL] ETAPA 1: Verificando email "$_email"...');
      debugPrint('🔍 [VIEWMODEL] ETAPA 1: Usuário autenticado: ${currentUser?.email}');
      debugPrint('🔍 [VIEWMODEL] ETAPA 1: É o email do usuário atual: $isCurrentUserEmail');
      
      if (isCurrentUserEmail) {
        debugPrint('✅ [VIEWMODEL] ETAPA 1: Email é do usuário autenticado, PERMITINDO avanço');
      } else {
        // Validação assíncrona de email usando fetchSignInMethodsForEmail
        debugPrint('🔍 [VIEWMODEL] ETAPA 1: Verificando se email "$_email" já está em uso...');
        final emailInUse = await _authRepository.isEmailInUse(_email);
        debugPrint('🔍 [VIEWMODEL] ETAPA 1: Resultado - Email em uso: $emailInUse');
        
        if (emailInUse) {
          debugPrint('❌ [VIEWMODEL] ETAPA 1: Email já está cadastrado, BLOQUEANDO avanço');
          _setError('Este email já está cadastrado');
          return false;
        }
        debugPrint('✅ [VIEWMODEL] ETAPA 1: Email disponível, prosseguindo...');
      }

      // Validação assíncrona de CNPJ via /cnpj_registry
      debugPrint('🔍 [VIEWMODEL] ETAPA 2: Verificando unicidade do CNPJ "$_cnpj"...');
      final cnpjInUse = await _barRepository.isCnpjInUse(_cnpj);
      debugPrint('🔍 [VIEWMODEL] ETAPA 2: Resultado - CNPJ em uso: $cnpjInUse');
      
      if (cnpjInUse) {
        debugPrint('❌ [VIEWMODEL] ETAPA 2: CNPJ já está cadastrado, BLOQUEANDO avanço');
        _setError('Este CNPJ já está cadastrado');
        return false;
      }
      debugPrint('✅ [VIEWMODEL] ETAPA 2: CNPJ disponível, prosseguindo...');

      debugPrint('✅ [VIEWMODEL] SUCESSO: Email e CNPJ disponíveis, PERMITINDO avanço');
      return true;
    } catch (e) {
      debugPrint('❌ [VIEWMODEL] ERRO CRÍTICO ao verificar email/CNPJ: $e');
      debugPrint('❌ [VIEWMODEL] Stack trace: ${StackTrace.current}');
      _setError('Erro ao verificar dados: $e');
      return false;
    } finally {
      debugPrint('🔍 [VIEWMODEL] validateStep1AndCheckEmail FINALIZADO');
      _setLoading(false);
    }
  }

  void _validateCnpj() {
    // Remove caracteres não numéricos
    final numericValue = _cnpj.replaceAll(RegExp(r'\D'), '');

    if (numericValue.length != 14) {
      _isCnpjValid = false;
      return;
    }

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(numericValue)) {
      _isCnpjValid = false;
      return;
    }

    // Algoritmo de validação do CNPJ
    List<int> numbers = numericValue.split('').map(int.parse).toList();

    // Primeiro dígito verificador
    int sum = 0;
    int weight = 5;

    for (int i = 0; i < 12; i++) {
      sum += numbers[i] * weight;
      weight = weight == 2 ? 9 : weight - 1;
    }

    int digit1 = sum % 11 < 2 ? 0 : 11 - (sum % 11);

    if (numbers[12] != digit1) {
      _isCnpjValid = false;
      return;
    }

    // Segundo dígito verificador
    sum = 0;
    weight = 6;

    for (int i = 0; i < 13; i++) {
      sum += numbers[i] * weight;
      weight = weight == 2 ? 9 : weight - 1;
    }

    int digit2 = sum % 11 < 2 ? 0 : 11 - (sum % 11);

    if (numbers[13] != digit2) {
      _isCnpjValid = false;
      return;
    }

    _isCnpjValid = true;
  }

  void _validateName() {
    _isNameValid = _name.isNotEmpty;
  }

  void _validateResponsibleName() {
    _isResponsibleNameValid = _responsibleName.isNotEmpty;
  }

  void _validatePhone() {
    // Remove caracteres não numéricos
    final numericValue = _phone.replaceAll(RegExp(r'\D'), '');

    // Verifica se o telefone tem entre 10 e 11 dígitos (com DDD)
    if (numericValue.length < 10 || numericValue.length > 11) {
      _isPhoneValid = false;
      return;
    }

    // Valida DDD (11-99)
    if (numericValue.length >= 2) {
      final ddd = int.tryParse(numericValue.substring(0, 2));
      if (ddd == null || ddd < 11 || ddd > 99) {
        _isPhoneValid = false;
        return;
      }
    }

    _isPhoneValid = true;
  }

  // Métodos de validação do Passo 2
  void _validateCep() {
    // Remove caracteres não numéricos
    final numericValue = _cep.replaceAll(RegExp(r'\D'), '');

    _isCepValid = numericValue.length == 8;
  }

  void _validateStreet() {
    _isStreetValid = _street.isNotEmpty;
  }

  void _validateNumber() {
    _isNumberValid = _number.isNotEmpty;
  }

  void _validateState() {
    _isStateValid = _stateUf.isNotEmpty;
  }

  void _validateCity() {
    _isCityValid = _city.isNotEmpty;
  }

  // Métodos de validação do Passo 3
  void _validatePassword() {
    _isPasswordValid = _password.length >= 8;
  }

  void _validateConfirmPassword() {
    _isConfirmPasswordValid =
        _confirmPassword.isNotEmpty && _confirmPassword == _password;
  }

  // Busca o endereço pelo CEP
  Future<void> _searchCep() async {
    debugPrint('🔍 [VIEWMODEL] _searchCep: Iniciando busca de CEP');
    
    if (_cep.isEmpty) {
      debugPrint('❌ [VIEWMODEL] _searchCep: CEP vazio, cancelando busca');
      return;
    }

    // Remove caracteres não numéricos
    final numericCep = _cep.replaceAll(RegExp(r'\D'), '');
    debugPrint('🔍 [VIEWMODEL] _searchCep: CEP formatado: $numericCep');

    if (numericCep.length != 8) {
      debugPrint('❌ [VIEWMODEL] _searchCep: CEP inválido (${numericCep.length} dígitos), cancelando busca');
      return;
    }

    debugPrint('🔍 [VIEWMODEL] _searchCep: Iniciando busca na API ViaCEP para CEP: $numericCep');
    _setLoading(true);

    try {
      final viaCepSearchCep = ViaCepSearchCep();
      final result = await viaCepSearchCep.searchInfoByCep(cep: numericCep);

      result.fold(
        (error) {
          debugPrint('❌ [VIEWMODEL] _searchCep: Erro na API ViaCEP: $error');
        },
        (info) {
          debugPrint('✅ [VIEWMODEL] _searchCep: Sucesso na busca do CEP');
          debugPrint('🔍 [VIEWMODEL] _searchCep: Logradouro: ${info.logradouro}');
          debugPrint('🔍 [VIEWMODEL] _searchCep: UF: ${info.uf}');
          debugPrint('🔍 [VIEWMODEL] _searchCep: Localidade: ${info.localidade}');
          
          // Atualiza os campos de endereço
          setStreet(info.logradouro ?? '');
          setState(info.uf ?? '');
          setCity(info.localidade ?? '');

          debugPrint('✅ [VIEWMODEL] _searchCep: Campos de endereço atualizados com sucesso');
          // Não atualiza o número e complemento para não sobrescrever
          // dados que o usuário possa ter inserido
        }
      );
    } catch (e) {
      debugPrint('❌ [VIEWMODEL] _searchCep: Erro crítico na busca do CEP: $e');
      debugPrint('❌ [VIEWMODEL] _searchCep: Stack trace: ${StackTrace.current}');
    } finally {
      debugPrint('🔍 [VIEWMODEL] _searchCep: Finalizando busca de CEP');
      _setLoading(false);
    }
  }

  // Cria bar para usuários de login social (apenas Passo 1 e 2)
  Future<void> createBarFromSocialLogin() async {
    if (!isStep1Valid || !isStep2Valid) {
      throw Exception('Dados incompletos para criar bar');
    }

    _setLoading(true);
    _clearError();

    try {
      // Obtém o usuário atual (já autenticado via social)
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Cria o bar no Firestore com perfil completo
      // Como o usuário completou Passo 1 e 2, marca as flags como true
      final bar = BarModel.empty().copyWith(
        contactEmail: _email,
        cnpj: _cnpj,
        name: _name,
        responsibleName: _responsibleName,
        contactPhone: _phone,
        address: BarAddress(
          cep: _cep,
          street: _street,
          number: _number,
          complement: _complement,
          state: _stateUf,
          city: _city,
        ),
        profile: BarProfile(
          contactsComplete: true, // Passo 1 completo
          addressComplete: true,  // Passo 2 completo
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUid: currentUser.uid,
        primaryOwnerUid: currentUser.uid,
      );

      // Cria o bar com operação atômica (reserva CNPJ + bar + membership OWNER)
      final barId = await _barRepository.createBarWithReservation(
        bar: bar,
        ownerUid: currentUser.uid,
      );

      // Atualiza o UserProfile com currentBarId
      // Mantém completedFullRegistration = false pois veio de login social
      final existingProfile = await _userRepository.getMe();
      if (existingProfile != null) {
        final updatedProfile = existingProfile.copyWith(
          currentBarId: barId,
        );
        await _userRepository.upsert(updatedProfile);
      }

      // Debug log conforme especificado
      debugPrint('🎉 DEBUG Login Social: Bar criado com sucesso para usuário ${currentUser.uid}');
      debugPrint('🎉 DEBUG Login Social: Profile completo - contactsComplete=true, addressComplete=true');
      debugPrint('🎉 DEBUG Login Social: UserProfile atualizado com currentBarId=$barId');

      // Limpa os rascunhos após sucesso
      await clearDrafts();

      ToastService.instance.showSuccess(message: 'Bar cadastrado com sucesso!');
      _setRegistrationState(RegistrationState.success);
    } catch (e) {
      debugPrint('❌ [BarRegistrationViewModel] Erro durante o registro: $e');
      debugPrint('❌ [BarRegistrationViewModel] Stack trace: ${StackTrace.current}');
      _setError(e.toString());
      rethrow;
    } finally {
      debugPrint('🔄 [BarRegistrationViewModel] Finalizando registerBarAndUser - definindo loading = false');
      _setLoading(false);
    }
  }

  // Registra o bar e o usuário
  Future<void> registerBarAndUser() async {
    debugPrint('🚀 [BarRegistrationViewModel] Iniciando registerBarAndUser...');
    debugPrint('🚀 [BarRegistrationViewModel] Step3 válido: $isStep3Valid');
    
    if (!isStep3Valid) {
      debugPrint('❌ [BarRegistrationViewModel] Step3 inválido, cancelando registro');
      return;
    }

    debugPrint('🔄 [BarRegistrationViewModel] Definindo loading = true');
    _setLoading(true);
    _clearError();

    try {
      // Cria o usuário no Firebase Auth
      final displayName = _responsibleName;
      debugPrint('👤 [BarRegistrationViewModel] Criando usuário no Firebase Auth...');
      debugPrint('👤 [BarRegistrationViewModel] Email: ${_email.substring(0, 3)}***');
      debugPrint('👤 [BarRegistrationViewModel] DisplayName: $displayName');
      
      final authResult = await _authRepository.signUpWithEmail(
        _email,
        _password,
        displayName: displayName,
      );

      if (!authResult.isSuccess) {
        debugPrint('❌ [BarRegistrationViewModel] Falha na criação do usuário: ${authResult.errorMessage}');
        _setError(authResult.errorMessage ?? 'Erro ao criar usuário');
        return;
      }
      
      debugPrint('✅ [BarRegistrationViewModel] Usuário criado com sucesso no Firebase Auth!');

      // Obtém o UID do usuário recém-criado
      debugPrint('🔍 [BarRegistrationViewModel] Obtendo UID do usuário recém-criado...');
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [BarRegistrationViewModel] Erro: usuário não encontrado após criação');
        throw Exception('Erro ao obter ID do usuário');
      }
      debugPrint('✅ [BarRegistrationViewModel] UID obtido: ${currentUser.uid}');

      // Cria o bar no Firestore com perfil completo
      // Como o usuário passou por todos os passos (1, 2 e 3), marca as flags como true
      debugPrint('🏢 [BarRegistrationViewModel] Criando modelo do bar...');
      final bar = BarModel.empty().copyWith(
        contactEmail: _email,
        cnpj: _cnpj,
        name: _name,
        responsibleName: _responsibleName,
        contactPhone: _phone,
        address: BarAddress(
          cep: _cep,
          street: _street,
          number: _number,
          complement: _complement,
          state: _stateUf,
          city: _city,
        ),
        profile: BarProfile(
          contactsComplete: true, // Passo 1 completo
          addressComplete: true,  // Passo 2 completo
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUid: currentUser.uid,
        primaryOwnerUid: currentUser.uid, // Campo obrigatório para as regras do Firestore
      );

      // Cria o bar com operação atômica (reserva CNPJ + bar + membership OWNER)
      debugPrint('💾 [BarRegistrationViewModel] Criando bar no Firestore com operação atômica...');
      debugPrint('💾 [BarRegistrationViewModel] CNPJ: ${_cnpj.substring(0, 5)}***');
      debugPrint('💾 [BarRegistrationViewModel] Nome do bar: $_name');
      
      final barId = await _barRepository.createBarWithReservation(
        bar: bar,
        ownerUid: currentUser.uid,
      );
      
      debugPrint('✅ [BarRegistrationViewModel] Bar criado com sucesso! ID: $barId');

      // Cria o UserProfile com completedFullRegistration = true e currentBarId
      // Como o usuário passou por todos os passos (1, 2 e 3), marca a flag como true
      debugPrint('👤 [BarRegistrationViewModel] Criando perfil do usuário...');
      final userProfile = UserProfile(
        uid: currentUser.uid,
        email: _email,
        displayName: _responsibleName,
        photoUrl: null,
        providers: ['email'], // Cadastro via email/senha
        currentBarId: barId, // Define o bar recém-criado como atual
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        completedFullRegistration: true, // Usuário completou cadastro completo
      );

      debugPrint('💾 [BarRegistrationViewModel] Salvando perfil do usuário no Firestore...');
      await _userRepository.upsert(userProfile);
      debugPrint('✅ [BarRegistrationViewModel] Perfil do usuário salvo com sucesso!');

      // Debug log conforme especificado
      debugPrint('🎉 DEBUG Cadastro finalizado: Bar criado com sucesso para usuário ${currentUser.uid}');
      debugPrint('🎉 DEBUG Cadastro finalizado: Profile completo - contactsComplete=true, addressComplete=true');
      debugPrint('🎉 DEBUG Cadastro finalizado: UserProfile criado com completedFullRegistration=true');

      // Limpa os rascunhos após sucesso
      debugPrint('🧹 [BarRegistrationViewModel] Limpando rascunhos...');
      await clearDrafts();
      debugPrint('✅ [BarRegistrationViewModel] Rascunhos limpos com sucesso!');
      
      debugPrint('🎉 [BarRegistrationViewModel] Registro completo finalizado com sucesso!');

      _setRegistrationState(RegistrationState.success);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos auxiliares para gerenciar o estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRegistrationState(RegistrationState state) {
    _registrationState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _registrationState = RegistrationState.error;
    ToastService.instance.showError(message: message);
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Métodos para salvar rascunhos
   void _saveDraftStep1() {
     DraftStorage.saveStep1Draft(
       email: _email,
       cnpj: _cnpj,
       name: _name,
       responsibleName: _responsibleName,
       phone: _phone,
     );
   }

  /// Salva o rascunho do Passo 1 (método público)
  void saveDraftStep1() {
    _saveDraftStep1();
  }

  /// Salva o Passo 1 e atualiza a completude do perfil
  Future<void> saveStep1(String barId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Salva o rascunho
      _saveDraftStep1();
      
      // Atualiza a completude do perfil
      await _updateContactsCompleteness(barId);
      
      // Debug log conforme especificado
      debugPrint('📝 DEBUG Passo 1: profile.contactsComplete = $isStep1Valid para barId = $barId');
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
 
   void _saveDraftStep2() {
     DraftStorage.saveStep2Draft(
       cep: _cep,
       street: _street,
       number: _number,
       complement: _complement,
       state: _stateUf,
       city: _city,
     );
   }

  /// Salva o rascunho do Passo 2 (método público)
  void saveDraftStep2() {
    _saveDraftStep2();
  }

  /// Salva o Passo 2 e atualiza a completude do perfil
  Future<void> saveStep2(String barId) async {
    debugPrint('🔍 [VIEWMODEL] saveStep2: Iniciando salvamento do Passo 2');
    debugPrint('🔍 [VIEWMODEL] saveStep2: barId = $barId');
    debugPrint('🔍 [VIEWMODEL] saveStep2: isStep2Valid = $isStep2Valid');
    
    try {
      debugPrint('🔍 [VIEWMODEL] saveStep2: Definindo loading = true');
      _setLoading(true);
      _clearError();
      
      debugPrint('🔍 [VIEWMODEL] saveStep2: Salvando rascunho do Passo 2');
      // Salva o rascunho
      _saveDraftStep2();
      
      debugPrint('🔍 [VIEWMODEL] saveStep2: Atualizando completude do endereço no Firestore');
      // Atualiza a completude do perfil
      await _updateAddressCompleteness(barId);
      
      debugPrint('✅ [VIEWMODEL] saveStep2: Passo 2 salvo com sucesso');
      // Debug log conforme especificado
      debugPrint('📝 DEBUG Passo 2: profile.addressComplete = $isStep2Valid para barId = $barId');
    } catch (e) {
      debugPrint('❌ [VIEWMODEL] saveStep2: Erro ao salvar Passo 2: $e');
      debugPrint('❌ [VIEWMODEL] saveStep2: Stack trace: ${StackTrace.current}');
      _setError(e.toString());
      rethrow;
    } finally {
      debugPrint('🔍 [VIEWMODEL] saveStep2: Finalizando salvamento (loading = false)');
      _setLoading(false);
    }
  }
 
   void _saveDraftStep3() {
     // Senhas não são salvas em rascunho por questões de segurança
     // O Step3 não possui persistência de rascunho
   }

  // Métodos para carregar rascunhos
   Future<void> loadDrafts() async {
     await _loadDraftStep1();
     await _loadDraftStep2();
     // Step3 não possui rascunho (senhas não são persistidas)
     
     // Se o email ainda estiver vazio após carregar rascunhos,
     // preenche com o email do usuário autenticado (login social)
     await _initializeEmailFromCurrentUser();
     
     notifyListeners();
   }
   
   /// Inicializa o email com dados do usuário autenticado se estiver vazio
   Future<void> _initializeEmailFromCurrentUser() async {
     if (_email.isEmpty) {
       final currentUser = _authRepository.currentUser;
       if (currentUser != null && currentUser.email != null && currentUser.email!.isNotEmpty) {
         debugPrint('🔄 [BarRegistrationViewModel] Preenchendo email automaticamente: ${currentUser.email}');
         _email = currentUser.email!;
         _validateEmail();
         // Não salva no rascunho ainda, apenas preenche o campo
       }
     }
   }
 
   Future<void> _loadDraftStep1() async {
     debugPrint('🔍 [VIEWMODEL] _loadDraftStep1: Carregando rascunho do Passo 1');
     
     final draft = await DraftStorage.readStep1Draft();
     if (draft != null) {
       debugPrint('✅ [VIEWMODEL] _loadDraftStep1: Rascunho encontrado, carregando dados');
       
       _email = draft['email'] ?? '';
       _cnpj = draft['cnpj'] ?? '';
       _name = draft['name'] ?? '';
       _responsibleName = draft['responsibleName'] ?? '';
       _phone = draft['phone'] ?? '';
 
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep1: Email carregado: ${_email.isNotEmpty ? "${_email.substring(0, 3)}***" : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep1: CNPJ carregado: ${_cnpj.isNotEmpty ? "${_cnpj.substring(0, 3)}***" : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep1: Nome carregado: ${_name.isNotEmpty ? _name : "(vazio)"}');
       
       // Valida os campos carregados
       _validateEmail();
       _validateCnpj();
       _validateName();
       _validateResponsibleName();
       _validatePhone();
       
       debugPrint('✅ [VIEWMODEL] _loadDraftStep1: Rascunho carregado e validado com sucesso');
     } else {
       debugPrint('ℹ️ [VIEWMODEL] _loadDraftStep1: Nenhum rascunho encontrado');
     }
   }
 
   Future<void> _loadDraftStep2() async {
     debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: Carregando rascunho do Passo 2');
     
     final draft = await DraftStorage.readStep2Draft();
     if (draft != null) {
       debugPrint('✅ [VIEWMODEL] _loadDraftStep2: Rascunho encontrado, carregando dados');
       
       _cep = draft['cep'] ?? '';
       _street = draft['street'] ?? '';
       _number = draft['number'] ?? '';
       _complement = draft['complement'] ?? '';
       _stateUf = draft['state'] ?? '';
       _city = draft['city'] ?? '';
 
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: CEP carregado: ${_cep.isNotEmpty ? _cep : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: Rua carregada: ${_street.isNotEmpty ? _street : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: Número carregado: ${_number.isNotEmpty ? _number : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: Estado carregado: ${_stateUf.isNotEmpty ? _stateUf : "(vazio)"}');
       debugPrint('🔍 [VIEWMODEL] _loadDraftStep2: Cidade carregada: ${_city.isNotEmpty ? _city : "(vazio)"}');
       
       // Valida os campos carregados
       _validateCep();
       _validateStreet();
       _validateNumber();
       _validateState();
       _validateCity();
       
       debugPrint('✅ [VIEWMODEL] _loadDraftStep2: Rascunho carregado e validado com sucesso');
     } else {
       debugPrint('ℹ️ [VIEWMODEL] _loadDraftStep2: Nenhum rascunho encontrado');
     }
   }
 
   // Step3 não possui carregamento de rascunho
   // Senhas não são persistidas por questões de segurança
 
   // Limpa todos os rascunhos
    Future<void> clearDrafts() async {
      await DraftStorage.clearAllDrafts();
    }

    // Atualiza apenas a completude de contatos
    Future<void> _updateContactsCompleteness(String barId) async {
      try {
        // Busca o bar atual para manter outros dados
        final bars = await _barRepository.listMyBars(_authRepository.currentUser!.uid).first;
        final currentBar = bars.firstWhere((bar) => bar.id == barId);
        
        // Atualiza apenas a flag de contatos
        final updatedBar = currentBar.copyWith(
          profile: currentBar.profile.copyWith(
            contactsComplete: isStep1Valid,
          ),
        );
        
        await _barRepository.update(updatedBar);
      } catch (e) {
        debugPrint('Erro ao atualizar completude de contatos: $e');
        rethrow;
      }
    }

    // Atualiza apenas a completude de endereço
    Future<void> _updateAddressCompleteness(String barId) async {
      try {
        // Busca o bar atual para manter outros dados
        final bars = await _barRepository.listMyBars(_authRepository.currentUser!.uid).first;
        final currentBar = bars.firstWhere((bar) => bar.id == barId);
        
        // Atualiza apenas a flag de endereço
        final updatedBar = currentBar.copyWith(
          profile: currentBar.profile.copyWith(
            addressComplete: isStep2Valid,
          ),
        );
        
        await _barRepository.update(updatedBar);
      } catch (e) {
        debugPrint('Erro ao atualizar completude de endereço: $e');
        rethrow;
      }
    }

    // Atualiza os campos de completude do perfil (ambos)
    Future<void> _updateProfileCompleteness(String barId) async {
      try {
        // Busca o bar atual para manter outros dados
        final bars = await _barRepository.listMyBars(_authRepository.currentUser!.uid).first;
        final currentBar = bars.firstWhere((bar) => bar.id == barId);
        
        // Atualiza ambas as flags
        final updatedBar = currentBar.copyWith(
          profile: currentBar.profile.copyWith(
            contactsComplete: isStep1Valid,
            addressComplete: isStep2Valid,
          ),
        );
        
        await _barRepository.update(updatedBar);
      } catch (e) {
        debugPrint('Erro ao atualizar completude do perfil: $e');
        rethrow;
      }
    }

    // Método público para atualizar completude após edição de perfil
    Future<void> updateProfileCompleteness(String barId) async {
      await _updateProfileCompleteness(barId);
    }

  // Reseta o ViewModel para o estado inicial
  void reset() {
    _registrationState = RegistrationState.initial;
    _errorMessage = null;
    _isLoading = false;

    // Reseta os dados do Passo 1
    _email = '';
    _cnpj = '';
    _name = '';
    _responsibleName = '';
    _phone = '';

    // Reseta a validação do Passo 1
    _isEmailValid = false;
    _isCnpjValid = false;
    _isNameValid = false;
    _isResponsibleNameValid = false;
    _isPhoneValid = false;

    // Reseta os dados do Passo 2
    _cep = '';
    _street = '';
    _number = '';
    _complement = '';
    _stateUf = '';
    _city = '';

    // Reseta a validação do Passo 2
    _isCepValid = false;
    _isStreetValid = false;
    _isNumberValid = false;
    _isStateValid = false;
    _isCityValid = false;

    // Reseta os dados do Passo 3
    _password = '';
    _confirmPassword = '';

    // Reseta a validação do Passo 3
    _isPasswordValid = false;
    _isConfirmPasswordValid = false;

    notifyListeners();
  }

  /// Finaliza o cadastro para usuários de login social no Step 3
  Future<void> finalizeSocialLoginRegistration() async {
    debugPrint('🚀 [BarRegistrationViewModel] Iniciando finalizeSocialLoginRegistration...');
    debugPrint('🚀 [BarRegistrationViewModel] Step3 válido: $isStep3Valid');
    
    if (!isStep3Valid) {
      debugPrint('❌ [BarRegistrationViewModel] Step3 inválido, cancelando registro');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Obtém o usuário atual (já autenticado via social)
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Vincula credencial de email/senha ao usuário de login social
      debugPrint('🔗 [BarRegistrationViewModel] Vinculando credencial de email/senha...');
      await _authRepository.linkEmailPassword(_email, _password);
      debugPrint('✅ [BarRegistrationViewModel] Credencial de email/senha vinculada com sucesso!');
      
      // Recarrega os dados do usuário para atualizar os provedores
      debugPrint('🔄 [BarRegistrationViewModel] Recarregando dados do usuário...');
      await FirebaseAuth.instance.currentUser?.reload();
      debugPrint('✅ [BarRegistrationViewModel] Dados do usuário recarregados!');

      // Cria o bar no Firestore com perfil completo
      // Como o usuário completou todos os 3 passos, marca todas as flags como true
      final bar = BarModel.empty().copyWith(
        contactEmail: _email,
        cnpj: _cnpj,
        name: _name,
        responsibleName: _responsibleName,
        contactPhone: _phone,
        address: BarAddress(
          cep: _cep,
          street: _street,
          number: _number,
          complement: _complement,
          state: _stateUf,
          city: _city,
        ),
        profile: BarProfile(
          contactsComplete: true, // Passo 1 completo
          addressComplete: true,  // Passo 2 completo
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByUid: currentUser.uid,
        primaryOwnerUid: currentUser.uid,
      );

      // Cria o bar com operação atômica (reserva CNPJ + bar + membership OWNER)
      final barId = await _barRepository.createBarWithReservation(
        bar: bar,
        ownerUid: currentUser.uid,
      );

      // Atualiza o UserProfile com currentBarId e marca como completedFullRegistration = true
      final existingProfile = await _userRepository.getMe();
      if (existingProfile != null) {
        final updatedProfile = existingProfile.copyWith(
          currentBarId: barId,
          completedFullRegistration: true, // Marca como completo após Step 3
        );
        await _userRepository.upsert(updatedProfile);
      }

      // Debug log conforme especificado
      debugPrint('🎉 DEBUG Login Social Step 3: Bar criado com sucesso para usuário ${currentUser.uid}');
      debugPrint('🎉 DEBUG Login Social Step 3: Profile completo - contactsComplete=true, addressComplete=true, passwordComplete=true');
      debugPrint('🎉 DEBUG Login Social Step 3: UserProfile atualizado com currentBarId=$barId e completedFullRegistration=true');

      // Limpa os rascunhos após sucesso
      await clearDrafts();

      ToastService.instance.showSuccess(message: 'Cadastro finalizado com sucesso!');
      _setRegistrationState(RegistrationState.success);
    } catch (e) {
      debugPrint('❌ [BarRegistrationViewModel] Erro durante o registro social step 3: $e');
      debugPrint('❌ [BarRegistrationViewModel] Stack trace: ${StackTrace.current}');
      _setError(e.toString());
      rethrow;
    } finally {
      debugPrint('🔄 [BarRegistrationViewModel] Finalizando finalizeSocialLoginRegistration - definindo loading = false');
      _setLoading(false);
    }
  }
}
