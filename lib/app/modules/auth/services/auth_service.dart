import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Serviço de autenticação usando Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

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

  static Future<bool> isEmailInUse(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

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
      throw Exception('Erro ao criar conta: $e');
    }
  }

  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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
}
