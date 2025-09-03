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
    colorScheme: const ColorScheme.light(
      // Cor primária: Vermelho D9401F para app bar e botões principais
      primary: Color(0xFFD9401F),
      onPrimary: Color(0xFFFFFFFF), // Texto branco sobre vermelho
      primaryContainer: Color(0xFFFFDAD4), // Container mais claro
      onPrimaryContainer: Color(0xFF410000), // Texto escuro no container
      
      // Cores secundárias
      secondary: Color(0xFF775651),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDAD4),
      onSecondaryContainer: Color(0xFF2C1512),
      
      // Surface: Cinza claro para o fundo principal
      surface: Color(0xFFF5F5F5), // Cinza claro para o fundo
      onSurface: Color(0xFF1C1B1F),
      
      // Surface containers: Branco para cards e banners
      surfaceContainer: Color(0xFFFFFFFF), // Branco para cards
      onSurfaceVariant: Color(0xFF534341),
      surfaceContainerHighest: Color(0xFFF3F0F0), // Substitui surfaceVariant
      
      // Cores de contorno para bordas
      outline: Color(0xFF857370),
      outlineVariant: Color(0xFFD8C2BE),
      
      // Cores de erro
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      
      // Cor de sombra
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFFD9401F), // Vermelho para app bar
      foregroundColor: Color(0xFFFFFFFF), // Texto branco na app bar
    ),
    cardTheme: CardThemeData(
      elevation: 4, // Sombra mais pronunciada
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2), // Borda sutil
          width: 1,
        ),
      ),
      color: const Color(0xFFFFFFFF), // Fundo branco para cards
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD9401F), // Vermelho para botões principais
        foregroundColor: const Color(0xFFFFFFFF), // Texto branco nos botões
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
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
    colorScheme: const ColorScheme.dark(
      // Cor primária: Vermelho mais suave para o modo escuro
      primary: Color(0xFFFF6B47), // Vermelho mais claro e vibrante
      onPrimary: Color(0xFF000000), // Texto preto sobre vermelho claro
      primaryContainer: Color(0xFF8C1D00), // Container vermelho escuro
      onPrimaryContainer: Color(0xFFFFDAD4), // Texto claro no container
      
      // Cores secundárias
      secondary: Color(0xFFE7BDB6),
      onSecondary: Color(0xFF442925),
      secondaryContainer: Color(0xFF5D3F3A),
      onSecondaryContainer: Color(0xFFFFDAD4),
      
      // Surface: Cinza escuro para o fundo principal
      surface: Color(0xFF121212), // Fundo escuro principal
      onSurface: Color(0xFFE6E1E5),
      
      // Surface containers: Cinza escuro para cards
      surfaceContainer: Color(0xFF1E1E1E), // Cinza escuro para cards
      onSurfaceVariant: Color(0xFFD8C2BE),
      surfaceContainerHighest: Color(0xFF534341), // Substitui surfaceVariant
      
      // Cores de contorno
      outline: Color(0xFFA08C89),
      outlineVariant: Color(0xFF534341),
      
      // Cores de erro
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      
      // Cor de sombra
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E), // Fundo escuro para app bar
      foregroundColor: Color(0xFFE6E1E5), // Texto claro na app bar
    ),
    cardTheme: CardThemeData(
      elevation: 8, // Sombra mais pronunciada no modo escuro
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF534341).withValues(alpha: 0.5), // Borda sutil
          width: 1,
        ),
      ),
      color: const Color(0xFF1E1E1E), // Fundo escuro para cards
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B47), // Vermelho vibrante para botões
        foregroundColor: const Color(0xFF000000), // Texto preto nos botões
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}