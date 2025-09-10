import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

/// Widget do drawer principal do aplicativo
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header moderno do drawer
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, _) {
                final user = authViewModel.currentUser;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.spacingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary(context),
                        AppColors.primary(context).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar com design moderno
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.white.withOpacity(0.2),
                          child: user?.photoUrl != null
                               ? ClipOval(
                                   child: Image.network(
                                     user!.photoUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 32,
                                        color: AppColors.white,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppColors.white,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingMedium),
                      
                      // Nome do usuário
                      Text(
                        user?.displayName ?? 'Usuário',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Email do usuário
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Itens do menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacingSmall,
                ),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    title: 'Início',
                    onTap: () {
                      Navigator.pop(context);
                      context.goNamed('home');
                    },
                  ),
                  
                  // Item Perfil do Bar com badge moderno
                  Consumer<HomeViewModel>(
                    builder: (context, homeViewModel, _) {
                      final showBadge = !homeViewModel.isProfileComplete;
                      
                      return _buildDrawerItem(
                        context: context,
                        icon: Icons.store_outlined,
                        selectedIcon: Icons.store,
                        title: 'Perfil do bar',
                        showBadge: showBadge,
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed('barProfile');
                        },
                      );
                    },
                  ),
                  
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.event_outlined,
                    selectedIcon: Icons.event,
                    title: 'Eventos',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed('eventsList');
                    },
                  ),
                  
                  const SizedBox(height: AppSizes.spacingSmall),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                  const SizedBox(height: AppSizes.spacingSmall),
                  
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed('settings');
                    },
                  ),
                  
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.help_outline,
                    selectedIcon: Icons.help,
                    title: 'Ajuda',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implementar navegação para ajuda
                    },
                  ),
                ],
              ),
            ),
            
            // Botão de logout moderno
            Container(
              margin: const EdgeInsets.all(AppSizes.spacingMedium),
              child: Consumer<AuthViewModel>(
                builder: (context, authViewModel, _) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context, authViewModel);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingMedium,
                          vertical: AppSizes.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_outlined,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.spacingMedium),
                            Text(
                              'Sair',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSmall,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMedium,
              vertical: AppSizes.spacingSmall,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.onSurface.withOpacity(0.8),
                  size: 22,
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar saída'),
          content: const Text('Tem certeza que deseja sair do aplicativo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                authViewModel.logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}