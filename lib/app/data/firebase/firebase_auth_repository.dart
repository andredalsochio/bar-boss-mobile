import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_result.dart';

/// Implementação Firebase da interface AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_fromFirebaseUser);
  }

  @override
  AuthUser? get currentUser {
    return _fromFirebaseUser(_auth.currentUser);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fromFirebaseCredential(credential);
    } on FirebaseAuthException catch (e) {
      return _fromFirebaseException(e);
    } catch (e) {
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o displayName se fornecido
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      return _fromFirebaseCredential(credential);
    } on FirebaseAuthException catch (e) {
      return _fromFirebaseException(e);
    } catch (e) {
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return AuthResult.error('Login com Google cancelado');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return _fromFirebaseCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      return _fromFirebaseException(e);
    } catch (e) {
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      return _fromFirebaseCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      return _fromFirebaseException(e);
    } catch (e) {
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
         final OAuthCredential facebookAuthCredential = 
             FacebookAuthProvider.credential(result.accessToken!.tokenString);
         
         final userCredential = await _auth.signInWithCredential(facebookAuthCredential);
         return _fromFirebaseCredential(userCredential);
       } else {
         return AuthResult.error('Login com Facebook cancelado ou falhou');
       }
    } on FirebaseAuthException catch (e) {
      return _fromFirebaseException(e);
    } catch (e) {
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Erro ao enviar email de verificação: $e');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.linkWithCredential(credential);
      }
    } catch (e) {
      throw Exception('Erro ao vincular email/senha: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Erro ao enviar email de redefinição de senha: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  // Métodos privados de conversão (anteriormente no AuthAdapter)
  
  /// Converte User do Firebase para AuthUser de domínio
  AuthUser? _fromFirebaseUser(User? firebaseUser) {
    if (firebaseUser == null) return null;
    
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      providerIds: firebaseUser.providerData
          .map((info) => info.providerId)
          .toList(),
    );
  }

  /// Converte UserCredential do Firebase para AuthResult de domínio
  AuthResult _fromFirebaseCredential(UserCredential credential) {
    final user = _fromFirebaseUser(credential.user);
    
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
  AuthResult _fromFirebaseException(FirebaseAuthException exception) {
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
  AuthResult _fromGenericException(Exception exception) {
    return AuthResult.error('Erro inesperado: ${exception.toString()}');
  }
}