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
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              final user = authViewModel.currentUser;
              return DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingMedium),
                    Text(
                      user?.displayName ?? 'Usuário',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppSizes.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Itens do menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Início'),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('home');
                  },
                ),
                
                // Item Perfil do Bar com badge
                Consumer<HomeViewModel>(
                  builder: (context, homeViewModel, _) {
                    final showBadge = !homeViewModel.isProfileComplete;
                    
                    return ListTile(
                      leading: const Icon(Icons.store),
                      title: Row(
                        children: [
                          const Text('Perfil do bar'),
                          if (showBadge) ...[
                            const SizedBox(width: AppSizes.spacingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '!',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('barProfile');
                      },
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Eventos'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed('eventsList');
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Relatórios'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar navegação para relatórios
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configurações'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar navegação para configurações
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Ajuda'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar navegação para ajuda
                  },
                ),
              ],
            ),
          ),
          
          // Botão de logout
          const Divider(),
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              return ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Sair',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  authViewModel.logout();
                },
              );
            },
          ),
          const SizedBox(height: AppSizes.spacingMedium),
        ],
      ),
    );
  }
}