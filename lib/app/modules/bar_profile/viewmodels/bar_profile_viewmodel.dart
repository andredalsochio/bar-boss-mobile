import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/repositories/bar_repository.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// ViewModel para gerenciar o perfil do bar
class BarProfileViewModel extends ChangeNotifier {
  final BarRepository _barRepository;
  final AuthViewModel _authViewModel;

  BarProfileViewModel({
    required BarRepository barRepository,
    required AuthViewModel authViewModel,
  })  : _barRepository = barRepository,
        _authViewModel = authViewModel;

  BarModel? _bar;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  BarModel? get bar => _bar;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBar => _bar != null;

  /// Carrega os dados do bar atual
  Future<void> loadBarProfile() async {
    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authViewModel.currentUser;
      if (currentUser == null) {
        _setError('Usuário não autenticado');
        return;
      }

      // Busca o bar do usuário atual
      final userBars = await _barRepository.getBarsByCreatedByUid(currentUser.uid);
      if (userBars.isNotEmpty) {
        _bar = userBars.first;
      } else {
        _setError('Nenhum bar encontrado para este usuário');
      }
    } catch (e) {
      _setError('Erro ao carregar perfil do bar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza os dados do bar
  Future<void> updateBarProfile(BarModel updatedBar) async {
    _setLoading(true);
    _clearError();

    try {
      await _barRepository.updateBar(updatedBar);
      _bar = updatedBar;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao atualizar perfil do bar: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }


}