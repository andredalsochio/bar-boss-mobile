import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ViewModel para gerenciar as configurações do aplicativo
/// Inclui gerenciamento de tema (claro/escuro/sistema) e outras preferências
class SettingsViewModel extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _defaultTheme = 'system';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  String? _passwordChangeError;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isChangingPassword => _isChangingPassword;
  String? get passwordChangeError => _passwordChangeError;

  /// Inicializa o ViewModel carregando as preferências salvas
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadThemePreference();
    } catch (e) {
      debugPrint('Erro ao carregar preferências: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega a preferência de tema do SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? _defaultTheme;
    _themeMode = _stringToThemeMode(themeString);
  }

  /// Altera o tema do aplicativo
  Future<void> changeTheme(ThemeMode newTheme) async {
    if (_themeMode == newTheme) return;

    _themeMode = newTheme;
    notifyListeners();

    try {
      await _saveThemePreference(newTheme);
    } catch (e) {
      debugPrint('Erro ao salvar preferência de tema: $e');
    }
  }

  /// Salva a preferência de tema no SharedPreferences
  Future<void> _saveThemePreference(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(theme));
  }

  /// Converte string para ThemeMode
  ThemeMode _stringToThemeMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Converte ThemeMode para string
  String _themeModeToString(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Retorna o nome do tema atual para exibição
  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  /// Lista de opções de tema disponíveis
  List<ThemeOption> get themeOptions => [
        ThemeOption(
          mode: ThemeMode.system,
          name: 'Sistema',
          description: 'Segue a configuração do sistema',
          icon: Icons.brightness_auto,
        ),
        ThemeOption(
          mode: ThemeMode.light,
          name: 'Claro',
          description: 'Tema claro sempre ativo',
          icon: Icons.brightness_7,
        ),
        ThemeOption(
          mode: ThemeMode.dark,
          name: 'Escuro',
          description: 'Tema escuro sempre ativo',
          icon: Icons.brightness_2,
        ),
      ];

  /// Verifica se o usuário pode alterar a senha
  /// Todos os usuários podem alterar senha, incluindo os de login social
  bool get canChangePassword {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  /// Retorna o tipo de login do usuário atual
  String get userLoginType {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Desconhecido';

    final providers = user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('google.com')) {
      return 'Google';
    } else if (providers.contains('apple.com')) {
      return 'Apple';
    } else if (providers.contains('facebook.com')) {
      return 'Facebook';
    } else if (providers.contains('password')) {
      return 'Email/Senha';
    }

    return 'Desconhecido';
  }

  /// Verifica se o usuário tem credencial de email/senha vinculada
  bool get hasPasswordProvider {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  /// Força a atualização dos dados do usuário e verifica se tem provedor de senha
  Future<bool> checkHasPasswordProvider() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Recarrega os dados do usuário para garantir informações atualizadas
    await user.reload();
    
    // Verifica novamente após o reload
    final updatedUser = FirebaseAuth.instance.currentUser;
    if (updatedUser == null) return false;
    
    return updatedUser.providerData.any((provider) => provider.providerId == 'password');
  }

  /// Altera a senha do usuário
  /// Para usuários de login social, primeiro vincula credencial de email/senha
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isChangingPassword = true;
      _passwordChangeError = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _passwordChangeError = 'Usuário não encontrado';
        return false;
      }

      if (user.email == null) {
        _passwordChangeError = 'Email do usuário não encontrado';
        return false;
      }

      // Se o usuário já tem provedor de senha, reautentica e atualiza
      if (hasPasswordProvider) {
        // Reautentica o usuário com a senha atual
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Atualiza a senha
        await user.updatePassword(newPassword);
      } else {
        // Para usuários de login social, vincula credencial de email/senha
        // Neste caso, currentPassword será ignorado e newPassword será a primeira senha
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPassword,
        );
        
        // Vincula a credencial de email/senha ao usuário
        await user.linkWithCredential(credential);
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          _passwordChangeError = 'Senha atual incorreta';
          break;
        case 'weak-password':
          _passwordChangeError = 'A nova senha é muito fraca (mínimo 6 caracteres)';
          break;
        case 'requires-recent-login':
          _passwordChangeError = 'Por segurança, faça login novamente antes de alterar a senha';
          break;
        case 'email-already-in-use':
          _passwordChangeError = 'Este email já está em uso por outra conta';
          break;
        case 'provider-already-linked':
          _passwordChangeError = 'Credencial de email/senha já vinculada';
          break;
        case 'credential-already-in-use':
          _passwordChangeError = 'Esta credencial já está em uso';
          break;
        default:
          _passwordChangeError = 'Erro ao alterar senha: ${e.message}';
      }
      return false;
    } catch (e) {
      _passwordChangeError = 'Erro inesperado ao alterar senha';
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  /// Limpa o erro de alteração de senha
  void clearPasswordError() {
    _passwordChangeError = null;
    notifyListeners();
  }
}

/// Classe para representar uma opção de tema
class ThemeOption {
  final ThemeMode mode;
  final String name;
  final String description;
  final IconData icon;

  const ThemeOption({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });
}