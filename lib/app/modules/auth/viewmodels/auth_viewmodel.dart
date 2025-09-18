import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/auth_user.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';

/// Estados possíveis da autenticação
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Tipos de fluxo de autenticação
enum AuthFlowType { emailPassword, social }

/// Estados específicos para verificação de email
enum EmailVerificationState { notRequired, pending, verified }

/// ViewModel para autenticação com fluxos separados conforme BUSINESS_RULES_AUTH.md v2.0
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepositoryDomain _barRepository;
  final UserRepository _userRepository;

  // Estados principais
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  AuthUser? _currentUser;
  
  // Estados específicos dos fluxos
  AuthFlowType? _currentFlowType;
  EmailVerificationState _emailVerificationState = EmailVerificationState.notRequired;
  bool _hasCompletedFullRegistration = false;
  
  // Controle de verificação de email
  Timer? _emailVerificationTimer;
  bool _isCheckingEmailVerification = false;

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

  // === GETTERS PRINCIPAIS ===
  
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

  /// Verifica se o e-mail do usuário atual foi verificado
  bool get isCurrentUserEmailVerified => _currentUser?.emailVerified ?? false;
  
  // === GETTERS ESPECÍFICOS DOS FLUXOS ===
  
  /// Tipo de fluxo atual (email/senha ou social)
  AuthFlowType? get currentFlowType => _currentFlowType;
  
  /// Estado da verificação de email
  EmailVerificationState get emailVerificationState => _emailVerificationState;
  
  /// Indica se o usuário completou o cadastro completo
  bool get hasCompletedFullRegistration => _hasCompletedFullRegistration;
  
  /// Indica se é um usuário de login social (baseado no tipo de fluxo)
  bool get isFromSocialFlow => _currentFlowType == AuthFlowType.social;
  
  /// Indica se precisa verificar email (fluxo email/senha)
  bool get needsEmailVerification => 
      _currentFlowType == AuthFlowType.emailPassword && 
      _emailVerificationState == EmailVerificationState.pending;
  
  /// Indica se pode acessar o app (regras de negócio)
  bool get canAccessApp {
    if (!isAuthenticated) return false;
    
    switch (_currentFlowType) {
      case AuthFlowType.emailPassword:
        // Fluxo email/senha: precisa ter email verificado
        return isCurrentUserEmailVerified;
      case AuthFlowType.social:
        // Fluxo social: acesso imediato, mas pode ter banner de completude
        return true;
      case null:
        return false;
    }
  }
  
  /// Indica se deve mostrar banner de completude (fluxo social)
  bool get shouldShowCompletionBanner => 
      isFromSocialFlow && !_hasCompletedFullRegistration;
  
  /// Indica se está verificando email automaticamente
  bool get isCheckingEmailVerification => _isCheckingEmailVerification;

  /// Verifica o estado inicial da autenticação
  Future<void> _checkInitialAuthState() async {
    _setLoading(true);
    try {
      _currentUser = _authRepository.currentUser;
      if (_currentUser != null) {
        await _determineAuthFlowType();
        await _checkRegistrationCompleteness();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] AuthViewModel.checkAuthState: Erro - $e');
      _setError('Erro ao verificar autenticação. Tente novamente.');
    } finally {
      _setLoading(false);
    }
  }

  /// Determina o tipo de fluxo baseado nos provedores do usuário
  Future<void> _determineAuthFlowType() async {
    if (_currentUser == null) return;
    
    final socialProviders = ['google.com', 'apple.com', 'facebook.com'];
    final hasSocialProvider = _currentUser!.providerIds.any((provider) => 
        socialProviders.contains(provider));
    
    if (hasSocialProvider) {
      _currentFlowType = AuthFlowType.social;
      _emailVerificationState = EmailVerificationState.verified; // Social sempre verificado
      debugPrint('🔄 [AuthViewModel] Fluxo determinado: SOCIAL');
    } else {
      _currentFlowType = AuthFlowType.emailPassword;
      _emailVerificationState = _currentUser!.emailVerified 
          ? EmailVerificationState.verified 
          : EmailVerificationState.pending;
      debugPrint('🔄 [AuthViewModel] Fluxo determinado: EMAIL/SENHA');
    }
  }

  /// Verifica se o usuário completou o cadastro completo
  Future<void> _checkRegistrationCompleteness() async {
    try {
      final userProfile = await _userRepository.getMe();
      _hasCompletedFullRegistration = userProfile?.completedFullRegistration ?? false;
      debugPrint('🔄 [AuthViewModel] Cadastro completo: $_hasCompletedFullRegistration');
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar completude do cadastro: $e');
      _hasCompletedFullRegistration = false;
    }
  }

  StreamSubscription<AuthUser?>? _authSub;

  void _subscribeToAuthChanges() {
    debugPrint('🟠 [AuthViewModel] Iniciando subscription para authStateChanges...');
    _authSub = _authRepository.authStateChanges().listen((user) async {
      debugPrint('🟠 [AuthViewModel] authStateChanges triggered: user=${user?.email ?? "null"}');
      _currentUser = user;
      if (user != null) {
        debugPrint('🟠 [AuthViewModel] Usuário autenticado, processando fluxo...');
        
        // Garantir que o documento do usuário existe no Firestore
        await _ensureUserDocumentExists(user);
        
        // Determinar tipo de fluxo e estados
        await _determineAuthFlowType();
        await _checkRegistrationCompleteness();
        
        // Iniciar verificação de email se necessário (fluxo email/senha)
        if (_currentFlowType == AuthFlowType.emailPassword && 
            _emailVerificationState == EmailVerificationState.pending) {
          _startEmailVerificationPolling();
        }
        
        debugPrint('🟠 [AuthViewModel] Definindo estado como authenticated...');
        _setState(AuthState.authenticated);
      } else {
        debugPrint('🟠 [AuthViewModel] Usuário não autenticado, limpando estados...');
        _clearAuthStates();
        _setState(AuthState.unauthenticated);
      }
    });
  }

  /// Limpa todos os estados relacionados à autenticação
  void _clearAuthStates() {
    _currentFlowType = null;
    _emailVerificationState = EmailVerificationState.notRequired;
    _hasCompletedFullRegistration = false;
    _stopEmailVerificationPolling();
  }

  /// Garante que o documento do usuário existe no Firestore
  Future<void> _ensureUserDocumentExists(AuthUser user) async {
    debugPrint('🟡 [AuthViewModel] _ensureUserDocumentExists iniciado para: ${user.email}');
    try {
      debugPrint('🟡 [AuthViewModel] Verificando se usuário já existe no Firestore...');
      // Verificar se o usuário já existe
      final existingUser = await _userRepository.getMe();
      
      if (existingUser == null) {
        debugPrint('🟡 [AuthViewModel] Usuário não existe, criando novo documento...');
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
        
        debugPrint('🟡 [AuthViewModel] Salvando novo usuário no Firestore...');
        await _userRepository.upsert(newUser);
        debugPrint('✅ [AuthViewModel] Documento do usuário criado: ${user.uid}');
      } else {
        debugPrint('🟡 [AuthViewModel] Usuário existe, atualizando lastLoginAt...');
        // Atualizar lastLoginAt para usuários existentes
        final updatedUser = existingUser.copyWith(
          lastLoginAt: DateTime.now(),
        );
        await _userRepository.upsert(updatedUser);
        debugPrint('✅ [AuthViewModel] Documento do usuário atualizado: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao criar/atualizar documento do usuário: $e');
    }
  }

  // === MÉTODOS DE VERIFICAÇÃO DE EMAIL ===

  /// Inicia o polling de verificação de email (fluxo email/senha)
  void _startEmailVerificationPolling() {
    if (_emailVerificationTimer?.isActive == true) return;
    
    debugPrint('📧 [AuthViewModel] Iniciando polling de verificação de email...');
    _isCheckingEmailVerification = true;
    notifyListeners();
    
    _emailVerificationTimer = Timer.periodic(
      const Duration(seconds: 3), 
      (timer) => _checkEmailVerificationStatus()
    );
  }

  /// Para o polling de verificação de email
  void _stopEmailVerificationPolling() {
    _emailVerificationTimer?.cancel();
    _emailVerificationTimer = null;
    _isCheckingEmailVerification = false;
    debugPrint('📧 [AuthViewModel] Polling de verificação de email parado');
  }

  /// Verifica o status de verificação de email
  Future<void> _checkEmailVerificationStatus() async {
    try {
      final isVerified = await _authRepository.checkEmailVerified();
      
      if (isVerified) {
        debugPrint('✅ [AuthViewModel] Email verificado com sucesso!');
        _emailVerificationState = EmailVerificationState.verified;
        _stopEmailVerificationPolling();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar status do email: $e');
    }
  }

  /// Reenvia email de verificação
  Future<void> resendVerificationEmail() async {
    try {
      _setLoading(true);
      await _authRepository.sendEmailVerification();
      ToastService.instance.showSuccess(
        message: 'Email de verificação reenviado!',
        title: 'Sucesso',
      );
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao reenviar email: $e');
      ToastService.instance.showError(
        message: 'Erro ao reenviar email de verificação',
        title: 'Erro',
      );
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _stopEmailVerificationPolling();
    super.dispose();
  }

  // === MÉTODOS DE AUTENTICAÇÃO ===

  /// Faz login com e-mail e senha (Fluxo Email/Senha)
  /// Após login bem-sucedido, usuário vai para verificação de email se necessário
  Future<void> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    debugPrint('🔐 [AuthViewModel] Iniciando login EMAIL/SENHA: ${email.substring(0, 3)}***');
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authRepository.signInWithEmail(email, password);
      debugPrint('🔐 [AuthViewModel] Resultado: isSuccess=${result.isSuccess}');
      
      if (result.isSuccess && result.user != null) {
        debugPrint('✅ [AuthViewModel] Login EMAIL/SENHA bem-sucedido!');
        
        // Definir tipo de fluxo
        _currentFlowType = AuthFlowType.emailPassword;
        _currentUser = result.user;
        
        // Verificar status de verificação de email
        final isEmailVerified = result.user!.emailVerified;
        _emailVerificationState = isEmailVerified 
            ? EmailVerificationState.verified 
            : EmailVerificationState.pending;
        
        debugPrint('🔐 [AuthViewModel] Email verificado: $isEmailVerified');
        
        // Se email não verificado, iniciar polling
        if (!isEmailVerified) {
          debugPrint('📧 [AuthViewModel] Email não verificado, iniciando polling...');
          _startEmailVerificationPolling();
        }
        
        _setState(AuthState.authenticated);
        debugPrint('✅ [AuthViewModel] Fluxo EMAIL/SENHA configurado');
        
      } else {
        debugPrint('❌ [AuthViewModel] Falha no login: ${result.errorMessage}');
        final errorMsg = result.errorMessage ?? 'Erro ao fazer login com e-mail.';
        _setError(errorMsg);
        ToastService.instance.showError(
          message: errorMsg,
          title: 'Erro no Login',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Exceção durante login EMAIL/SENHA: $e');
      const errorMsg = 'Erro ao fazer login com e-mail. Por favor, tente novamente.';
      _setError(errorMsg);
      ToastService.instance.showError(
        message: errorMsg,
        title: 'Erro no Login',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Faz login com Google (Fluxo Social)
  /// Acesso imediato ao app, mas pode mostrar banner de completude
  Future<void> loginWithGoogle() async {
    debugPrint('🔵 [AuthViewModel] Iniciando login SOCIAL (Google)...');
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authRepository.signInWithGoogle();
      debugPrint('🔵 [AuthViewModel] Resultado: isSuccess=${result.isSuccess}');
      
      if (result.isSuccess && result.user != null) {
        debugPrint('✅ [AuthViewModel] Login SOCIAL (Google) bem-sucedido!');
        
        // Definir tipo de fluxo
        _currentFlowType = AuthFlowType.social;
        _currentUser = result.user;
        
        // Email sempre verificado em login social
        _emailVerificationState = EmailVerificationState.verified;
        
        // Verificar se completou cadastro completo
        await _checkRegistrationCompleteness();
        
        debugPrint('🔵 [AuthViewModel] Cadastro completo: $_hasCompletedFullRegistration');
        
        _setState(AuthState.authenticated);
        debugPrint('✅ [AuthViewModel] Fluxo SOCIAL configurado');
        
      } else {
        debugPrint('❌ [AuthViewModel] Falha no login: ${result.errorMessage}');
        final errorMsg = result.errorMessage ?? 'Erro ao fazer login com Google.';
        _setError(errorMsg);
        ToastService.instance.showError(
          message: errorMsg,
          title: 'Erro no Login',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Exceção durante login SOCIAL (Google): $e');
      const errorMsg = 'Erro ao fazer login com Google. Por favor, tente novamente.';
      _setError(errorMsg);
      ToastService.instance.showError(
        message: errorMsg,
        title: 'Erro no Login',
      );
    } finally {
      _setLoading(false);
      debugPrint('🔵 [AuthViewModel] Login com Google finalizado (loading=false)');
    }
  }

  /// Faz logout
  Future<void> logout() async {
    debugPrint('🚪 [AuthViewModel] Iniciando logout...');
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🚪 [AuthViewModel] Chamando _authRepository.signOut()...');
      await _authRepository.signOut();
      debugPrint('✅ [AuthViewModel] Logout realizado com sucesso!');
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      debugPrint('✅ [AuthViewModel] Estado alterado para unauthenticated');
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro durante logout: $e');
      _setError(AppStrings.logoutErrorMessage);
      rethrow;
    } finally {
      _setLoading(false);
      debugPrint('🚪 [AuthViewModel] Logout finalizado (loading=false)');
    }
  }

  /// Faz logout (método alternativo)
  Future<void> signOut() async {
    await logout();
  }

  /// Envia e-mail de redefinição de senha
  /// SEMPRE retorna sucesso por questões de segurança (anti-enumeração)
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('📧 [AuthViewModel] Iniciando envio de e-mail de redefinição de senha para: ${email.substring(0, 3)}***');
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📧 [AuthViewModel] Chamando _authRepository.sendPasswordResetEmail...');
      await _authRepository.sendPasswordResetEmail(email);
      debugPrint('✅ [AuthViewModel] Processamento de reset de senha concluído!');
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao processar reset de senha: $e');
      // NÃO definir erro nem relançar exceção por segurança
      // O usuário sempre verá mensagem de sucesso
    } finally {
      _setLoading(false);
      debugPrint('📧 [AuthViewModel] Processamento de reset de senha finalizado (loading=false)');
    }
  }

  /// Verifica se o usuário tem um bar cadastrado
  Future<bool> hasBarRegistered() async {
    debugPrint('🏪 [AuthViewModel] Verificando se usuário tem bar cadastrado...');
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [AuthViewModel] Usuário não autenticado - retornando false');
        return false;
      }
      debugPrint('🏪 [AuthViewModel] Usuário autenticado: ${currentUser.email}');
      
      debugPrint('🏪 [AuthViewModel] Buscando perfil do usuário...');
      final userProfile = await _userRepository.getMe();
      if (userProfile?.currentBarId != null) {
        debugPrint('✅ [AuthViewModel] Usuário tem currentBarId: ${userProfile!.currentBarId}');
        return true;
      }
      debugPrint('🏪 [AuthViewModel] currentBarId é null, verificando bars cadastrados...');
      
      // Fallback: verificar se tem bars cadastrados
      final bars = await _barRepository.listMyBars(currentUser.uid).first;
      final hasBar = bars.isNotEmpty;
      debugPrint('🏪 [AuthViewModel] Resultado da verificação de bars: $hasBar (${bars.length} bars encontrados)');
      return hasBar;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar bar: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário logou via provedor social
  bool get isFromSocialProvider {
    if (_currentUser == null) return false;
    
    // Apenas Google está ativo no momento
    // TODO: Adicionar 'apple.com' e 'facebook.com' quando implementados
    final socialProviders = ['google.com'];
    return _currentUser!.providerIds.any((provider) => 
        socialProviders.contains(provider));
  }
  
  /// Obtém o perfil do usuário atual
  Future<UserProfile?> getCurrentUserProfile() async {
    debugPrint('👤 [AuthViewModel] Obtendo perfil do usuário atual...');
    try {
      final profile = await _userRepository.getMe();
      if (profile != null) {
        debugPrint('✅ [AuthViewModel] Perfil obtido: ${profile.email}');
        debugPrint('👤 [AuthViewModel] currentBarId: ${profile.currentBarId}');
        debugPrint('👤 [AuthViewModel] completedFullRegistration: ${profile.completedFullRegistration}');
      } else {
        debugPrint('❌ [AuthViewModel] Perfil não encontrado');
      }
      return profile;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao obter perfil do usuário: $e');
      return null;
    }
  }
  
  /// Verifica se deve mostrar o banner de completar cadastro
  Future<bool> shouldShowProfileCompleteCard() async {
    debugPrint('🎯 [AuthViewModel] Verificando se deve mostrar banner de completar cadastro...');
    if (!isFromSocialProvider) {
      debugPrint('🎯 [AuthViewModel] Usuário não é de provedor social - não mostrar banner');
      return false;
    }
    debugPrint('🎯 [AuthViewModel] Usuário é de provedor social, verificando completude...');
    
    try {
      final profile = await getCurrentUserProfile();
      if (profile == null) {
        debugPrint('🎯 [AuthViewModel] Perfil não encontrado - mostrar banner');
        return true;
      }
      
      // Para login social, mostrar banner se não completou o registro completo
      final shouldShow = !profile.completedFullRegistration;
      debugPrint('🎯 [AuthViewModel] completedFullRegistration: ${profile.completedFullRegistration}, shouldShow: $shouldShow');
      return shouldShow;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar completude do perfil: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário pode criar eventos
  Future<bool> canCreateEvent() async {
    debugPrint('🎪 [AuthViewModel] Verificando se usuário pode criar eventos...');
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [AuthViewModel] Usuário não autenticado - não pode criar eventos');
        return false;
      }
      debugPrint('🎪 [AuthViewModel] Usuário autenticado: ${currentUser.email}');
      
      // Verifica se tem currentBarId
      debugPrint('🎪 [AuthViewModel] Verificando currentBarId...');
      final userProfile = await _userRepository.getMe();
      if (userProfile?.currentBarId != null) {
        debugPrint('✅ [AuthViewModel] Usuário tem currentBarId: ${userProfile!.currentBarId} - pode criar eventos');
        return true;
      }
      debugPrint('🎪 [AuthViewModel] currentBarId é null, verificando se é membro de algum bar...');
      
      // Verifica se é membro de algum bar
      final bars = await _barRepository.listMyBars(currentUser.uid).first;
      final canCreate = bars.isNotEmpty;
      debugPrint('🎪 [AuthViewModel] Resultado da verificação de membros: $canCreate (${bars.length} bars encontrados)');
      return canCreate;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar permissão para criar evento: $e');
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

  /// TODO: Implementar login com Apple posteriormente
  /*
  /// Faz login com Apple
  Future<void> loginWithApple() async {
    debugPrint('🍎 [AuthViewModel] Iniciando login com Apple...');
    try {
      _setLoading(true);
      _clearError();
      debugPrint('🍎 [AuthViewModel] Chamando _authRepository.signInWithApple()...');
      final result = await _authRepository.signInWithApple();
      debugPrint('🍎 [AuthViewModel] Resultado recebido: isSuccess=${result.isSuccess}');
      
      if (result.isSuccess) {
        debugPrint('✅ [AuthViewModel] Login com Apple bem-sucedido!');
        debugPrint('🍎 [AuthViewModel] Usuário: ${result.user?.email}');
        _currentUser = result.user;
        _setState(AuthState.authenticated);
        // Toast de boas-vindas removido conforme solicitado
        debugPrint('✅ [AuthViewModel] Estado alterado para authenticated');
      } else {
        debugPrint('❌ [AuthViewModel] Falha no login: ${result.errorMessage}');
        final errorMsg = result.errorMessage ?? 'Erro ao fazer login com Apple.';
        _setError(errorMsg);
        ToastService.instance.showError(
          message: errorMsg,
          title: 'Erro no Login',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Exceção durante login com Apple: $e');
      const errorMsg = 'Erro ao fazer login com Apple. Por favor, tente novamente.';
      _setError(errorMsg);
      ToastService.instance.showError(
        message: errorMsg,
        title: 'Erro no Login',
      );
    } finally {
      _setLoading(false);
      debugPrint('🍎 [AuthViewModel] Login com Apple finalizado (loading=false)');
    }
  }
  */

  /// TODO: Implementar login com Facebook posteriormente
  /*
  /// Faz login com Facebook
  Future<void> loginWithFacebook() async {
    debugPrint('📘 [AuthViewModel] Iniciando login com Facebook...');
    try {
      _setLoading(true);
      _clearError();
      debugPrint('📘 [AuthViewModel] Chamando _authRepository.signInWithFacebook()...');
      final result = await _authRepository.signInWithFacebook();
      debugPrint('📘 [AuthViewModel] Resultado recebido: isSuccess=${result.isSuccess}');
      
      if (result.isSuccess) {
        debugPrint('✅ [AuthViewModel] Login com Facebook bem-sucedido!');
        debugPrint('📘 [AuthViewModel] Usuário: ${result.user?.email}');
        _currentUser = result.user;
        _setState(AuthState.authenticated);
        // Toast de boas-vindas removido conforme solicitado
        debugPrint('✅ [AuthViewModel] Estado alterado para authenticated');
      } else {
        debugPrint('❌ [AuthViewModel] Falha no login: ${result.errorMessage}');
        final errorMsg = result.errorMessage ?? 'Erro ao fazer login com Facebook.';
        _setError(errorMsg);
        ToastService.instance.showError(
          message: errorMsg,
          title: 'Erro no Login',
        );
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Exceção durante login com Facebook: $e');
      const errorMsg = 'Erro ao fazer login com Facebook. Por favor, tente novamente.';
      _setError(errorMsg);
      ToastService.instance.showError(
        message: errorMsg,
        title: 'Erro no Login',
      );
    } finally {
      _setLoading(false);
      debugPrint('📘 [AuthViewModel] Login com Facebook finalizado (loading=false)');
    }
  }
  */

  /// Envia e-mail de verificação
  Future<bool> sendEmailVerification() async {
    debugPrint('📧 [AuthViewModel] Iniciando envio de e-mail de verificação...');
    try {
      debugPrint('📧 [AuthViewModel] Chamando _authRepository.sendEmailVerification()...');
      final success = await _authRepository.sendEmailVerification();
      if (success) {
        debugPrint('✅ [AuthViewModel] E-mail de verificação enviado com sucesso!');
      } else {
        debugPrint('⚠️ [AuthViewModel] Falha ao enviar e-mail de verificação');
      }
      return success;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao enviar e-mail de verificação: $e');
      throw Exception('Erro ao enviar e-mail de verificação: $e');
    }
  }

  /// Verifica se o e-mail foi verificado
  Future<bool> checkEmailVerified() async {
    debugPrint('🔍 [AuthViewModel] Verificando status de verificação do e-mail...');
    try {
      debugPrint('🔍 [AuthViewModel] Chamando _authRepository.checkEmailVerified()...');
      final isVerified = await _authRepository.checkEmailVerified();
      debugPrint('🔍 [AuthViewModel] Status de verificação: $isVerified');
      return isVerified;
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao verificar e-mail: $e');
      throw Exception('Erro ao verificar e-mail: $e');
    }
  }

  /// Marca o cadastro como completo após finalizar todos os steps
  /// Usado principalmente no fluxo social
  Future<void> markRegistrationAsComplete() async {
    debugPrint('✅ [AuthViewModel] Marcando cadastro como completo...');
    try {
      if (_currentUser?.uid != null) {
        // Buscar perfil atual e atualizar
        final currentProfile = await _userRepository.getMe();
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(
            completedFullRegistration: true,
          );
          await _userRepository.upsert(updatedProfile);
          _hasCompletedFullRegistration = true;
          notifyListeners();
          debugPrint('✅ [AuthViewModel] Cadastro marcado como completo!');
        }
      }
    } catch (e) {
      debugPrint('❌ [AuthViewModel] Erro ao marcar cadastro como completo: $e');
    }
  }

  /// Limpa todos os estados de autenticação (versão atualizada)
  void _clearAuthStatesUpdated() {
    _currentFlowType = null;
    _emailVerificationState = EmailVerificationState.notRequired;
    _hasCompletedFullRegistration = false;
    _stopEmailVerificationPolling();
    debugPrint('🧹 [AuthViewModel] Estados de autenticação limpos');
  }

  /// Força uma nova verificação da completude do cadastro
  /// Útil após completar steps no fluxo social
  Future<void> refreshRegistrationStatus() async {
    debugPrint('🔄 [AuthViewModel] Atualizando status de cadastro...');
    if (_currentUser?.uid != null) {
      await _checkRegistrationCompleteness();
      notifyListeners();
    }
  }

  /// Getter para saber quantos steps foram completados (para banner)
  int get completedStepsCount {
    if (_hasCompletedFullRegistration) return 3;
    
    // Aqui você pode implementar lógica mais granular
    // verificando quais steps específicos foram completados
    // Por enquanto, retorna 0 se não completou tudo
    return 0;
  }

  /// Getter para mensagem do banner de completude
  String get completionBannerMessage {
    final completed = completedStepsCount;
    return 'Complete seu cadastro ($completed/3)';
  }
}
