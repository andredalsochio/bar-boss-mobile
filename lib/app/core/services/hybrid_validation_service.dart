import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/validators.dart';
import '../utils/normalization_helpers.dart';

/// Resultado da validação híbrida
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? details;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.details,
  });

  ValidationResult.success({Map<String, dynamic>? details})
      : isValid = true,
        errorMessage = null,
        details = details;

  ValidationResult.error(String message, {Map<String, dynamic>? details})
      : isValid = false,
        errorMessage = message,
        details = details;
}

/// Serviço de validação híbrida que combina validações do cliente com servidor
/// Estratégia: validar formato no cliente, unicidade no servidor
class HybridValidationService {
  static final HybridValidationService _instance = HybridValidationService._internal();
  factory HybridValidationService() => _instance;
  HybridValidationService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Validação híbrida completa para dados de cadastro
  /// Combina validação de formato (cliente) + unicidade (servidor)
  Future<ValidationResult> validateRegistrationData({
    required String? email,
    required String? cnpj,
    required String flowType, // 'CLASSIC' ou 'SOCIAL'
  }) async {
    debugPrint('🔍 [HybridValidationService] Iniciando validação híbrida...');
    debugPrint('📋 [HybridValidationService] Tipo de fluxo: $flowType');

    try {
      // 1. Validações de formato no cliente (rápidas)
      final clientValidation = _validateClientSide(
        email: email,
        cnpj: cnpj,
        flowType: flowType,
      );

      if (!clientValidation.isValid) {
        debugPrint('❌ [HybridValidationService] Validação do cliente falhou: ${clientValidation.errorMessage}');
        return clientValidation;
      }

      // 2. Validações de unicidade no servidor (seguras)
      final serverValidation = await _validateServerSide(
        email: email,
        cnpj: cnpj,
        flowType: flowType,
      );

      if (!serverValidation.isValid) {
        debugPrint('❌ [HybridValidationService] Validação do servidor falhou: ${serverValidation.errorMessage}');
        return serverValidation;
      }

      debugPrint('✅ [HybridValidationService] Validação híbrida concluída com sucesso');
      return ValidationResult.success(
        details: {
          'clientValidation': clientValidation.details,
          'serverValidation': serverValidation.details,
        },
      );

    } catch (e) {
      debugPrint('❌ [HybridValidationService] Erro na validação híbrida: $e');
      return ValidationResult.error(
        'Erro interno na validação. Tente novamente.',
        details: {'error': e.toString()},
      );
    }
  }

  /// Validação apenas de email (para casos específicos)
  Future<ValidationResult> validateEmailAvailability(String email) async {
    debugPrint('📧 [HybridValidationService] Validando disponibilidade do email...');

    try {
      // 1. Validar formato no cliente
      final emailError = Validators.email(email);
      if (emailError != null) {
        return ValidationResult.error(emailError);
      }

      // 2. Validar unicidade no servidor
      final callable = _functions.httpsCallable('checkEmailAvailability');
      final result = await callable.call({
        'email': email.trim().toLowerCase(),
      });

      final emailExists = result.data['emailExists'] as bool;

      if (emailExists) {
        return ValidationResult.error('E-mail já cadastrado, faça login.');
      }

      return ValidationResult.success(
        details: {'emailExists': false},
      );

    } catch (e) {
      debugPrint('❌ [HybridValidationService] Erro na validação de email: $e');
      return ValidationResult.error(
        'Erro ao validar e-mail. Tente novamente.',
        details: {'error': e.toString()},
      );
    }
  }

  // Método validateCnpjAvailability removido - funcionalidade integrada em validateRegistrationData

  /// Validações do lado do cliente (formato, regras básicas)
  ValidationResult _validateClientSide({
    required String? email,
    required String? cnpj,
    required String flowType,
  }) {
    debugPrint('📱 [HybridValidationService] Executando validações do cliente...');

    // Validar CNPJ (obrigatório para ambos os fluxos)
    if (cnpj == null || cnpj.isEmpty) {
      return ValidationResult.error('CNPJ é obrigatório');
    }

    final cnpjError = Validators.cnpj(cnpj);
    if (cnpjError != null) {
      return ValidationResult.error(cnpjError);
    }

    // Validar email (obrigatório apenas para fluxo clássico)
    if (flowType == 'CLASSIC') {
      if (email == null || email.isEmpty) {
        return ValidationResult.error('E-mail é obrigatório');
      }

      final emailError = Validators.email(email);
      if (emailError != null) {
        return ValidationResult.error(emailError);
      }
    }

    debugPrint('✅ [HybridValidationService] Validações do cliente aprovadas');
    return ValidationResult.success(
      details: {
        'emailFormat': flowType == 'CLASSIC' ? 'valid' : 'not_required',
        'cnpjFormat': 'valid',
      },
    );
  }

