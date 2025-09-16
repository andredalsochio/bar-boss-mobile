import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  
  /// Validador de telefone com DDD
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
    
    // Verifica se o DDD é válido (11-99)
    final ddd = int.tryParse(numericValue.substring(0, 2));
    if (ddd == null || ddd < 11 || ddd > 99) {
      return AppStrings.invalidPhone;
    }
    
    return null;
  }
  
  /// Validador de senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    if (value.length < 6) {
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
  
  /// Validador de título de evento
  static String? eventTitle(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    
    if (value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    
    return null;
  }
  
  /// Validador de data de evento (deve ser presente ou futura)
  static String? eventDate(DateTime? value) {
    if (value == null) {
      return AppStrings.requiredField;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(value.year, value.month, value.day);
    
    if (eventDay.isBefore(today)) {
      return AppStrings.invalidDateErrorMessage;
    }
    
    return null;
  }
  
  /// Validador de data de fim de evento (deve ser >= data de início)
  static String? eventEndDate(DateTime? startDate, DateTime? endDate) {
    if (endDate == null) {
      return null; // Data de fim é opcional
    }
    
    if (startDate == null) {
      return null; // Não pode validar sem data de início
    }
    
    if (endDate.isBefore(startDate)) {
      return 'Data de fim deve ser posterior à data de início';
    }
    
    return null;
  }
  

}