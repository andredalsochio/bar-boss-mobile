import 'package:flutter/material.dart';

/// Classe que contém as cores utilizadas no aplicativo
/// Agora utiliza Theme.of(context) para suportar tema claro e escuro
class AppColors {
  // Cores primárias - baseadas no tema
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color primaryDark(BuildContext context) => Theme.of(context).colorScheme.primary.withValues(alpha: .8);
  static Color primaryLight(BuildContext context) => Theme.of(context).colorScheme.primary.withOpacity(0.6);
  
  // Cores secundárias - baseadas no tema
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color secondaryDark(BuildContext context) => Theme.of(context).colorScheme.secondary.withOpacity(0.8);
  static Color secondaryLight(BuildContext context) => Theme.of(context).colorScheme.secondary.withOpacity(0.6);
  
  // Cores de fundo - baseadas no tema
  static Color background(BuildContext context) => Theme.of(context).colorScheme.background;
  static Color cardBackground(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color surfaceVariant(BuildContext context) => Theme.of(context).colorScheme.surfaceVariant;
  
  // Cores de texto - baseadas no tema
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  static Color textHint(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  static Color textLight(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  
  // Cores de estado - fixas (não dependem do tema)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Cores de borda - baseadas no tema
  static Color border(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color divider(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;
  
  // Cores de botões - baseadas no tema
  static Color buttonText(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  static Color buttonDisabled(BuildContext context) => Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
  
  // Cores básicas - fixas
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  
  // Cores de indicadores - fixas
  static const Color promotionIndicator = Color(0xFF9C27B0); // Roxo para promoções
  
  // Cores de redes sociais - fixas
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF4267B2);
  static const Color appleBlack = Color(0xFF000000);
  
  // Cores de sombra - baseadas no tema
  static Color shadow(BuildContext context) => Theme.of(context).shadowColor;
  
  // Aliases para compatibilidade
  static Color inputBackground(BuildContext context) => cardBackground(context);
}