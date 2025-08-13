import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/modules/auth/services/auth_service.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/repositories/bar_repository.dart';

/// Estados possíveis da autenticação
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// ViewModel para a tela de login
class AuthViewModel extends ChangeNotifier {
  final BarRepository _barRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  AuthViewModel({
    required BarRepository barRepository,
  }) : _barRepository = barRepository {
    _authSubscription = AuthService.authStateChanges.listen((user) {
      _setState(user != null ? AuthState.authenticated : AuthState.unauthenticated);
    });
  }
  
  /// Estado atual da autenticação
  AuthState get state => _state;
  
  /// Mensagem de erro
  String? get errorMessage => _errorMessage;
  
  /// Indica se está carregando
  bool get isLoading => _isLoading;
  
  /// Indica se o usuário está autenticado
  bool isAuthenticated(BuildContext context) => AuthService.isAuthenticated();
  
  /// Retorna o ID do usuário atual
  String? getUserId(BuildContext context) => AuthService.currentUserId;
  
  /// Retorna o e-mail do usuário atual
  String? getUserEmail(BuildContext context) => AuthService.currentUserEmail;
  
  /// Retorna o nome do usuário atual
  String? getUserName(BuildContext context) => AuthService.currentUserName;
  
  /// Faz login com e-mail e senha
  Future<void> loginWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      await AuthService.signInWithEmailAndPassword(email, password);
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com e-mail. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Google
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      _setLoading(true);
      _clearError();
      await AuthService.signInWithGoogle();
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Google. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz logout
  Future<void> logout(BuildContext context) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.signOut();
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError(AppStrings.logoutErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz logout (método alternativo com contexto)
  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.signOut();
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError(AppStrings.logoutErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(AppStrings.resetPasswordErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Verifica se o usuário tem um bar cadastrado
  Future<bool> hasBarRegistered(BuildContext context) async {
    final email = getUserEmail(context);
    if (email?.isNotEmpty != true) {
      return false;
    }
    
    try {
      final bar = await _barRepository.getBarByEmail(email!);
      return bar != null;
    } catch (e) {
      debugPrint('Erro ao verificar bar: $e');
      return false;
    }
  }
  
  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Define o estado da autenticação
  void _setState(AuthState state) {
    _state = state;
    notifyListeners();
  }
  
  /// Define a mensagem de erro
  void _setError(String message) {
    _errorMessage = message;
    _state = AuthState.error;
    notifyListeners();
  }
  
  /// Limpa a mensagem de erro
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Faz login com Apple
  Future<void> loginWithApple(BuildContext context) async {
    try {
      _setLoading(true);
      _clearError();
      await AuthService.signInWithApple();
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Apple. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Facebook
  Future<void> loginWithFacebook(BuildContext context) async {
    try {
      _setLoading(true);
      _clearError();
      await AuthService.signInWithFacebook();
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Facebook. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }


  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}