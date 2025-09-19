import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/modules/bar_profile/viewmodels/bar_profile_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/services/image_picker_service.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// Tela de perfil do bar
class BarProfilePage extends StatefulWidget {
  const BarProfilePage({super.key});

  @override
  State<BarProfilePage> createState() => _BarProfilePageState();
}

class _BarProfilePageState extends State<BarProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarProfileViewModel>().loadBarProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Perfil do Bar',
        showBackButton: true,
      ),
      body: Consumer<BarProfileViewModel>(builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                Text(
                  viewModel.errorMessage!,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingLarge),
                ElevatedButton(
                  onPressed: () => viewModel.loadBarProfile(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (!viewModel.hasBar) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                const Text(
                  'Nenhum bar cadastrado',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(
                  'Complete seu cadastro para visualizar\nos dados do seu bar',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return _buildBarProfile(viewModel.bar!);
      }),
    );
  }

  Widget _buildBarProfile(BarModel bar) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com avatar e nome do bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.spacing24),
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
              border: Border.all(
                color: AppColors.primary(context).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Avatar circular com botão de edição
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary(context),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Consumer<BarProfileViewModel>(
                          builder: (context, viewModel, _) {
                            if (bar.logoUrl != null && bar.logoUrl!.isNotEmpty) {
                              return Image.network(
                                bar.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(bar.name);
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              );
                            }
                            return _buildDefaultAvatar(bar.name);
                          },
                        ),
                      ),
                    ),
                    // Botão de editar foto
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showPhotoOptions(context.read<BarProfileViewModel>()),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingMedium),
                Text(
                  bar.name,
                  style: TextStyle(
                    fontSize: AppSizes.fontSize24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                    vertical: AppSizes.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Ativo',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Indicador de upload
                Consumer<BarProfileViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.isUploadingPhoto) {
                      return Column(
                        children: [
                          const SizedBox(height: AppSizes.spacingSmall),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Atualizando foto...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacingXLarge),

          // Seção de Informações Básicas
          _buildSection(
            title: 'Informações Básicas',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('CNPJ', _formatCnpj(bar.cnpj)),
              _buildInfoRow('Responsável', bar.responsibleName),
              _buildInfoRow('E-mail', bar.contactEmail),
              _buildInfoRow('Telefone', _formatPhone(bar.contactPhone)),
            ],
          ),

          const SizedBox(height: AppSizes.spacingLarge),

          // Seção de Endereço
          _buildSection(
            title: 'Endereço',
            icon: Icons.location_on_outlined,
            children: [
              _buildInfoRow('CEP', _formatCep(bar.address.cep)),
              _buildInfoRow('Rua', bar.address.street),
              _buildInfoRow('Número', bar.address.number),
              if (bar.address.complement != null && bar.address.complement!.isNotEmpty)
                _buildInfoRow('Complemento', bar.address.complement!),
              _buildInfoRow('Cidade', bar.address.city),
              _buildInfoRow('Estado', bar.address.state),
            ],
          ),

          const SizedBox(height: AppSizes.spacingXLarge),

          // Botão de editar (placeholder para futuras implementações)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/bar-profile/edit');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacing16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary(context),
                size: 20,
              ),
              const SizedBox(width: AppSizes.spacingSmall),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCnpj(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  String _formatPhone(String phone) {
    if (phone.length != 11) return phone;
    return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7, 11)}';
  }

  String _formatCep(String cep) {
    if (cep.length != 8) return cep;
    return '${cep.substring(0, 5)}-${cep.substring(5, 8)}';
  }

  Widget _buildDefaultAvatar(String name) {
    return Consumer<BarProfileViewModel>(
      builder: (context, viewModel, _) {
        // Tenta usar a foto do usuário logado se disponível
        final authViewModel = context.read<AuthViewModel>();
        final userPhotoUrl = authViewModel.currentUser?.photoUrl;
        
        if (userPhotoUrl != null && userPhotoUrl.isNotEmpty) {
          return Image.network(
            userPhotoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialAvatar(name);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.primary(context).withValues(alpha: 0.1),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          );
        }
        
        return _buildInitialAvatar(name);
      },
    );
  }
  
  Widget _buildInitialAvatar(String name) {
    return Container(
      color: AppColors.primary(context).withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary(context),
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions(BarProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alterar foto do perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(viewModel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(viewModel);
              },
            ),
            if (viewModel.bar?.logoUrl != null && viewModel.bar!.logoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(viewModel);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera(BarProfileViewModel viewModel) async {
     try {
       final imageFile = await ImagePickerService.pickImageFromCamera();
       if (imageFile != null) {
         await viewModel.uploadProfilePhoto(imageFile);
         _showUploadResult(viewModel);
       } else {
         // Verifica se as permissões foram negadas
         final hasPermissions = await ImagePickerService.checkPermissions();
         if (!hasPermissions && mounted) {
           await ImagePickerService.showPermissionDialog(context);
         }
       }
     } catch (e) {
       ToastService.instance.showError(message: 'Erro ao capturar foto: $e');
     }
   }
 
   Future<void> _pickImageFromGallery(BarProfileViewModel viewModel) async {
     try {
       final imageFile = await ImagePickerService.pickImageFromGallery();
       if (imageFile != null) {
         await viewModel.uploadProfilePhoto(imageFile);
         _showUploadResult(viewModel);
       } else {
         // Verifica se as permissões foram negadas
         final hasPermissions = await ImagePickerService.checkPermissions();
         if (!hasPermissions && mounted) {
           await ImagePickerService.showPermissionDialog(context);
         }
       }
     } catch (e) {
       ToastService.instance.showError(message: 'Erro ao selecionar foto: $e');
     }
   }
 
   Future<void> _removePhoto(BarProfileViewModel viewModel) async {
     try {
       final updatedBar = viewModel.bar!.copyWith(logoUrl: null);
       await viewModel.updateBarProfile(updatedBar);
       ToastService.instance.showSuccess(message: 'Foto removida com sucesso!');
     } catch (e) {
       ToastService.instance.showError(message: 'Erro ao remover foto: $e');
     }
   }
 
   void _showUploadResult(BarProfileViewModel viewModel) {
     if (viewModel.uploadMessage != null) {
       if (viewModel.uploadMessage!.contains('sucesso')) {
         ToastService.instance.showSuccess(message: viewModel.uploadMessage!);
       } else {
         ToastService.instance.showError(message: viewModel.uploadMessage!);
       }
     }
   }
}