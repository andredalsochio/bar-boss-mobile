import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar o tema da aplicação
/// Suporta apenas tema claro e escuro (sem opção sistema)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  /// Carrega o tema salvo nas preferências
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // Em caso de erro, mantém o tema claro como padrão
      _isDarkMode = false;
    }
  }
  
  /// Alterna entre tema claro e escuro
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
  }
  
  /// Define o tema como claro
  Future<void> setLightTheme() async {
    if (_isDarkMode) {
      _isDarkMode = false;
      await _saveTheme();
      notifyListeners();
    }
  }
  
  /// Define o tema como escuro
  Future<void> setDarkTheme() async {
    if (!_isDarkMode) {
      _isDarkMode = true;
      await _saveTheme();
      notifyListeners();
    }
  }
  
  /// Salva a preferência do tema
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Falha silenciosa - o tema será resetado na próxima inicialização
    }
  }
  
  /// Retorna o ThemeData apropriado para o tema atual
  ThemeData get currentTheme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }
  
  /// Tema claro da aplicação
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
  
  /// Tema escuro da aplicação
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}