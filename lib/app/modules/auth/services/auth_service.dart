import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


/// Serviço de autenticação usando Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;
  static bool get isCurrentUserEmailVerified => _auth.currentUser?.emailVerified ?? false;

  static User? getCurrentUser(BuildContext context) {
    return _auth.currentUser;
  }

  static bool isAuthenticated(BuildContext context) {
    return _auth.currentUser != null;
  }

  static String? getCurrentUserId(BuildContext context) {
    return _auth.currentUser?.uid;
  }

  static String? getCurrentUserEmail(BuildContext context) {
    return _auth.currentUser?.email;
  }

  static String? getCurrentUserName(BuildContext context) {
    final user = _auth.currentUser;
    return user?.displayName ?? user?.email;
  }

  static Future<String?> getToken() async {
    return _auth.currentUser?.getIdToken();
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signOut(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }

  /// Envia e-mail de verificação para o usuário atual
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        // Configurar ActionCodeSettings para deep links
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://bar-boss-mobile.web.app/email-verification.html',
          handleCodeInApp: true,
          iOSBundleId: 'com.barboss.mobile',
          androidPackageName: 'com.barboss.mobile',
          androidInstallApp: true,
          androidMinimumVersion: '21',
        );
        
        await user.sendEmailVerification(actionCodeSettings);
      }
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de verificação: $e');
    }
  }

  /// Recarrega os dados do usuário atual para verificar se o e-mail foi verificado
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Erro ao recarregar dados do usuário: $e');
    }
  }

  /// Verifica se o e-mail do usuário atual foi verificado (após reload)
  static Future<bool> checkEmailVerified() async {
    try {
      await reloadUser();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw Exception('Erro ao verificar status do e-mail: $e');
    }
  }

  // Método removido por usar API deprecated (fetchSignInMethodsForEmail)
  // Para verificar se email existe, use tentativa de criação de conta
  // e trate o erro FirebaseAuthException com código 'email-already-in-use'

  static Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName('$firstName $lastName'.trim());
      
      // Enviar e-mail de verificação automaticamente após cadastro
      await sendEmailVerification();
      
      return credential;
    } catch (e) {
      throw Exception('Erro ao criar conta: $e');
    }
  }

  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Verificar se o e-mail foi verificado
    if (!credential.user!.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'E-mail não verificado. Verifique sua caixa de entrada.',
      );
    }
    
    return credential;
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login com Google cancelado.');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  // TODO: Implementar login com Facebook posteriormente
  /*
  static Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        throw Exception('Login com Facebook falhou: ${result.status}');
      }
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      throw Exception('Erro ao fazer login com Facebook: $e');
    }
  }
  */

  // TODO: Implementar login com Apple posteriormente
  /*
  static Future<UserCredential> signInWithApple() async {
    try {
      if (!Platform.isIOS) {
        throw Exception('Sign in with Apple disponível apenas no iOS.');
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oAuthProvider = OAuthProvider('apple.com');
      final authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final userCredential = await _auth.signInWithCredential(authCredential);
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((e) => (e ?? '').isNotEmpty).join(' ');
      if (fullName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(fullName);
      }
      return userCredential;
    } catch (e) {
      throw Exception('Erro ao fazer login com Apple: $e');
    }
  }
  */
}
