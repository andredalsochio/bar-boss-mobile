import 'package:flutter/material.dart';

/// Classe que contém os tamanhos utilizados no aplicativo
class AppSizes {
  // Espaçamentos
  static const double spacing = 16.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacingXLarge = 48.0;
  
  // Raios de borda
  static const double borderRadius4 = 4.0;
  static const double borderRadius8 = 8.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius22 = 22.0;
  static const double borderRadiusLarge = 16.0;
  
  // Tamanhos de fonte
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  
  // Tamanhos de ícone
  static const double iconSize12 = 12.0;
  static const double iconSize16 = 16.0;
  static const double iconSize24 = 24.0;
  static const double iconSize32 = 32.0;
  static const double iconSize48 = 48.0;
  static const double iconSizeLarge = 64.0;
  static const double iconSizeMedium = 24.0;
  
  // Altura de campos de formulário
  static const double inputHeight = 44.0;
  
  // Espessura de borda
  static const double borderWidth = 1.0;
  
  // Elevação
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
  
  // Paddings
  static const EdgeInsets paddingAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: spacing16);
  
  // Tamanhos para a interface
  static const double screenPadding = spacing16;
  static const double spacingSmall = spacing8;
  static const double spacingMedium = spacing16;
  static const double spacingLarge = spacing24;
  
  // Tamanhos de fonte semânticos
  static const double fontSizeSmall = fontSize12;
  static const double fontSizeMedium = fontSize16;
  static const double fontSizeLarge = fontSize20;
  static const EdgeInsets paddingPage = EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing16);
  static const EdgeInsets paddingForm = EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8);
  
  // Aliases para compatibilidade
  static const double borderRadius = borderRadius8;
  static const double inputHorizontalPadding = spacing16;
  static const double inputVerticalPadding = spacing12;
  static const double buttonHorizontalPadding = spacing24;
  static const double buttonVerticalPadding = spacing16;
  static const double iconSizeSmall = 16.0;
}