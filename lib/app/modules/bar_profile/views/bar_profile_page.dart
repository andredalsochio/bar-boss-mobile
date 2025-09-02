import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/modules/bar_profile/viewmodels/bar_profile_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

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
          // Header com ícone e nome do bar
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
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.white,
                  ),
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
                // TODO: Implementar edição do perfil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade de edição em desenvolvimento'),
                  ),
                );
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
            color: AppColors.black.withOpacity(0.05),
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
}