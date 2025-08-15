import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository.dart';
import 'package:bar_boss_mobile/app/modules/auth/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/modules/auth/models/user_model.dart';

/// Estados possíveis da autenticação
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// ViewModel para a tela de login
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepository _barRepository;
  final UserRepository _userRepository;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  AuthUser? _currentUser;

  AuthViewModel({
    required AuthRepository authRepository,
    required BarRepository barRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _barRepository = barRepository,
       _userRepository = userRepository {
    _checkInitialAuthState();
    _subscribeToAuthChanges();
  }

  /// Estado atual da autenticação
  AuthState get state => _state;

  /// Mensagem de erro
  String? get errorMessage => _errorMessage;

  /// Indica se está carregando
  bool get isLoading => _isLoading;

  /// Usuário atual
  AuthUser? get currentUser => _currentUser;

  /// Indica se o usuário está autenticado
  bool get isAuthenticated => _currentUser != null;

  /// Retorna o ID do usuário atual
  String? get userId => _currentUser?.uid;

  /// Retorna o e-mail do usuário atual
  String? get userEmail => _currentUser?.email;

  /// Retorna o nome do usuário atual
  String? get userName => _currentUser?.displayName;

  /// Verifica o estado inicial da autenticação
  Future<void> _checkInitialAuthState() async {
    _setLoading(true);
    try {
      _currentUser = _authRepository.currentUser;
      if (_currentUser != null) {
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  StreamSubscription<AuthUser?>? _authSub;

  void _subscribeToAuthChanges() {
    _authSub = _authRepository.authStateChanges().listen((user) async {
      _currentUser = user;
      if (user != null) {
        // Garantir que o documento do usuário existe no Firestore
        await _ensureUserDocumentExists(user);
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    });
  }

  /// Garante que o documento do usuário existe no Firestore
  Future<void> _ensureUserDocumentExists(AuthUser user) async {
    try {
      // Verificar se o usuário já existe
      final existingUser = await _userRepository.getUserById(user.uid);
      
      if (existingUser == null) {
        // Criar novo documento do usuário
        final now = DateTime.now();
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          providers: ['google'], // Assumindo login social por padrão
          currentBarId: null,
          createdAt: now,
          lastLoginAt: now,
        );
        
        await _userRepository.createUser(newUser);
        debugPrint('✅ Documento do usuário criado: ${user.uid}');
      } else {
        debugPrint('✅ Documento do usuário já existe: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar documento do usuário: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Faz login com e-mail e senha
  Future<void> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      final result = await _authRepository.signInWithEmail(email, password);
      if (result.isSuccess) {
        _currentUser = result.user;
        _setState(AuthState.authenticated);
      } else {
        _setError(result.errorMessage ?? 'Erro ao fazer login com e-mail.');
      }
    } catch (e) {
      _setError('Erro ao fazer login com e-mail. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Google
  Future<void> loginWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      final result = await _authRepository.signInWithGoogle();
      if (result.isSuccess) {
        _currentUser = result.user;
        _setState(AuthState.authenticated);
      } else {
        _setError(result.errorMessage ?? 'Erro ao fazer login com Google.');
      }
    } catch (e) {
      _setError('Erro ao fazer login com Google. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Faz logout
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError(AppStrings.logoutErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Faz logout (método alternativo)
  Future<void> signOut() async {
    await logout();
  }

  /// Envia e-mail de redefinição de senha
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(AppStrings.resetPasswordErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifica se o usuário tem um bar cadastrado
  Future<bool> hasBarRegistered() async {
    final email = userEmail;
    if (email?.isNotEmpty != true) {
      return false;
    }

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return false;
      
      final bars = await _barRepository.listBarsByMembership(
        currentUser.uid,
      );
      return bars.isNotEmpty;
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
      final result = await _authRepository.signInWithApple();
      if (result.isSuccess) {
        _currentUser = result.user;
        _setState(AuthState.authenticated);
      } else {
        _setError(result.errorMessage ?? 'Erro ao fazer login com Apple.');
      }
    } catch (e) {
      _setError('Erro ao fazer login com Apple. Por favor, tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Facebook
  Future<void> loginWithFacebook() async {
    try {
      _setLoading(true);
      _clearError();
      final result = await _authRepository.signInWithFacebook();
      if (result.isSuccess) {
        _currentUser = result.user;
        _setState(AuthState.authenticated);
      } else {
        _setError(result.errorMessage ?? 'Erro ao fazer login com Facebook.');
      }
    } catch (e) {
      _setError(
        'Erro ao fazer login com Facebook. Por favor, tente novamente.',
      );
    } finally {
      _setLoading(false);
    }
  }
}