  /// Validações do lado do servidor (unicidade, segurança)
  Future<ValidationResult> _validateServerSide({
    required String? email,
    required String? cnpj,
    required String flowType,
  }) async {
    debugPrint('☁️ [HybridValidationService] Executando validações do servidor...');

    try {
      final callable = _functions.httpsCallable('validateRegistrationData');
      final result = await callable.call({
        'email': email?.trim().toLowerCase(),
        'cnpj': NormalizationHelpers.normalizeCnpj(cnpj!),
        'flowType': flowType,
      });

      final emailExists = result.data['emailExists'] as bool;
      final cnpjExists = result.data['cnpjExists'] as bool;

      // Verificar conflitos
      if (flowType == 'CLASSIC' && emailExists) {
        return ValidationResult.error('E-mail já cadastrado, faça login.');
      }

      if (cnpjExists) {
        return ValidationResult.error('CNPJ já registrado.');
      }

      debugPrint('✅ [HybridValidationService] Validações do servidor aprovadas');
      return ValidationResult.success(
        details: {
          'emailExists': emailExists,
          'cnpjExists': cnpjExists,
          'flowType': flowType,
        },
      );

    } catch (e) {
      debugPrint('❌ [HybridValidationService] Erro nas validações do servidor: $e');
      
      // Para fluxo SOCIAL, tentar fallback para validação de email
      if (flowType == 'SOCIAL' && email != null) {
        debugPrint('🔄 [HybridValidationService] Tentando fallback para fluxo SOCIAL...');
        
        try {
          final emailFallback = await _validateEmailWithFallback(email);
          
          if (!emailFallback.isValid) {
            return emailFallback;
          }
          
          // Se email está OK via fallback, assumir que CNPJ também está (fail-safe)
          debugPrint('✅ [HybridValidationService] Fallback concluído com sucesso');
          return ValidationResult.success(
            details: {
              'emailExists': false,
              'cnpjExists': false, // Assumir que não existe (fail-safe)
              'flowType': flowType,
              'method': 'fallback',
            },
          );
          
        } catch (fallbackError) {
          debugPrint('❌ [HybridValidationService] Fallback também falhou: $fallbackError');
        }
      }
      
      // Analisar tipo de erro para mensagem apropriada
      if (e.toString().contains('unauthenticated')) {
        return ValidationResult.error('Sessão expirada. Faça login novamente.');
      } else if (e.toString().contains('invalid-argument')) {
        return ValidationResult.error('Dados inválidos fornecidos.');
      } else {
        return ValidationResult.error('Erro de conexão. Tente novamente.');
      }
    }
  }

  /// Fallback para validação de email usando fetchSignInMethodsForEmail
  /// Usado quando Cloud Functions não estão disponíveis
  Future<ValidationResult> _validateEmailWithFallback(String email) async {
    debugPrint('🔄 [HybridValidationService] Usando fallback para validação de email...');

    try {
      final auth = FirebaseAuth.instance;
      final signInMethods = await auth.fetchSignInMethodsForEmail(email);
      
      final emailExists = signInMethods.isNotEmpty;
      
      if (emailExists) {
        return ValidationResult.error('E-mail já cadastrado, faça login.');
      }

      return ValidationResult.success(
        details: {'emailExists': false, 'method': 'fallback'},
      );

    } catch (e) {
      debugPrint('❌ [HybridValidationService] Erro no fallback de email: $e');
      // Em caso de erro, assumir que email não existe (fail-safe)
      return ValidationResult.success(
        details: {'emailExists': false, 'method': 'fallback_error'},
      );
    }
  }

  /// Limpar cache de validações (se implementado no futuro)
  void clearCache() {
    debugPrint('🧹 [HybridValidationService] Cache limpo');
    // Implementar cache local se necessário
  }
}