import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget de AppBar personalizado para o aplicativo
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  
  const AppBarWidget({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.titleColor,
    this.elevation = 0,
    this.bottom,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppSizes.fontSize18,
          fontWeight: FontWeight.bold,
          color: titleColor ?? Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: elevation,
      actions: actions,
      bottom: bottom,
      leading: _buildLeading(context),
      iconTheme: IconThemeData(
        color: titleColor ?? Colors.white,
      ),
    );
  }
  
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }
    
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Se não há nada para fazer pop, navegar para home
            context.go('/');
          }
        },
      );
    }
    
    return null;
  }
  
  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}