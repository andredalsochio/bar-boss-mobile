import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'throttling_service.dart';

/// Mixin para verificação de conectividade de internet
/// 
/// Fornece métodos reutilizáveis para verificar se o dispositivo
/// está conectado à internet antes de executar operações que requerem rede.
/// Integra com ThrottlingService para mitigar problemas de "Too many attempts".
/// 
/// Uso:
/// ```dart
/// class MyViewModel extends ChangeNotifier with ConnectivityMixin {
///   Future<void> createEvent() async {
///     if (!await checkConnectivity(context, 'criar evento')) return;
///     // Lógica para criar evento
///   }
/// }
/// ```
mixin ConnectivityMixin {
  final Connectivity _connectivity = Connectivity();
  final ThrottlingService _throttlingService = ThrottlingService();

  /// Verifica se há conectividade com a internet
  /// 
  /// Retorna `true` se há conexão, `false` caso contrário
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = 
          await _connectivity.checkConnectivity();
      
      // Verifica se há pelo menos uma conexão ativa
      return connectivityResult.any((result) => 
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn);
    } catch (e) {
      // Em caso de erro, assume que não há conexão
      debugPrint('Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Verifica conectividade e exibe dialog se não houver internet
  /// 
  /// [context] - BuildContext para exibir o dialog
  /// [action] - Descrição da ação que requer internet (ex: "criar evento")
  /// 
  /// Retorna `true` se há conexão, `false` se não há e o dialog foi exibido
  Future<bool> checkConnectivity(BuildContext context, String action) async {
    // Usa throttling para evitar múltiplas verificações simultâneas
    final hasConnection = await _throttlingService.executeWithThrottling<bool>(
      operationKey: 'connectivity_check',
      operation: () => hasInternetConnection(),
    );

    if (!hasConnection) {
      if (context.mounted) {
        await _showNoInternetDialog(context, action);
      }
      return false;
    }
    return true;
  }

  /// Exibe dialog informando sobre falta de conexão
  Future<void> _showNoInternetDialog(BuildContext context, String action) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return NoInternetDialog(action: action);
      },
    );
  }

  /// Stream para monitorar mudanças na conectividade
  /// 
  /// Útil para reagir a mudanças de conectividade em tempo real
  Stream<List<ConnectivityResult>> get connectivityStream => 
      _connectivity.onConnectivityChanged;
}

/// Dialog customizado para avisar sobre falta de conexão
class NoInternetDialog extends StatelessWidget {
  final String action;

  const NoInternetDialog({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sem conexão',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para $action, você precisa estar conectado à internet.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verifique sua conexão Wi-Fi ou dados móveis e tente novamente.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Entendi',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}