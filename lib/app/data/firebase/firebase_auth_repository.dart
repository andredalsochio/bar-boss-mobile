import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('🔐 [FirebaseAuthRepository] Iniciando signInWithEmail para: ${email.substring(0, 3)}***');
    try {
      debugPrint('🔐 [FirebaseAuthRepository] Chamando _auth.signInWithEmailAndPassword...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ [FirebaseAuthRepository] Autenticação Firebase bem-sucedida!');
      
      // Verificar se o e-mail foi verificado
      if (credential.user != null && !credential.user!.emailVerified) {
        debugPrint('❌ [FirebaseAuthRepository] E-mail não verificado, fazendo logout...');
        // Fazer logout do usuário não verificado
        await _auth.signOut();
        debugPrint('❌ [FirebaseAuthRepository] Logout realizado devido a e-mail não verificado');
        return AuthResult.error('E-mail não verificado. Verifique sua caixa de entrada e clique no link de verificação.');
      }
      
      debugPrint('✅ [FirebaseAuthRepository] E-mail verificado, login autorizado!');
      return _fromFirebaseCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] FirebaseAuthException: ${e.code} - ${e.message}');
      return _fromFirebaseException(e);
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Exceção genérica: $e');
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName}) async {
    debugPrint('📝 [FirebaseAuthRepository] Iniciando signUpWithEmail para: ${email.substring(0, 3)}***');
    try {
      debugPrint('📝 [FirebaseAuthRepository] Chamando _auth.createUserWithEmailAndPassword...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ [FirebaseAuthRepository] Conta criada com sucesso!');
      
      // Atualiza o displayName se fornecido
      if (displayName != null && credential.user != null) {
        debugPrint('📝 [FirebaseAuthRepository] Atualizando displayName: $displayName');
        await credential.user!.updateDisplayName(displayName);
        debugPrint('✅ [FirebaseAuthRepository] DisplayName atualizado!');
      }
      
      // Envia e-mail de verificação automaticamente após criação da conta
      if (credential.user != null) {
        debugPrint('📧 [FirebaseAuthRepository] Enviando e-mail de verificação...');
        await sendEmailVerification();
        debugPrint('✅ [FirebaseAuthRepository] E-mail de verificação enviado!');
      }
      
      return _fromFirebaseCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] FirebaseAuthException: ${e.code} - ${e.message}');
      return _fromFirebaseException(e);
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Exceção genérica: $e');
      return _fromGenericException(Exception(e.toString()));
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    debugPrint('🟢 [FirebaseAuthRepository] Iniciando signInWithGoogle...');
    try {
      debugPrint('🟢 [FirebaseAuthRepository] Chamando GoogleSignIn().signIn()...');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        debugPrint('❌ [FirebaseAuthRepository] GoogleSignIn cancelado pelo usuário');
        return AuthResult.error('Login com Google cancelado');
      }
      
      debugPrint('✅ [FirebaseAuthRepository] GoogleSignIn bem-sucedido: ${googleUser.email}');
      debugPrint('🟢 [FirebaseAuthRepository] Obtendo authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('🟢 [FirebaseAuthRepository] Criando credential do Firebase...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      debugPrint('🟢 [FirebaseAuthRepository] Fazendo signInWithCredential...');
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ [FirebaseAuthRepository] Firebase signIn bem-sucedido!');
      final result = _fromFirebaseCredential(userCredential);
      debugPrint('✅ [FirebaseAuthRepository] AuthResult criado: isSuccess=${result.isSuccess}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] FirebaseAuthException: ${e.code} - ${e.message}');
      return _fromFirebaseException(e);
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Exceção genérica: $e');
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
  Future<bool> sendEmailVerification() async {
    debugPrint('📧 [FirebaseAuthRepository] Iniciando sendEmailVerification...');
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        debugPrint('📧 [FirebaseAuthRepository] Usuário encontrado e e-mail não verificado, enviando...');
        
        // Configurar idioma para português
        await _auth.setLanguageCode('pt');
        
        // Enviar e-mail de verificação sem ActionCodeSettings complexos
        await user.sendEmailVerification();
        debugPrint('✅ [FirebaseAuthRepository] E-mail de verificação enviado com sucesso!');
        return true;
      }
      debugPrint('⚠️ [FirebaseAuthRepository] Usuário não encontrado ou e-mail já verificado');
      return false;
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Erro ao enviar e-mail de verificação: $e');
      return false;
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    debugPrint('🔍 [FirebaseAuthRepository] Iniciando checkEmailVerified...');
    try {
      debugPrint('🔍 [FirebaseAuthRepository] Recarregando dados do usuário...');
      await _auth.currentUser?.reload();
      final isVerified = _auth.currentUser?.emailVerified ?? false;
      debugPrint('✅ [FirebaseAuthRepository] Status de verificação: $isVerified');
      return isVerified;
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Erro ao verificar status do e-mail: $e');
      return false;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    debugPrint('🔍 [FirebaseAuthRepository] Verificando se e-mail está verificado...');
    final user = _auth.currentUser;
    if (user != null) {
      final isVerified = user.emailVerified;
      debugPrint('✅ [FirebaseAuthRepository] E-mail verificado: $isVerified');
      return isVerified;
    }
    debugPrint('⚠️ [FirebaseAuthRepository] Usuário não encontrado');
    return false;
  }

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    debugPrint('🔗 [FirebaseAuthRepository] Iniciando linkEmailPassword para: ${email.substring(0, 3)}***');
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('🔗 [FirebaseAuthRepository] Usuário encontrado, criando credential...');
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        debugPrint('🔗 [FirebaseAuthRepository] Vinculando credential ao usuário...');
        await user.linkWithCredential(credential);
        debugPrint('✅ [FirebaseAuthRepository] E-mail/senha vinculado com sucesso!');
      } else {
        debugPrint('❌ [FirebaseAuthRepository] Usuário não encontrado para vincular e-mail/senha');
        throw Exception('Usuário não encontrado');
      }
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Erro ao vincular e-mail/senha: $e');
      throw Exception('Erro ao vincular email/senha: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('📧 [FirebaseAuthRepository] Iniciando sendPasswordResetEmail para: ${email.substring(0, 3)}***');
    try {
      debugPrint('📧 [FirebaseAuthRepository] Chamando _auth.sendPasswordResetEmail...');
      
      // Configurar idioma para português
      await _auth.setLanguageCode('pt');
      
      // Enviar e-mail de reset sem ActionCodeSettings complexos
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ [FirebaseAuthRepository] E-mail de redefinição enviado com sucesso!');
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Erro ao enviar e-mail de redefinição: $e');
      throw Exception('Erro ao enviar email de redefinição de senha: $e');
    }
  }

  @override
  Future<void> signOut() async {
    debugPrint('🚪 [FirebaseAuthRepository] Iniciando signOut...');
    try {
      debugPrint('🚪 [FirebaseAuthRepository] Fazendo logout do Google...');
      await GoogleSignIn().signOut();
      debugPrint('🚪 [FirebaseAuthRepository] Fazendo logout do Firebase Auth...');
      await _auth.signOut();
      debugPrint('✅ [FirebaseAuthRepository] Logout realizado com sucesso!');
    } catch (e) {
      debugPrint('❌ [FirebaseAuthRepository] Erro ao fazer logout: $e');
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Verifica se um email já está em uso no Firebase Auth
  /// Usa tentativa de criação de conta para verificar disponibilidade
  @override
  Future<bool> isEmailInUse(String email) async {
    debugPrint('🔍 [AUTH_REPO] isEmailInUse INICIADO para: "$email"');
    
    try {
      // Tenta criar uma conta temporária para verificar se o email está disponível
      debugPrint('🔍 [AUTH_REPO] Tentando createUserWithEmailAndPassword com senha temporária...');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'temp_password_123456789', // Senha temporária
      );
      
      // Se chegou aqui, o email estava disponível
      // Deletar a conta temporária imediatamente
      debugPrint('🔍 [AUTH_REPO] Email disponível, deletando conta temporária...');
      await credential.user?.delete();
      
      debugPrint('✅ [AUTH_REPO] Email DISPONÍVEL');
      return false;
      
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('🔍 [AUTH_REPO] Erro capturado: $errorStr');
      
      if (errorStr.contains('email-already-in-use')) {
        debugPrint('✅ [AUTH_REPO] Email EM USO (email-already-in-use)');
        return true;
      } else if (errorStr.contains('invalid-email')) {
        debugPrint('❌ [AUTH_REPO] Email inválido');
        throw Exception('Email inválido');
      } else {
        debugPrint('❌ [AUTH_REPO] ERRO CRÍTICO: $e');
        // Para erros críticos, assume que o email está em uso por segurança
        debugPrint('⚠️ [AUTH_REPO] Assumindo email EM USO por segurança devido a erro crítico');
        return true;
      }
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