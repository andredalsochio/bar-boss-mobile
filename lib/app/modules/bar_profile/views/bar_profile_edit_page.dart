import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:search_cep/search_cep.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:bar_boss_mobile/app/core/utils/formatters.dart';
import 'package:bar_boss_mobile/app/modules/bar_profile/viewmodels/bar_profile_viewmodel.dart';

/// Página de edição do perfil do bar
class BarProfileEditPage extends StatefulWidget {
  const BarProfileEditPage({super.key});

  @override
  State<BarProfileEditPage> createState() => _BarProfileEditPageState();
}

class _BarProfileEditPageState extends State<BarProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para os campos
  final _nameController = TextEditingController();
  final _responsibleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  late BarProfileViewModel _viewModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<BarProfileViewModel>();
    _loadBarData();
    
    // Listener para busca automática de CEP
    _cepController.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cepController.removeListener(_onCepChanged);
    _nameController.dispose();
    _responsibleNameController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _loadBarData() {
    final bar = _viewModel.bar;
    if (bar != null) {
      _nameController.text = bar.name;
      _responsibleNameController.text = bar.responsibleName;
      _phoneController.text = bar.contactPhone;
      _cepController.text = bar.address.cep;
      _streetController.text = bar.address.street;
      _numberController.text = bar.address.number;
      _complementController.text = bar.address.complement ?? '';
      _cityController.text = bar.address.city;
      _stateController.text = bar.address.state;
    }
  }

  void _onCepChanged() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cep.length == 8) {
      try {
        final viaCepSearchCep = ViaCepSearchCep();
        final result = await viaCepSearchCep.searchInfoByCep(cep: cep);
        
        result.fold(
          (error) {
            // Erro na busca do CEP
            debugPrint('Erro ao buscar CEP: $error');
          },
          (info) {
            // Sucesso na busca
            setState(() {
              _streetController.text = info.logradouro ?? '';
              _cityController.text = info.localidade ?? '';
              _stateController.text = info.uf ?? '';
            });
          },
        );
      } catch (e) {
        debugPrint('Erro ao buscar CEP: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.primary(context),
        foregroundColor: Colors.white,
      ),
      body: Consumer<BarProfileViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dados básicos
                  _buildSectionTitle('Dados Básicos'),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  FormInputFieldWidget(
                    label: 'Nome do Bar',
                    hint: 'Digite o nome do seu bar',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.store),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  FormInputFieldWidget(
                    label: 'Nome do Responsável',
                    hint: 'Digite o nome do responsável',
                    controller: _responsibleNameController,
                    prefixIcon: const Icon(Icons.person),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  FormInputFieldWidget(
                    label: 'Telefone',
                    hint: '(11) 99999-9999',
                    controller: _phoneController,
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [Formatters.phoneFormatter],
                    validator: Validators.phone,
                  ),
                  
                  const SizedBox(height: AppSizes.spacingLarge),
                  
                  // Endereço
                  _buildSectionTitle('Endereço'),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  FormInputFieldWidget(
                    label: 'CEP',
                    hint: '00000-000',
                    controller: _cepController,
                    prefixIcon: const Icon(Icons.location_on),
                    keyboardType: TextInputType.number,
                    inputFormatters: [Formatters.cepFormatter],
                    validator: Validators.cep,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FormInputFieldWidget(
                          label: 'Rua',
                          hint: 'Nome da rua',
                          controller: _streetController,
                          validator: Validators.required,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(
                        flex: 1,
                        child: FormInputFieldWidget(
                          label: 'Número',
                          hint: '123',
                          controller: _numberController,
                          keyboardType: TextInputType.number,
                          validator: Validators.required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  FormInputFieldWidget(
                    label: 'Complemento',
                    hint: 'Apto, sala, etc. (opcional)',
                    controller: _complementController,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FormInputFieldWidget(
                          label: 'Cidade',
                          hint: 'Nome da cidade',
                          controller: _cityController,
                          validator: Validators.required,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMedium),
                      Expanded(
                        flex: 1,
                        child: FormInputFieldWidget(
                          label: 'Estado',
                          hint: 'UF',
                          controller: _stateController,
                          validator: Validators.required,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.spacingLarge),
                  
                  // Botões
                  ButtonWidget(
                    text: 'Salvar Alterações',
                    onPressed: _isLoading ? null : _saveChanges,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary(context),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentBar = _viewModel.bar;
      if (currentBar == null) {
        throw Exception('Bar não encontrado');
      }

      // Cria o bar atualizado
      final updatedBar = currentBar.copyWith(
        name: _nameController.text.trim(),
        responsibleName: _responsibleNameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        address: currentBar.address.copyWith(
          cep: _cepController.text.trim(),
          street: _streetController.text.trim(),
          number: _numberController.text.trim(),
          complement: _complementController.text.trim().isEmpty 
              ? null 
              : _complementController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
        ),
      );

      // Atualiza o bar
      await _viewModel.updateBarProfile(updatedBar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}