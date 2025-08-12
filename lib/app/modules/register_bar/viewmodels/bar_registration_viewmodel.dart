import 'package:flutter/foundation.dart';
import 'package:search_cep/search_cep.dart';

import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/modules/auth/services/auth_service.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/repositories/bar_repository.dart';

/// Estados possíveis do cadastro de bar
enum RegistrationState {
  initial,
  loading,
  success,
  error,
}

/// ViewModel para o cadastro de bar
class BarRegistrationViewModel extends ChangeNotifier {
  final BarRepository _barRepository;
  
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
    required BarRepository barRepository,
  }) : _barRepository = barRepository;
  
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
    _isEmailValid = _email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);
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
    _isConfirmPasswordValid = _confirmPassword.isNotEmpty && _confirmPassword == _password;
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
      
      result.fold(
        (error) => debugPrint('Erro ao buscar CEP: $error'),
        (info) {
          // Atualiza os campos de endereço
          setStreet(info.logradouro ?? '');
          setState(info.uf ?? '');
          setCity(info.localidade ?? '');
          
          // Não atualiza o número e complemento para não sobrescrever
          // dados que o usuário possa ter inserido
        },
      );
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
      // Verifica se o e-mail já está em uso no Clerk
      final isEmailInUse = await AuthService.isEmailInUse(_email);
      if (isEmailInUse) {
        _setError(AppStrings.emailInUseErrorMessage);
        return;
      }
      
      // Verifica se o CNPJ já está em uso no Firestore
      final isCnpjInUse = await _barRepository.isCnpjInUse(_cnpj);
      if (isCnpjInUse) {
        _setError(AppStrings.cnpjInUseErrorMessage);
        return;
      }
      
      // Cria o usuário no Clerk
      final firstName = _responsibleName.split(' ').first;
      final lastName = _responsibleName.split(' ').length > 1
          ? _responsibleName.split(' ').sublist(1).join(' ')
          : '';
      
      await AuthService.signUpWithEmailAndPassword(
        _email,
        _password,
        firstName,
        lastName,
      );
      
      // Cria o bar no Firestore
      final bar = BarModel.empty().copyWith(
        email: _email,
        cnpj: _cnpj,
        name: _name,
        responsibleName: _responsibleName,
        phone: _phone,
        cep: _cep,
        street: _street,
        number: _number,
        complement: _complement,
        state: _stateUf,
        city: _city,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _barRepository.createBar(bar);
      
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