import 'package:flutter/foundation.dart';
import 'package:search_cep/search_cep.dart';

import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/storage/draft_storage.dart';

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

  /// Valida o Passo 1 e verifica se o e-mail já está em uso
  /// Retorna true se tudo estiver válido e o e-mail não estiver em uso
  Future<bool> validateStep1AndCheckEmail() async {
    debugPrint('🔍 [DEBUG] validateStep1AndCheckEmail chamado para email: $_email');
    
    if (!isStep1Valid) {
      debugPrint('❌ [DEBUG] Step 1 inválido');
      _setError('Preencha todos os campos obrigatórios');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔍 [DEBUG] Verificando se email $_email já está em uso...');
      // Verifica se o email já está em uso
      final emailInUse = await _authRepository.isEmailInUse(_email);
      debugPrint('🔍 [DEBUG] Email em uso: $emailInUse');
      
      if (emailInUse) {
        debugPrint('❌ [DEBUG] Email já está cadastrado, bloqueando avanço');
        _setError('Este email já está cadastrado');
        return false;
      }

      debugPrint('✅ [DEBUG] Email disponível, permitindo avanço');
      return true;
    } catch (e) {
      debugPrint('❌ [DEBUG] Erro ao verificar email: $e');
      _setError('Erro ao verificar e-mail: $e');
      return false;
    } finally {
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
    _isPhoneValid = numericValue.length >= 10 && numericValue.length <= 11;
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
    if (_cep.isEmpty) return;

    // Remove caracteres não numéricos
    final numericCep = _cep.replaceAll(RegExp(r'\D'), '');

    if (numericCep.length != 8) return;

    _setLoading(true);

    try {
      final viaCepSearchCep = ViaCepSearchCep();
      final result = await viaCepSearchCep.searchInfoByCep(cep: numericCep);

      result.fold((error) => debugPrint('Erro ao buscar CEP: $error'), (info) {
        // Atualiza os campos de endereço
        setStreet(info.logradouro ?? '');
        setState(info.uf ?? '');
        setCity(info.localidade ?? '');

        // Não atualiza o número e complemento para não sobrescrever
        // dados que o usuário possa ter inserido
      });
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Registra o bar e o usuário
  Future<void> registerBarAndUser() async {
    if (!isStep3Valid) return;

    _setLoading(true);
    _clearError();

    try {
      // Cria o usuário no Firebase Auth
      final displayName = _responsibleName;
      final authResult = await _authRepository.signUpWithEmail(
        _email,
        _password,
        displayName: displayName,
      );

      if (!authResult.isSuccess) {
        _setError(authResult.errorMessage ?? 'Erro ao criar usuário');
        return;
      }

      // Obtém o UID do usuário recém-criado
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Erro ao obter ID do usuário');
      }

      // Cria o bar no Firestore com perfil completo
      // Como o usuário passou por todos os passos (1, 2 e 3), marca as flags como true
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
      );

      await _barRepository.create(bar);

      // Cria o UserProfile com completedFullRegistration = true
      // Como o usuário passou por todos os passos (1, 2 e 3), marca a flag como true
      final userProfile = UserProfile(
        uid: currentUser.uid,
        email: _email,
        displayName: _responsibleName,
        photoUrl: null,
        providers: ['email'], // Cadastro via email/senha
        currentBarId: null, // Será atualizado pelo repositório do bar
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        completedFullRegistration: true, // Usuário completou cadastro completo
      );

      await _userRepository.upsert(userProfile);

      // Debug log conforme especificado
      debugPrint('🎉 DEBUG Cadastro finalizado: Bar criado com sucesso para usuário ${currentUser.uid}');
      debugPrint('🎉 DEBUG Cadastro finalizado: Profile completo - contactsComplete=true, addressComplete=true');
      debugPrint('🎉 DEBUG Cadastro finalizado: UserProfile criado com completedFullRegistration=true');

      // Limpa os rascunhos após sucesso
      await clearDrafts();

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

  /// Salva o Passo 2 e atualiza a completude do perfil
  Future<void> saveStep2(String barId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Salva o rascunho
      _saveDraftStep2();
      
      // Atualiza a completude do perfil
      await _updateAddressCompleteness(barId);
      
      // Debug log conforme especificado
      debugPrint('📝 DEBUG Passo 2: profile.addressComplete = $isStep2Valid para barId = $barId');
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
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
     notifyListeners();
   }
 
   Future<void> _loadDraftStep1() async {
     final draft = await DraftStorage.readStep1Draft();
     if (draft != null) {
       _email = draft['email'] ?? '';
       _cnpj = draft['cnpj'] ?? '';
       _name = draft['name'] ?? '';
       _responsibleName = draft['responsibleName'] ?? '';
       _phone = draft['phone'] ?? '';
 
       // Valida os campos carregados
       _validateEmail();
       _validateCnpj();
       _validateName();
       _validateResponsibleName();
       _validatePhone();
     }
   }
 
   Future<void> _loadDraftStep2() async {
     final draft = await DraftStorage.readStep2Draft();
     if (draft != null) {
       _cep = draft['cep'] ?? '';
       _street = draft['street'] ?? '';
       _number = draft['number'] ?? '';
       _complement = draft['complement'] ?? '';
       _stateUf = draft['state'] ?? '';
       _city = draft['city'] ?? '';
 
       // Valida os campos carregados
       _validateCep();
       _validateStreet();
       _validateNumber();
       _validateState();
       _validateCity();
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
}
