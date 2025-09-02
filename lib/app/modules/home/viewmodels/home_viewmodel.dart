import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// ViewModel para a tela inicial
class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepositoryDomain _barRepository;
  final UserRepository _userRepository;
  final EventRepositoryDomain _eventRepository;
  final AuthViewModel _authViewModel;

  // Estado do perfil
  BarModel? _currentBar;
  UserProfile? _currentUserProfile;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Estado do card de completude
  bool _isProfileCompleteCardDismissed = false;
  
  // Propriedades para controle de fluxo de completude
  List<BarModel> _userBars = [];
  
  // Eventos
  List<EventModel> _upcomingEvents = [];
  EventModel? _nextEvent;
  
  // Stream subscriptions
  StreamSubscription<List<BarModel>>? _barsSubscription;
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  HomeViewModel({
    required AuthRepository authRepository,
    required BarRepositoryDomain barRepository,
    required UserRepository userRepository,
    required EventRepositoryDomain eventRepository,
    required AuthViewModel authViewModel,
  }) : _authRepository = authRepository,
       _barRepository = barRepository,
       _userRepository = userRepository,
       _eventRepository = eventRepository,
       _authViewModel = authViewModel;
       
  @override
  void dispose() {
    _barsSubscription?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

 // Getters
  BarModel? get currentBar => _currentBar;
  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BarModel> get userBars => _userBars;
  bool get isProfileCompleteCardDismissed => _isProfileCompleteCardDismissed;
  
  // Getters para eventos
  List<EventModel> get upcomingEvents => _upcomingEvents;
  EventModel? get nextEvent => _nextEvent;
  // Verifica se o usuário tem pelo menos um bar
  bool get hasBar => _userBars.isNotEmpty;
  
  // Retorna o ID do bar atual (se houver)
  String? get currentBarId => _currentBar?.id;
  
  // Calcula quantos passos estão completos (0, 1 ou 2)
  int get profileStepsDone {
    if (_currentUserProfile == null) return 0;
    
    int stepsCompleted = 0;
    
    // Passo 1: Informações de contato
    if (_currentBar != null) {
      final hasStep1Complete = _currentBar!.cnpj.isNotEmpty &&
          _currentBar!.name.isNotEmpty &&
          _currentBar!.responsibleName.isNotEmpty &&
          _currentBar!.contactEmail.isNotEmpty &&
          _currentBar!.contactPhone.isNotEmpty;
      
      if (hasStep1Complete) {
        stepsCompleted = 1;
        
        // Passo 2: Endereço
        if (_currentBar!.hasCompleteAddress) {
          stepsCompleted = 2;
        }
      }
    }
    
    return stepsCompleted;
  }
  
  // Verifica se pode criar eventos (tem bar - perfil não bloqueia mais)
  bool get canCreateEvent => hasBar;
  
  // Verifica se o perfil está completo
  bool get isProfileComplete => _currentBar?.isProfileComplete ?? false;
  
  // Calcula quantos passos estão completos (X/2) - atualizado para 2 passos
  int get completedSteps => profileStepsDone;
  
  // Total de passos do cadastro
  int get totalSteps => 2;
  
/// Função centralizada para verificar se o perfil do usuário está completo
  /// Verifica todos os campos obrigatórios dos Passos 1, 2 e 3
  /// Campos obrigatórios: cnpj, nome do bar, responsibleName, contactEmail, contactPhone, address (exceto complement), senha
  /// Campo opcional: complement
  bool isUserProfileComplete() {
    // Primeira verificação: se completedFullRegistration == true, perfil está completo
    if (_currentUserProfile?.completedFullRegistration == true) {
      debugPrint('🔍 isUserProfileComplete: true - completedFullRegistration=true');
      return true;
    }
    
    // Se não tem bar, perfil não está completo
    if (_currentBar == null) {
      debugPrint('🔍 isUserProfileComplete: false - sem bar cadastrado');
      return false;
    }
    
    final bar = _currentBar!;
    
    // Verifica se tem currentBarId (necessário para perfil completo)
    if (_currentUserProfile?.currentBarId == null) {
      debugPrint('🔍 isUserProfileComplete: false - sem currentBarId');
      return false;
    }
    
    // Verifica campos obrigatórios do Passo 1 (contatos)
    final hasValidContacts = bar.cnpj.isNotEmpty &&
        bar.name.isNotEmpty &&
        bar.responsibleName.isNotEmpty &&
        bar.contactEmail.isNotEmpty &&
        bar.contactPhone.isNotEmpty;
    
    // Verifica campos obrigatórios do Passo 2 (endereço - complement é opcional)
    final hasValidAddress = bar.address.cep.isNotEmpty &&
        bar.address.street.isNotEmpty &&
        bar.address.number.isNotEmpty &&
        bar.address.state.isNotEmpty &&
        bar.address.city.isNotEmpty;
        // complement é opcional, não verificamos
    
    // Verifica se tem usuário autenticado (Passo 3 - senha já foi criada se chegou até aqui)
    final hasValidAuth = _currentUserProfile != null && _currentUserProfile!.email.isNotEmpty;
    
    final isComplete = hasValidContacts && hasValidAddress && hasValidAuth;
    
    debugPrint('🔍 isUserProfileComplete: $isComplete');
    debugPrint('🔍   - completedFullRegistration: ${_currentUserProfile?.completedFullRegistration}');
    debugPrint('🔍   - hasValidContacts: $hasValidContacts');
    debugPrint('🔍   - hasValidAddress: $hasValidAddress');
    debugPrint('🔍   - hasValidAuth: $hasValidAuth');
    debugPrint('🔍   - currentBarId: ${_currentUserProfile?.currentBarId}');
    
    return isComplete;
  }
  
  // Verifica se deve mostrar o card de completude
  bool get shouldShowProfileCompleteCard {
    final dismissed = _isProfileCompleteCardDismissed;
    final completedReg = _currentUserProfile?.completedFullRegistration;
    final isFromSocial = _authViewModel.isFromSocialProvider;
    
    // Verifica quantos passos foram completados (0-2)
    final stepsCompleted = profileStepsDone;
    final allStepsComplete = stepsCompleted >= 2;
    
    debugPrint('🏠 DEBUG Banner: stepsCompleted=$stepsCompleted/2, allStepsComplete=$allStepsComplete, dismissed=$dismissed, completedFullRegistration=$completedReg, isFromSocial=$isFromSocial');
    
    // Nova lógica do banner:
    // - Se completedFullRegistration == true (todos os 2 passos concluídos), nunca mostrar banner
    // - Se todos os 2 passos estão completos, nunca mostrar banner
    // - Se foi dispensado pelo usuário, não mostrar banner
    // - Caso contrário, mostrar banner se não completou todos os passos
    final shouldShow = !allStepsComplete && !dismissed && (completedReg != true);
    debugPrint('🏠 DEBUG Banner: shouldShowProfileCompleteCard=$shouldShow');
    
    return shouldShow;
  }

  /// Carrega o perfil do usuário e dados relacionados
  Future<void> loadUserProfile() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Carrega o UserProfile
      final userProfile = await _userRepository.getMe();
      _currentUserProfile = userProfile;
      
      debugPrint('HomeViewModel: UserProfile carregado - completedFullRegistration: ${userProfile?.completedFullRegistration}');
      
      // Inicia o stream de bares do usuário
      _startBarsStream();
      
    } catch (e) {
      _setError('Erro ao carregar perfil: $e');
      debugPrint('Erro ao carregar perfil do usuário: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega os dados do bar atual
  Future<void> loadCurrentBar() async {
    try {
      _setLoading(true);
      _clearError();
      
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Carrega bares por membership (fonte da verdade)
      debugPrint('🏠 DEBUG Home: Iniciando carregamento de bares para uid=${currentUser.uid}');
      
      // Cancela subscription anterior se existir
      _barsSubscription?.cancel();
      
      // Escuta mudanças nos bares do usuário
      _barsSubscription = _barRepository.listMyBars(currentUser.uid).listen(
        (bars) {
          _userBars = bars;
          debugPrint('🏠 DEBUG Home: Encontrados ${_userBars.length} bares');
          
          if (_userBars.isNotEmpty) {
            _currentBar = _userBars.first; // Seleciona o primeiro bar
            debugPrint('🏠 DEBUG Home: Bar selecionado: id=${_currentBar!.id}, name=${_currentBar!.name}');
            debugPrint('🏠 DEBUG Home: Profile do bar: contactsComplete=${_currentBar!.profile.contactsComplete}, addressComplete=${_currentBar!.profile.addressComplete}');
          } else {
            _currentBar = null;
            debugPrint('🏠 DEBUG Home: Nenhum bar encontrado - _currentBar definido como null');
          }
          
          // Debug logs conforme especificado
          debugPrint('🏠 DEBUG Home: hasBar=$hasBar, profileStepsDone=$profileStepsDone, canCreateEvent=$canCreateEvent, currentBarId=$currentBarId');
          
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          debugPrint('🏠 ERROR Home: Erro ao carregar bares: $error');
          _setError('Erro ao carregar dados do bar: $error');
          _setLoading(false);
        },
       );
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('❌ DEBUG Home: Erro ao carregar bar - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Dispensa o card de completude por esta sessão
  void dismissProfileCompleteCard() {
    _isProfileCompleteCardDismissed = true;
    notifyListeners();
  }

  /// Recarrega os dados do bar (útil após atualização do perfil)
  Future<void> refreshBarData() async {
    await loadCurrentBar();
  }

  /// Recarrega os dados do usuário e bar (útil após atualização do perfil)
  Future<void> refreshUserData() async {
    await loadUserProfile();
  }

  // Métodos auxiliares para gerenciar o estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }



  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Inicia o stream de bares do usuário
  void _startBarsStream() {
    _barsSubscription?.cancel();
    
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      _barsSubscription = _barRepository.listMyBars(currentUser.uid).listen(
        (bars) {
          _userBars = bars;
          _currentBar = bars.isNotEmpty ? bars.first : null;
          debugPrint('HomeViewModel: Bares carregados: ${bars.length}');
          
          // Inicia o stream de eventos quando temos um bar
          if (_currentBar != null) {
            _startEventsStream(_currentBar!.id);
          } else {
            _clearEvents();
          }
          
          notifyListeners();
        },
        onError: (error) {
          _setError('Erro ao carregar bares: $error');
          debugPrint('Erro no stream de bares: $error');
        },
      );
    }
  }
  
  /// Inicia o stream de eventos do bar atual
  void _startEventsStream(String barId) {
    _eventsSubscription?.cancel();
    
    _eventsSubscription = _eventRepository.upcomingByBar(barId).listen(
      (events) {
        _upcomingEvents = events;
        _nextEvent = events.isNotEmpty ? events.first : null;
        debugPrint('HomeViewModel: Eventos carregados: ${events.length}');
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erro no stream de eventos: $error');
        // Não definir erro global para eventos, apenas log
      },
    );
  }
  
  /// Limpa a lista de eventos
  void _clearEvents() {
    _eventsSubscription?.cancel();
    _upcomingEvents = [];
    _nextEvent = null;
    notifyListeners();
  }
}