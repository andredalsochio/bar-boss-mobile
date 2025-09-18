import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/data/firebase/firebase_image_storage_repository.dart';

/// ViewModel para gerenciar o perfil do bar
class BarProfileViewModel extends ChangeNotifier {
  final BarRepositoryDomain _barRepository;
  final AuthViewModel _authViewModel;
  final FirebaseImageStorageRepository _imageStorageRepository;

  BarProfileViewModel({
    required BarRepositoryDomain barRepository,
    required AuthViewModel authViewModel,
    FirebaseImageStorageRepository? imageStorageRepository,
  })  : _barRepository = barRepository,
        _authViewModel = authViewModel,
        _imageStorageRepository = imageStorageRepository ?? FirebaseImageStorageRepository();

  BarModel? _bar;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _uploadMessage;

  // Getters
  BarModel? get bar => _bar;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  String? get uploadMessage => _uploadMessage;
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

      debugPrint('🔍 [BarProfileViewModel] Carregando perfil do bar para usuário: ${currentUser.uid}');
      debugPrint('🔍 [BarProfileViewModel] Email verificado: ${currentUser.emailVerified}');
      debugPrint('🔍 [BarProfileViewModel] Email: ${currentUser.email}');
      
      // Busca o bar do usuário atual via membership usando Stream (mesmo método do HomeViewModel)
      final userBarsStream = _barRepository.listMyBars(currentUser.uid);
      final userBars = await userBarsStream.first;
      
      debugPrint('🔍 [BarProfileViewModel] Encontrados ${userBars.length} bares');
      for (int i = 0; i < userBars.length; i++) {
        debugPrint('🔍 [BarProfileViewModel] Bar $i: id=${userBars[i].id}, name=${userBars[i].name}');
      }
      
      if (userBars.isNotEmpty) {
        _bar = userBars.first;
        debugPrint('✅ [BarProfileViewModel] Perfil carregado: ${_bar?.name ?? "Nenhum bar encontrado"}');
      } else {
        debugPrint('❌ [BarProfileViewModel] Nenhum bar encontrado para o usuário ${currentUser.uid}');
        _setError('Nenhum bar encontrado para este usuário');
      }
    } catch (e) {
      debugPrint('❌ [BarProfileViewModel] Erro ao carregar perfil: $e');
      _setError('Erro ao carregar perfil do bar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Faz upload da foto de perfil do bar
  Future<void> uploadProfilePhoto(File imageFile) async {
    try {
      _setUploadingPhoto(true);
      _clearUploadMessage();
      _clearError();

      if (_bar == null) {
        throw Exception('Nenhum bar encontrado para atualizar');
      }

      debugPrint('📸 [BarProfileViewModel] Iniciando upload da foto de perfil para bar: ${_bar!.id}');
      
      // Define o caminho da imagem no Storage
      final imagePath = 'bars/${_bar!.id}/profile/avatar.jpg';
      
      // Faz upload da imagem
      final photoUrl = await _imageStorageRepository.uploadImage(
        imageFile,
        imagePath,
        metadata: {
          'barId': _bar!.id,
          'type': 'profile_photo',
        },
      );

      if (photoUrl == null) {
        throw Exception('Falha no upload da imagem');
      }

      debugPrint('✅ [BarProfileViewModel] Upload concluído: $photoUrl');
      
      // Atualiza o bar com a nova URL da foto
       final updatedBar = _bar!.copyWith(logoUrl: photoUrl);
       await updateBarProfile(updatedBar);
      
      _setUploadMessage('Foto de perfil atualizada com sucesso!');
      
      debugPrint('✅ [BarProfileViewModel] Foto de perfil atualizada no Firestore');
      
    } catch (e) {
      debugPrint('❌ [BarProfileViewModel] Erro no upload da foto: $e');
      _setError('Erro ao atualizar foto de perfil: $e');
    } finally {
      _setUploadingPhoto(false);
    }
  }

  /// Atualiza os dados do bar
  Future<void> updateBarProfile(BarModel updatedBar) async {
    _setLoading(true);
    _clearError();

    try {
      await _barRepository.update(updatedBar);
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

  void _setUploadingPhoto(bool uploading) {
    _isUploadingPhoto = uploading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setUploadMessage(String message) {
    _uploadMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearUploadMessage() {
    _uploadMessage = null;
    notifyListeners();
  }


}