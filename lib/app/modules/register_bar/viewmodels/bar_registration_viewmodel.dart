import 'package:flutter/foundation.dart';
import 'package:search_cep/search_cep.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:bar_boss_mobile/app/core/utils/normalization_helpers.dart';

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

  // Estados de validação de unicidade
  bool _isValidatingUniqueness = false;
  String? _uniquenessError;
  bool _emailUnique = true;
  bool _cnpjUnique = true;

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

  // Getters para validação de unicidade
  bool get isValidatingUniqueness => _isValidatingUniqueness;
  String? get uniquenessError => _uniquenessError;
  bool get emailUnique => _emailUnique;
  bool get cnpjUnique => _cnpjUnique;
  bool get hasUniquenessError => _uniquenessError != null;
  bool get canProceedToStep2 => isStep1Valid && _emailUnique && _cnpjUnique && !_isValidatingUniqueness;

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
    notifyListeners();
  }

  void setCnpj(String value) {
    _cnpj = value;
    _validateCnpj();
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    _validateName();
    notifyListeners();
  }

  void setResponsibleName(String value) {
    _responsibleName = value;
    _validateResponsibleName();
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    _validatePhone();
    notifyListeners();
  }

  // Setters para os dados do Passo 2
  void setCep(String value) {
    _cep = value;
    _validateCep();
    notifyListeners();

    // Se o CEP for válido, busca o endereço
    if (_isCepValid) {
      _searchCep();
    }
  }

  void setStreet(String value) {
    _street = value;
    _validateStreet();
    notifyListeners();
  }

  void setNumber(String value) {
    _number = value;
    _validateNumber();
    notifyListeners();
  }

  void setComplement(String value) {
    _complement = value;
    notifyListeners();
  }

  void setState(String value) {
    _stateUf = value;
    _validateState();
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    _validateCity();
    notifyListeners();
  }

  // Setters para os dados do Passo 3
  void setPassword(String value) {
    _password = value;
    _validatePassword();
    _validateConfirmPassword(); // Valida novamente a confirmação de senha
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _validateConfirmPassword();
    notifyListeners();
  }

  // Métodos de validação do Passo 1
  void _validateEmail() {
    _isEmailValid =
        _email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);
  }

  /// Valida os dados do Passo 1 (apenas formato, sem verificar duplicatas)
  bool validateStep1Format() {
    debugPrint('🔍 [VIEWMODEL] Validando formato dos dados do Passo 1...');
    
    // Validações básicas de formato
    if (!isEmailValid) {
      _setError('Email inválido');
      return false;
    }
    
    if (!isCnpjValid) {
      _setError('CNPJ inválido');
      return false;
    }
    
    if (!isPhoneValid) {
      _setError('Telefone inválido');
      return false;
    }
    
    if (_name.trim().isEmpty) {
      _setError('Nome do bar é obrigatório');
      return false;
    }
    
    if (_responsibleName.trim().isEmpty) {
      _setError('Nome do responsável é obrigatório');
      return false;
    }
    
    debugPrint('✅ [VIEWMODEL] Validação de formato do Passo 1 aprovada');
    _clearError();
    return true;
  }

  /// Valida unicidade de email e CNPJ no Step1 (Fluxo A/B)
  Future<bool> validateStep1Uniqueness() async {
    debugPrint('🔍 [VIEWMODEL] Iniciando validação de unicidade...');
    
    // Primeiro valida formato
    if (!validateStep1Format()) {
      debugPrint('❌ [VIEWMODEL] Formato inválido, cancelando validação de unicidade');
      return false;
    }

    _setValidatingUniqueness(true);
    _clearUniquenessError();

    try {
      // Normaliza os dados
      final normalizedEmail = NormalizationHelpers.normalizeEmail(_email);
      final normalizedCnpj = NormalizationHelpers.normalizeCnpj(_cnpj);

      debugPrint('🔍 [VIEWMODEL] Verificando unicidade para email: $normalizedEmail, CNPJ: $normalizedCnpj');

      // Verifica unicidade em paralelo
      final results = await Future.wait([
        _barRepository.isEmailUnique(normalizedEmail),
        _barRepository.isCnpjUnique(normalizedCnpj),
      ]);

      final emailUnique = results[0];
      final cnpjUnique = results[1];

      _emailUnique = emailUnique;
      _cnpjUnique = cnpjUnique;

      // Determina o erro específico
      if (!emailUnique && !cnpjUnique) {
        _setUniquenessError('Email e CNPJ já estão em uso');
        debugPrint('❌ [VIEWMODEL] Email e CNPJ já estão em uso');
        return false;
      } else if (!emailUnique) {
        _setUniquenessError('Email já está em uso');
        debugPrint('❌ [VIEWMODEL] Email já está em uso');
        return false;
      } else if (!cnpjUnique) {
        _setUniquenessError('CNPJ já está em uso');
        debugPrint('❌ [VIEWMODEL] CNPJ já está em uso');
        return false;
      }

      debugPrint('✅ [VIEWMODEL] Validação de unicidade aprovada');
      return true;

    } catch (e) {
      debugPrint('❌ [VIEWMODEL] Erro na validação de unicidade: $e');
      _setUniquenessError('Erro ao verificar dados. Tente novamente.');
      return false;
    } finally {
      _setValidatingUniqueness(false);
    }
  }

  /// Limpa erros de unicidade quando o usuário edita os campos
  void clearUniquenessValidation() {
    _emailUnique = true;
    _cnpjUnique = true;
    _clearUniquenessError();
    notifyListeners();
  }

  // Métodos auxiliares para controle de estado
  void _setValidatingUniqueness(bool value) {
    _isValidatingUniqueness = value;
    notifyListeners();
  }

  void _setUniquenessError(String error) {
    _uniquenessError = error;
    notifyListeners();
  }

  void _clearUniquenessError() {
    _uniquenessError = null;
    notifyListeners();
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
    
    try {
      debugPrint('🔄 [BarRegistrationViewModel] Definindo loading = true');
      _setLoading(true);
      _clearError();

      // Validar formato do Passo 1
      debugPrint('🔍 [BarRegistrationViewModel] Validando formato do Step 1...');
      if (!validateStep1Format()) {
        debugPrint('❌ [BarRegistrationViewModel] Step 1 inválido');
        return;
      }
      
      // Validar Passo 2
      if (!isStep2Valid) {
        debugPrint('❌ [BarRegistrationViewModel] Passo 2 inválido');
        _setError('Dados de endereço incompletos ou inválidos');
        return;
      }
      
      // Validar Passo 3 (senhas)
      if (!isStep3Valid) {
        debugPrint('❌ [BarRegistrationViewModel] Step3 inválido, cancelando registro');
        _setError('Senhas não conferem ou são muito fracas');
        return;
      }
      
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



  /// Salva o Passo 1 e atualiza a completude do perfil
  Future<void> saveStep1(String barId) async {
    try {
      _setLoading(true);
      _clearError();
      
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
 


  /// Salva o Passo 2 e atualiza a completude do perfil
  Future<void> saveStep2(String barId) async {
    debugPrint('🔍 [VIEWMODEL] saveStep2: Iniciando salvamento do Passo 2');
    debugPrint('🔍 [VIEWMODEL] saveStep2: barId = $barId');
    debugPrint('🔍 [VIEWMODEL] saveStep2: isStep2Valid = $isStep2Valid');
    
    try {
      debugPrint('🔍 [VIEWMODEL] saveStep2: Definindo loading = true');
      _setLoading(true);
      _clearError();
      
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

  /// Verifica se o usuário já tem provedor de senha configurado
  Future<bool> hasPasswordProvider() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return false;
    
    // Recarrega os dados do usuário para garantir informações atualizadas
    await firebaseUser.reload();
    
    // Verifica novamente após o reload
    final updatedUser = FirebaseAuth.instance.currentUser;
    if (updatedUser == null) return false;
    
    return updatedUser.providerData.any((provider) => provider.providerId == 'password');
  }

  /// Finaliza o cadastro para usuários de login social (sem Step 3 se já tem senha)
  Future<void> finalizeSocialLoginRegistrationWithoutPassword() async {
    debugPrint('🚀 [BarRegistrationViewModel] Iniciando finalizeSocialLoginRegistrationWithoutPassword...');
    
    _setLoading(true);
    _clearError();

    try {
      // Obtém o usuário atual (já autenticado via social)
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('ℹ️ [BarRegistrationViewModel] Usuário já possui senha configurada, pulando vinculação...');
      
      // Recarrega os dados do usuário para atualizar os provedores
      debugPrint('🔄 [BarRegistrationViewModel] Recarregando dados do usuário...');
      await FirebaseAuth.instance.currentUser?.reload();
      debugPrint('✅ [BarRegistrationViewModel] Dados do usuário recarregados!');

      // Cria o bar no Firestore com perfil completo
      // Como o usuário completou todos os passos (senha já existia), marca todas as flags como true
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
          completedFullRegistration: true, // Marca como completo após Step 2 (senha já existia)
        );
        await _userRepository.upsert(updatedProfile);
      }

      // Debug log conforme especificado
      debugPrint('🎉 DEBUG Login Social Step 2: Bar criado com sucesso para usuário ${currentUser.uid}');
      debugPrint('🎉 DEBUG Login Social Step 2: Profile completo - contactsComplete=true, addressComplete=true, passwordComplete=true (senha já existia)');
      debugPrint('🎉 DEBUG Login Social Step 2: UserProfile atualizado com currentBarId=$barId e completedFullRegistration=true');

      ToastService.instance.showSuccess(message: 'Cadastro finalizado com sucesso!');
      _setRegistrationState(RegistrationState.success);
      
    } catch (e) {
      debugPrint('❌ [BarRegistrationViewModel] Erro durante o registro social step 2: $e');
      debugPrint('❌ [BarRegistrationViewModel] Stack trace: ${StackTrace.current}');
      _setError(e.toString());
      rethrow;
    } finally {
      debugPrint('🔄 [BarRegistrationViewModel] Finalizando finalizeSocialLoginRegistrationWithoutPassword - definindo loading = false');
      _setLoading(false);
    }
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

      // Verifica se o usuário já tem provedor de email/senha vinculado
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final hasEmailProvider = firebaseUser?.providerData
          .any((provider) => provider.providerId == 'password') ?? false;
      
      if (!hasEmailProvider) {
        // Vincula credencial de email/senha ao usuário de login social
        debugPrint('🔗 [BarRegistrationViewModel] Vinculando credencial de email/senha...');
        await _authRepository.linkEmailPassword(_email, _password);
        debugPrint('✅ [BarRegistrationViewModel] Credencial de email/senha vinculada com sucesso!');
      } else {
        debugPrint('ℹ️ [BarRegistrationViewModel] Usuário já possui provedor de email/senha vinculado, pulando vinculação...');
      }
      
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
