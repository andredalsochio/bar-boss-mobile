import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Serviço para mitigar problemas de "Too many attempts" do Firebase
/// 
/// Implementa backoff exponencial e coalescing para reduzir chamadas
/// redundantes ao Firebase que podem causar throttling do App Check.
class ThrottlingService {
  static final ThrottlingService _instance = ThrottlingService._internal();
  factory ThrottlingService() => _instance;
  ThrottlingService._internal();

  // Cache de operações em andamento para coalescing
  final Map<String, Completer<dynamic>> _pendingOperations = {};
  
  // Histórico de tentativas para backoff
  final Map<String, _RetryInfo> _retryHistory = {};
  
  // Configurações de backoff
  static const Duration _baseDelay = Duration(milliseconds: 200);
  static const Duration _maxDelay = Duration(seconds: 5);
  static const int _maxRetries = 5;

  /// Executa uma operação com throttling e coalescing
  /// 
  /// [operationKey] - Chave única para identificar a operação (ex: 'auth_check', 'user_validation')
  /// [operation] - Função assíncrona a ser executada
  /// [forceNew] - Se true, força uma nova execução mesmo se já houver uma pendente
  /// 
  /// Retorna o resultado da operação ou lança exceção se falhar após todas as tentativas
  Future<T> executeWithThrottling<T>({
    required String operationKey,
    required Future<T> Function() operation,
    bool forceNew = false,
  }) async {
    // Coalescing: se já há uma operação pendente e não é forçada, retorna a existente
    if (!forceNew && _pendingOperations.containsKey(operationKey)) {
      debugPrint('ThrottlingService: Coalescing operation $operationKey');
      return await _pendingOperations[operationKey]!.future as T;
    }

    // Cria um novo completer para esta operação
    final completer = Completer<T>();
    _pendingOperations[operationKey] = completer as Completer<dynamic>;

    try {
      final result = await _executeWithBackoff(operationKey, operation);
      completer.complete(result);
      return result;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      // Remove a operação do cache
      _pendingOperations.remove(operationKey);
    }
  }

  /// Executa operação com backoff exponencial
  Future<T> _executeWithBackoff<T>(
    String operationKey,
    Future<T> Function() operation,
  ) async {
    final retryInfo = _retryHistory[operationKey] ?? _RetryInfo();
    _retryHistory[operationKey] = retryInfo;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        // Aplica delay de backoff se não for a primeira tentativa
        if (attempt > 0) {
          final delay = _calculateBackoffDelay(attempt);
          debugPrint('ThrottlingService: Backoff delay for $operationKey: ${delay.inMilliseconds}ms (attempt $attempt)');
          await Future.delayed(delay);
        }

        final result = await operation();
        
        // Sucesso: limpa o histórico de retry
        _retryHistory.remove(operationKey);
        return result;
        
      } catch (error) {
        final errorMessage = error.toString().toLowerCase();
        
        // Verifica se é um erro de throttling que deve ser retentado
        final isThrottlingError = errorMessage.contains('too many attempts') ||
                                 errorMessage.contains('quota exceeded') ||
                                 errorMessage.contains('rate limit') ||
                                 errorMessage.contains('app check');

        if (!isThrottlingError || attempt == _maxRetries) {
          // Não é erro de throttling ou esgotou tentativas
          _retryHistory.remove(operationKey);
          rethrow;
        }

        debugPrint('ThrottlingService: Throttling error for $operationKey (attempt $attempt): $error');
        retryInfo.lastAttempt = DateTime.now();
        retryInfo.attemptCount = attempt + 1;
      }
    }

    // Nunca deve chegar aqui, mas por segurança
    throw Exception('ThrottlingService: Max retries exceeded for $operationKey');
  }

  /// Calcula o delay de backoff exponencial
  Duration _calculateBackoffDelay(int attempt) {
    final exponentialDelay = Duration(
      milliseconds: _baseDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
    );
    
    // Adiciona jitter aleatório para evitar thundering herd
    final jitter = Duration(
      milliseconds: Random().nextInt(100),
    );
    
    final totalDelay = exponentialDelay + jitter;
    
    // Limita ao delay máximo
    return totalDelay > _maxDelay ? _maxDelay : totalDelay;
  }

  /// Limpa o cache de operações pendentes (útil para testes ou reset)
  void clearCache() {
    _pendingOperations.clear();
    _retryHistory.clear();
  }

  /// Verifica se uma operação está pendente
  bool isOperationPending(String operationKey) {
    return _pendingOperations.containsKey(operationKey);
  }

  /// Obtém estatísticas de retry para uma operação
  Map<String, dynamic>? getRetryStats(String operationKey) {
    final retryInfo = _retryHistory[operationKey];
    if (retryInfo == null) return null;

    return {
      'attemptCount': retryInfo.attemptCount,
      'lastAttempt': retryInfo.lastAttempt.toIso8601String(),
      'timeSinceLastAttempt': DateTime.now().difference(retryInfo.lastAttempt).inMilliseconds,
    };
  }
}

/// Informações de retry para uma operação específica
class _RetryInfo {
  int attemptCount = 0;
  DateTime lastAttempt = DateTime.now();
}

/// Mixin para facilitar o uso do ThrottlingService em ViewModels
mixin ThrottlingMixin {
  final ThrottlingService _throttlingService = ThrottlingService();

  /// Executa operação com throttling
  Future<T> executeThrottled<T>({
    required String operationKey,
    required Future<T> Function() operation,
    bool forceNew = false,
  }) {
    return _throttlingService.executeWithThrottling(
      operationKey: operationKey,
      operation: operation,
      forceNew: forceNew,
    );
  }

  /// Verifica se uma operação está pendente
  bool isThrottledOperationPending(String operationKey) {
    return _throttlingService.isOperationPending(operationKey);
  }
}