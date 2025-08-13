import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Serviço de autenticação usando Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Getter para o usuário atual
  static User? get currentUser => _auth.currentUser;
  
  /// Getter para o ID do usuário atual
  static String? get currentUserId => _auth.currentUser?.uid;
  
  /// Getter para o email do usuário atual
  static String? get currentUserEmail => _auth.currentUser?.email;

  /// Obtém o usuário atual
  static User? getCurrentUser(BuildContext context) {
    return _auth.currentUser;
  }

  /// Verifica se o usuário está autenticado
  static bool isAuthenticated(BuildContext context) {
    return _auth.currentUser != null;
  }

  /// Obtém o ID do usuário atual
  static String? getCurrentUserId(BuildContext context) {
    return _auth.currentUser?.uid;
  }

  /// Obtém o email do usuário atual
  static String? getCurrentUserEmail(BuildContext context) {
    return _auth.currentUser?.email;
  }

  /// Obtém o nome do usuário atual
  static String? getCurrentUserName(BuildContext context) {
    return _auth.currentUser?.displayName ?? _auth.currentUser?.email;
  }

  /// Obtém o token de autenticação
  static Future<String?> getToken(BuildContext context) async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      return null;
    }
  }

  /// Stream de mudanças no estado de autenticação
  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
  
  /// Faz logout do usuário
  static Future<void> signOut(BuildContext context) async {
    try {
      // Faz logout do Google se estiver conectado
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Faz logout do Facebook
      await FacebookAuth.instance.logOut();
      
      // Faz logout do Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }
  
  /// Envia email de redefinição de senha
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }
  
  /// Verifica se um email já está em uso
  static Future<bool> isEmailInUse(String email) async {
    try {
      // Tenta criar um usuário temporário para verificar se o email existe
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'temp_password_123456',
      );
      // Se chegou aqui, o email não estava em uso, então deletamos o usuário temporário
      await _auth.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Cria uma nova conta com email e senha
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
      
      // Atualiza o nome do usuário
      await credential.user?.updateDisplayName('$firstName $lastName');
      
      return credential;
    } catch (e) {
      throw Exception('Erro ao criar conta: $e');
    }
  }
  
  /// Faz login com email e senha
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
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Faz login com Google
  static Future<UserCredential> signInWithGoogle(BuildContext context) async {
    try {
      // Inicia o processo de login com Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Login cancelado pelo usuário');
      }

      // Obtém os detalhes de autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Cria uma credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz login no Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  /// Faz login com Apple
  static Future<UserCredential> signInWithApple(BuildContext context) async {
    try {
      // Solicita credencial da Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Cria uma credencial do Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Faz login no Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Atualiza o nome se disponível
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }
      
      return userCredential;
    } catch (e) {
      throw Exception('Erro ao fazer login com Apple: $e');
    }
  }

  /// Faz login com Facebook
  static Future<UserCredential> signInWithFacebook(BuildContext context) async {
    try {
      // Inicia o processo de login com Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Login cancelado ou falhou');
      }

      // Cria uma credencial do Firebase
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Faz login no Firebase
      return await _auth.signInWithCredential(facebookAuthCredential);
    } catch (e) {
      throw Exception('Erro ao fazer login com Facebook: $e');
    }
  }
}