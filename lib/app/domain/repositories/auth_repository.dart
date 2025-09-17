import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_result.dart';

/// Interface de domínio para autenticação
/// Isolada de tipos específicos do Firebase
abstract class AuthRepository {
  /// Stream que monitora mudanças no estado de autenticação
  Stream<AuthUser?> authStateChanges();

  /// Faz login com email e senha
  Future<AuthResult> signInWithEmail(String email, String password);

  /// Faz login com Google
  Future<AuthResult> signInWithGoogle();

  /// Faz login com Apple
  Future<AuthResult> signInWithApple();

  /// Faz login com Facebook
  Future<AuthResult> signInWithFacebook();

  /// Registra novo usuário com email e senha
  Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName});

  /// Envia email de verificação para o usuário atual
  Future<bool> sendEmailVerification();

  /// Verifica se o email do usuário atual está verificado
  Future<bool> isEmailVerified();

  /// Verifica se o email foi verificado (com reload)
  Future<bool> checkEmailVerified();

  /// Vincula email e senha à conta atual
  Future<void> linkEmailPassword(String email, String password);

  /// Obtém o usuário atual
  AuthUser? get currentUser;

  /// Envia email de redefinição de senha
  Future<void> sendPasswordResetEmail(String email);

  /// Verifica se email está em uso (método seguro contra enumeração)
  /// Retorna true se email já existe, false caso contrário
  Future<bool> isEmailInUse(String email);

  /// Faz logout do usuário atual
  Future<void> signOut();
}