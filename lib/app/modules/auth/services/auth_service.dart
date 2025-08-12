import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

/// Serviço de autenticação usando Clerk
class AuthService {
  /// Getter para o usuário atual (compatibilidade)
  static dynamic get currentUser => null; // Placeholder - use getCurrentUser(context) instead
  
  /// Getter para o ID do usuário atual (compatibilidade)
  static String? get currentUserId => null; // Placeholder - use getCurrentUserId(context) instead
  
  /// Getter para o email do usuário atual (compatibilidade)
  static String? get currentUserEmail => null; // Placeholder - use getCurrentUserEmail(context) instead
  /// Obtém o usuário atual
  static dynamic getCurrentUser(BuildContext context) {
    try {
      final authState = ClerkAuth.of(context);
      return authState.user;
    } catch (e) {
      return null;
    }
  }

  /// Verifica se o usuário está autenticado
  static bool isAuthenticated(BuildContext context) {
    try {
      final authState = ClerkAuth.of(context);
      return authState.user != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtém o ID do usuário atual
  static String? getCurrentUserId(BuildContext context) {
    try {
      final user = getCurrentUser(context);
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  /// Obtém o email do usuário atual
  static String? getCurrentUserEmail(BuildContext context) {
    try {
      final user = getCurrentUser(context);
      // Tentativa de acessar email de diferentes formas possíveis
      return user?.primaryEmailAddress?.emailAddress ?? 
             user?.emailAddresses?.first?.emailAddress ?? 
             user?.email;
    } catch (e) {
      return null;
    }
  }

  /// Obtém o nome do usuário atual
  static String? getCurrentUserName(BuildContext context) {
    try {
      final user = getCurrentUser(context);
      return user?.firstName ?? 
             user?.fullName ?? 
             user?.primaryEmailAddress?.emailAddress ?? 
             user?.email;
    } catch (e) {
      return null;
    }
  }

  /// Obtém o token de autenticação
  static String? getToken(BuildContext context) {
    try {
      final authState = ClerkAuth.of(context);
      // Fallback para session id se getToken não estiver disponível
      return authState.session?.id;
    } catch (e) {
      return null;
    }
  }

  /// Stream de mudanças no estado de autenticação
  static Stream<bool> get authStateChanges {
    // Implementação simplificada - retorna stream vazio por enquanto
    return Stream.value(false);
  }
  
  /// Faz logout do usuário
  static Future<void> signOut(BuildContext context) async {
    try {
      final authState = ClerkAuth.of(context);
      await authState.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }
  
  /// Envia email de redefinição de senha
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Implementação simplificada - esta funcionalidade pode não estar disponível
      // na versão atual do Clerk Flutter
      throw UnimplementedError('Funcionalidade não implementada no Clerk Flutter');
    } catch (e) {
      throw Exception('Erro ao enviar email de redefinição: $e');
    }
  }
  
  /// Verifica se um email já está em uso
  static Future<bool> isEmailInUse(String email) async {
    try {
      // Implementação simplificada - esta funcionalidade pode não estar disponível
      // na versão atual do Clerk Flutter
      // Por enquanto, sempre retorna false para permitir o cadastro
      return false;
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }
  
  /// Cria uma nova conta com email e senha
  static Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      // Implementação simplificada - esta funcionalidade deve ser implementada
      // usando os componentes de UI do Clerk Flutter
      throw UnimplementedError('Use os componentes de UI do Clerk para cadastro');
    } catch (e) {
      throw Exception('Erro ao criar conta: $e');
    }
  }
  
  /// Faz login com Google usando Clerk
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Por enquanto, implementação simplificada
      // O Clerk Flutter ainda está em desenvolvimento
      throw UnimplementedError('Login com Google não implementado ainda no Clerk Flutter');
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  /// Faz login com Apple usando Clerk
  static Future<void> signInWithApple(BuildContext context) async {
    try {
      // Por enquanto, implementação simplificada
      // O Clerk Flutter ainda está em desenvolvimento
      throw UnimplementedError('Login com Apple não implementado ainda no Clerk Flutter');
    } catch (e) {
      throw Exception('Erro ao fazer login com Apple: $e');
    }
  }

  /// Faz login com Facebook usando Clerk
  static Future<void> signInWithFacebook(BuildContext context) async {
    try {
      // Por enquanto, implementação simplificada
      // O Clerk Flutter ainda está em desenvolvimento
      throw UnimplementedError('Login com Facebook não implementado ainda no Clerk Flutter');
    } catch (e) {
      throw Exception('Erro ao fazer login com Facebook: $e');
    }
  }
}