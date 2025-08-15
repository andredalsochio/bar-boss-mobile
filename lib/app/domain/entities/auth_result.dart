import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';

/// Resultado de operações de autenticação
/// Substitui o tipo UserCredential do Firebase para manter isolamento
class AuthResult {
  final AuthUser? user;
  final String? providerId;
  final bool isNewUser;
  final String? errorMessage;
  final bool isSuccess;

  const AuthResult({
    this.user,
    this.providerId,
    this.isNewUser = false,
    this.errorMessage,
    required this.isSuccess,
  });

  /// Cria um resultado de sucesso
  factory AuthResult.success({
    required AuthUser user,
    String? providerId,
    bool isNewUser = false,
  }) {
    return AuthResult(
      user: user,
      providerId: providerId,
      isNewUser: isNewUser,
      isSuccess: true,
    );
  }

  /// Cria um resultado de erro
  factory AuthResult.error(String errorMessage) {
    return AuthResult(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  /// Verifica se a operação foi bem-sucedida e retornou um usuário
  bool get hasUser => isSuccess && user != null;

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(user: ${user?.uid}, providerId: $providerId, isNewUser: $isNewUser)';
    } else {
      return 'AuthResult.error(message: $errorMessage)';
    }
  }
}