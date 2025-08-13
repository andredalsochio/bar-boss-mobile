import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Serviço de autenticação usando Firebase
class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => currentUser?.uid;
  static String? get currentUserEmail => currentUser?.email;
  static String? get currentUserName => currentUser?.displayName;

  /// Verifica se há usuário autenticado
  static bool isAuthenticated() => currentUser != null;

  /// Token do usuário
  static Future<String?> getToken() async {
    try {
      return await currentUser?.getIdToken();
    } catch (e) {
      debugPrint('Erro ao obter token: $e');
      return null;
    }
  }

  /// Mudanças no estado de autenticação
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Logout
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('Erro no logout: $e');
      rethrow;
    }
  }

  /// Redefinição de senha por e-mail
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Erro ao enviar e-mail de redefinição: $e');
      rethrow;
    }
  }

  /// Verifica se o e-mail já está em uso
  static Future<bool> isEmailInUse(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar e-mail: $e');
      rethrow;
    }
  }

  /// Cadastro com e-mail e senha
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
      return credential;
    } catch (e) {
      debugPrint('Erro no cadastro: $e');
      rethrow;
    }
  }

  /// Login com e-mail e senha
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Erro no login com e-mail: $e');
      rethrow;
    }
  }

  /// Login com Google
  static Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login cancelado');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Erro no login com Google: $e');
      rethrow;
    }
  }

  /// Login com Apple
  static Future<UserCredential> signInWithApple() async {
    try {
      final appleId = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleId.identityToken,
        accessToken: appleId.authorizationCode,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final name = [appleId.givenName, appleId.familyName]
          .where((n) => n != null && n.isNotEmpty)
          .join(' ');
      if (name.isNotEmpty) {
        await userCred.user?.updateDisplayName(name);
      }
      return userCred;
    } catch (e) {
      debugPrint('Erro no login com Apple: $e');
      rethrow;
    }
  }

  /// Login com Facebook
  static Future<UserCredential> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.accessToken == null) {
        throw Exception('Login cancelado');
      }
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Erro no login com Facebook: $e');
      rethrow;
    }
  }
}
