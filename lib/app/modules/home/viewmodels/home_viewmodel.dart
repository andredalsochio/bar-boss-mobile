import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// ViewModel para a tela inicial
class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepositoryDomain _barRepository;

  // Estado do perfil
  BarModel? _currentBar;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Estado do card de completude
  bool _isProfileCompleteCardDismissed = false;
  
  // Propriedades para controle de fluxo de completude
  List<BarModel> _userBars = [];
  
  // Stream subscription para bares
  StreamSubscription<List<BarModel>>? _barsSubscription;

  HomeViewModel({
    required AuthRepository authRepository,
    required BarRepositoryDomain barRepository,
  }) : _authRepository = authRepository,
       _barRepository = barRepository;
       
  @override
  void dispose() {
    _barsSubscription?.cancel();
    super.dispose();
  }

  // Getters
  BarModel? get currentBar => _currentBar;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProfileCompleteCardDismissed => _isProfileCompleteCardDismissed;
  
  // Verifica se o usuário tem pelo menos um bar
  bool get hasBar => _userBars.isNotEmpty;
  
  // Retorna o ID do bar atual (se houver)
  String? get currentBarId => _currentBar?.id;
  
  // Calcula quantos passos estão completos (0, 1 ou 2)
  int get profileStepsDone {
    if (_currentBar == null) return 0;
    int steps = 0;
    if (_currentBar!.hasCompleteContacts) steps++;
    if (_currentBar!.hasCompleteAddress) steps++;
    return steps;
  }
  
  // Verifica se pode criar eventos (tem bar E perfil completo)
  bool get canCreateEvent => hasBar && profileStepsDone == 2;
  
  // Verifica se o perfil está completo
  bool get isProfileComplete => _currentBar?.isProfileComplete ?? false;
  
  // Calcula quantos passos estão completos (X/2) - mantido para compatibilidade
  int get completedSteps => profileStepsDone;
  
  // Verifica se deve mostrar o card de completude
  bool get shouldShowProfileCompleteCard => 
      profileStepsDone < 2 && !_isProfileCompleteCardDismissed;

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
          debugPrint('🏠 DEBUG Home: hasBar=${hasBar}, profileStepsDone=${profileStepsDone}, canCreateEvent=${canCreateEvent}, currentBarId=${currentBarId}');
          
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
}