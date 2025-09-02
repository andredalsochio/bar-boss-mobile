import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_bar_widget.dart';
import '../../../core/providers/theme_provider.dart';
import '../viewmodels/settings_viewmodel.dart';

/// Tela de configurações do aplicativo
/// Permite alterar tema e outras preferências
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Inicializa o ViewModel se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SettingsViewModel>();
      if (!viewModel.isLoading) {
        viewModel.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Configurações',
        showBackButton: true,
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Aparência'),
                const SizedBox(height: AppSizes.spacing8),
                _buildThemeSection(context, viewModel),
                const SizedBox(height: AppSizes.spacing32),
                _buildSectionHeader('Conta'),
                const SizedBox(height: AppSizes.spacing8),
                _buildAccountSection(context),
                const SizedBox(height: AppSizes.spacing32),
                _buildSectionHeader('Sobre'),
                const SizedBox(height: AppSizes.spacing8),
                _buildAboutSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Constrói o cabeçalho de uma seção
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Constrói a seção de tema
  Widget _buildThemeSection(BuildContext context, SettingsViewModel viewModel) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Tema'),
                subtitle: Text('Atual: ${themeProvider.isDarkMode ? "Escuro" : "Claro"}'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Constrói a seção de conta
  Widget _buildAccountSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Alterar Senha'),
            subtitle: const Text('Gerenciar sua senha de acesso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sair',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: const Text('Fazer logout da conta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção sobre
  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Sobre o App'),
            subtitle: const Text('Versão 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Ajuda e Suporte'),
            subtitle: const Text('Central de ajuda'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpDialog(context),
          ),
        ],
      ),
    );
  }

  /// Exibe o diálogo de seleção de tema


  /// Exibe o diálogo de alteração de senha
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }

  /// Exibe o diálogo de logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout será implementado em breve'),
                ),
              );
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Exibe o diálogo sobre o app
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Bar Boss',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.local_bar,
        size: 48,
      ),
      children: [
        const Text(
          'Aplicativo para gerenciamento de bares e eventos. '
          'Desenvolvido com Flutter e Firebase.',
        ),
      ],
    );
  }

  /// Exibe o diálogo de ajuda
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda e Suporte'),
        content: const Text(
          'Para dúvidas e suporte, entre em contato através do email: '
          'suporte@barboss.com.br\n\n'
          'Ou acesse nossa central de ajuda online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        final hasPasswordProvider = viewModel.hasPasswordProvider;
        final userLoginType = viewModel.userLoginType;
        
        return AlertDialog(
          title: Text(hasPasswordProvider ? 'Alterar Senha' : 'Criar Senha'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (viewModel.passwordChangeError != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.passwordChangeError!,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Informação para usuários de login social
                 if (!hasPasswordProvider) ...
                   [
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.blue.shade50,
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.blue.shade200),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               'Você fez login via $userLoginType. Criar uma senha permitirá que você faça login também com email/senha.',
                               style: TextStyle(
                                 fontSize: 12,
                                 color: Colors.blue.shade700,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 16),
                   ],
                 
                 // Campo senha atual (apenas para usuários que já têm senha)
                 if (hasPasswordProvider) ...
                   [
                     TextFormField(
                       controller: _currentPasswordController,
                       obscureText: _obscureCurrentPassword,
                       decoration: InputDecoration(
                         labelText: 'Senha atual',
                         suffixIcon: IconButton(
                           icon: Icon(
                             _obscureCurrentPassword
                                 ? Icons.visibility
                                 : Icons.visibility_off,
                           ),
                           onPressed: () {
                             setState(() {
                               _obscureCurrentPassword = !_obscureCurrentPassword;
                             });
                           },
                         ),
                       ),
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Digite sua senha atual';
                         }
                         return null;
                       },
                     ),
                     const SizedBox(height: 16),
                   ],
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: hasPasswordProvider ? 'Nova Senha' : 'Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return hasPasswordProvider ? 'Digite a nova senha' : 'Digite a senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: hasPasswordProvider ? 'Confirmar Nova Senha' : 'Confirmar Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return hasPasswordProvider ? 'Confirme a nova senha' : 'Confirme a senha';
                    }
                    if (value != _newPasswordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: viewModel.isChangingPassword
                  ? null
                  : () {
                      viewModel.clearPasswordError();
                      Navigator.of(context).pop();
                    },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: viewModel.isChangingPassword
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        final success = await viewModel.changePassword(
                          currentPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                hasPasswordProvider 
                                    ? 'Senha alterada com sucesso!' 
                                    : 'Senha criada com sucesso! Agora você pode fazer login com email/senha.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              child: viewModel.isChangingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(hasPasswordProvider ? 'Alterar' : 'Criar'),
            ),
          ],
        );
      },
    );
  }
}