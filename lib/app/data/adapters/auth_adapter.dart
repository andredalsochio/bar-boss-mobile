import 'package:firebase_auth/firebase_auth.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_result.dart';

/// Adapter para converter entre tipos Firebase e tipos de domínio
class AuthAdapter {
  /// Converte User do Firebase para AuthUser de domínio
  static AuthUser? fromFirebaseUser(User? firebaseUser) {
    if (firebaseUser == null) return null;
    
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      providerIds: firebaseUser.providerData
          .map((info) => info.providerId)
          .toList(),
    );
  }

  /// Converte UserCredential do Firebase para AuthResult de domínio
  static AuthResult fromFirebaseCredential(UserCredential credential) {
    final user = fromFirebaseUser(credential.user);
    
    if (user == null) {
      return AuthResult.error('Falha ao obter dados do usuário');
    }
    
    return AuthResult.success(
      user: user,
      providerId: credential.credential?.providerId,
      isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  /// Converte FirebaseAuthException para AuthResult de erro
  static AuthResult fromFirebaseException(FirebaseAuthException exception) {
    String errorMessage;
    
    switch (exception.code) {
      case 'user-not-found':
        errorMessage = 'Usuário não encontrado';
        break;
      case 'wrong-password':
        errorMessage = 'Senha incorreta';
        break;
      case 'email-already-in-use':
        errorMessage = 'Este email já está em uso';
        break;
      case 'weak-password':
        errorMessage = 'A senha é muito fraca';
        break;
      case 'invalid-email':
        errorMessage = 'Email inválido';
        break;
      case 'user-disabled':
        errorMessage = 'Esta conta foi desabilitada';
        break;
      case 'too-many-requests':
        errorMessage = 'Muitas tentativas. Tente novamente mais tarde';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Operação não permitida';
        break;
      default:
        errorMessage = exception.message ?? 'Erro de autenticação';
    }
    
    return AuthResult.error(errorMessage);
  }

  /// Converte Exception genérica para AuthResult de erro
  static AuthResult fromGenericException(Exception exception) {
    return AuthResult.error('Erro inesperado: ${exception.toString()}');
  }
}