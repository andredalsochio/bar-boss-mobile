import 'package:flutter/foundation.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// ViewModel para a tela inicial
class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BarRepository _barRepository;

  // Estado do perfil
  BarModel? _currentBar;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Estado do card de completude
  bool _isProfileCompleteCardDismissed = false;

  HomeViewModel({
    required AuthRepository authRepository,
    required BarRepository barRepository,
  }) : _authRepository = authRepository,
       _barRepository = barRepository;

  // Getters
  BarModel? get currentBar => _currentBar;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProfileCompleteCardDismissed => _isProfileCompleteCardDismissed;
  
  // Verifica se o perfil está completo
  bool get isProfileComplete => _currentBar?.isProfileComplete ?? false;
  
  // Calcula quantos passos estão completos (X/2)
  int get completedSteps {
    if (_currentBar == null) return 0;
    int steps = 0;
    if (_currentBar!.hasCompleteContacts) steps++;
    if (_currentBar!.hasCompleteAddress) steps++;
    return steps;
  }
  
  // Verifica se deve mostrar o card de completude
  bool get shouldShowProfileCompleteCard => 
      !isProfileComplete && !_isProfileCompleteCardDismissed;

  /// Carrega os dados do bar atual
  Future<void> loadCurrentBar() async {
    try {
      _setLoading(true);
      _clearError();
      
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final bars = await _barRepository.getBarsByOwner(currentUser.uid);
      if (bars.isNotEmpty) {
        _currentBar = bars.first; // Assume que o usuário tem apenas um bar
        notifyListeners();
      } else {
        // Se não encontrou por owner, tenta por membership
        final memberBars = await _barRepository.listBarsByMembership(currentUser.uid);
        if (memberBars.isNotEmpty) {
          _currentBar = memberBars.first;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError(e.toString());
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