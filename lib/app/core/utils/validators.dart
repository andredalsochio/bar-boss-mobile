import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';

/// Classe que contém os validadores utilizados nos formulários
class Validators {
  /// Validador de campo obrigatório
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }
  
  /// Validador de e-mail
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );
    
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    
    return null;
  }
  
  /// Validador de CNPJ
  static String? cnpj(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    // Remove caracteres não numéricos
    final numericValue = value.replaceAll(RegExp(r'\D'), '');
    
    if (numericValue.length != 14) {
      return AppStrings.invalidCnpj;
    }
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(numericValue)) {
      return AppStrings.invalidCnpj;
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
      return AppStrings.invalidCnpj;
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
      return AppStrings.invalidCnpj;
    }
    
    return null;
  }
  
  /// Validador de CEP
  static String? cep(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    // Remove caracteres não numéricos
    final numericValue = value.replaceAll(RegExp(r'\D'), '');
    
    if (numericValue.length != 8) {
      return AppStrings.invalidCep;
    }
    
    return null;
  }
  
  /// Validador de telefone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    // Remove caracteres não numéricos
    final numericValue = value.replaceAll(RegExp(r'\D'), '');
    
    // Verifica se o telefone tem entre 10 e 11 dígitos (com DDD)
    if (numericValue.length < 10 || numericValue.length > 11) {
      return AppStrings.invalidPhone;
    }
    
    return null;
  }
  
  /// Validador de senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    
    return null;
  }
  
  /// Validador de confirmação de senha
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.requiredField;
      }
      
      if (value != password) {
        return AppStrings.passwordsDontMatch;
      }
      
      return null;
    };
  }
}