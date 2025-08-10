import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  
  AuthViewModel({
    required BarRepository barRepository,
  }) : _barRepository = barRepository {
    _checkInitialAuthState();
  }
  
  /// Estado atual da autenticação
  AuthState get state => _state;
  
  /// Mensagem de erro
  String? get errorMessage => _errorMessage;
  
  /// Indica se está carregando
  bool get isLoading => _isLoading;
  
  /// Indica se o usuário está autenticado
  bool isAuthenticated(BuildContext context) => AuthService.isAuthenticated(context);
  
  /// Retorna o ID do usuário atual
  String? getUserId(BuildContext context) => AuthService.getCurrentUserId(context);
  
  /// Retorna o e-mail do usuário atual
  String? getUserEmail(BuildContext context) => AuthService.getCurrentUserEmail(context);
  
  /// Retorna o nome do usuário atual
  String? getUserName(BuildContext context) => AuthService.getCurrentUserName(context);
  
  /// Verifica o estado inicial da autenticação
  Future<void> _checkInitialAuthState() async {
    _setLoading(true);
    try {
      // Estado inicial será verificado na UI com context
      _setState(AuthState.initial);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com e-mail e senha
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Login será implementado via Clerk UI components
      // Por enquanto, apenas simula sucesso
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError(AppStrings.loginErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Login com Google será implementado via Clerk UI components
      // Por enquanto, apenas simula sucesso
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError(AppStrings.loginErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Apple
  Future<void> signInWithApple() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Login com Apple será implementado via Clerk UI components
      // Por enquanto, apenas simula sucesso
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError(AppStrings.loginErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Facebook
  Future<void> signInWithFacebook() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Login com Facebook será implementado via Clerk UI components
      // Por enquanto, apenas simula sucesso
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError(AppStrings.loginErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz logout
  Future<void> logout(BuildContext context) async {
    _setLoading(true);
    _clearError();
    
    try {
      await AuthService.signOut(context);
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
      await AuthService.signOut(context);
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
  Future<void> loginWithApple() async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Implementar login com Apple usando Clerk
      // await AuthService.signInWithApple();
      
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Apple: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Facebook
  Future<void> loginWithFacebook() async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Implementar login com Facebook usando Clerk
      // await AuthService.signInWithFacebook();
      
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Facebook: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com email e senha
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Implementar login com email e senha usando Clerk
      // await AuthService.signInWithEmailAndPassword(email, password);
      
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Faz login com Google
  Future<void> loginWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Implementar login com Google usando Clerk
      // await AuthService.signInWithGoogle();
      
      _setState(AuthState.authenticated);
    } catch (e) {
      _setError('Erro ao fazer login com Google: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}