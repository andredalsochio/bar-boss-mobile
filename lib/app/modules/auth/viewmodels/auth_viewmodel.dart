import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';

/// Estados possíveis da autenticação
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// ViewModel para a tela de login
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepositoryDomain _barRepository;
  final UserRepository _userRepository;

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  AuthUser? _currentUser;

  AuthViewModel({
    required AuthRepository authRepository,
    required BarRepositoryDomain barRepository,
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
      final existingUser = await _userRepository.getMe();
      
      if (existingUser == null) {
        // Criar novo documento do usuário
        final now = DateTime.now();
        final newUser = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          providers: user.providerIds, // Usar providers reais do usuário
          currentBarId: null,
          createdAt: now,
          lastLoginAt: now,
          completedFullRegistration: false,
        );
        
        await _userRepository.upsert(newUser);
        debugPrint('✅ Documento do usuário criado: ${user.uid}');
      } else {
        // Atualizar lastLoginAt para usuários existentes
        final updatedUser = existingUser.copyWith(
          lastLoginAt: DateTime.now(),
        );
        await _userRepository.upsert(updatedUser);
        debugPrint('✅ Documento do usuário atualizado: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar/atualizar documento do usuário: $e');
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
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return false;
      
      final userProfile = await _userRepository.getMe();
      if (userProfile?.currentBarId != null) {
        return true;
      }
      
      // Fallback: verificar se tem bars cadastrados
      final bars = await _barRepository.listMyBars(currentUser.uid).first;
      return bars.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar bar: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário logou via provedor social
  bool get isFromSocialProvider {
    if (_currentUser == null) return false;
    
    final socialProviders = ['google.com', 'apple.com', 'facebook.com'];
    return _currentUser!.providerIds.any((provider) => 
        socialProviders.contains(provider));
  }
  
  /// Obtém o perfil do usuário atual
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      return await _userRepository.getMe();
    } catch (e) {
      debugPrint('Erro ao obter perfil do usuário: $e');
      return null;
    }
  }
  
  /// Verifica se deve mostrar o banner de completar cadastro
  Future<bool> shouldShowProfileCompleteCard() async {
    if (!isFromSocialProvider) return false;
    
    try {
      final profile = await getCurrentUserProfile();
      if (profile == null) return true;
      
      // Para login social, mostrar banner se não completou o registro completo
      return !profile.completedFullRegistration;
    } catch (e) {
      debugPrint('Erro ao verificar completude do perfil: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário pode criar eventos
  Future<bool> canCreateEvent() async {
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return false;
      
      // Verifica se tem currentBarId
      final userProfile = await _userRepository.getMe();
      if (userProfile?.currentBarId != null) {
        return true;
      }
      
      // Verifica se é membro de algum bar
      final bars = await _barRepository.listMyBars(currentUser.uid).first;
      return bars.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar permissão para criar evento: $e');
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
