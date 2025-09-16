import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/core/constants/app_routes.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:go_router/go_router.dart';

/// Tela para recuperação de senha
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _emailSent ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }
  
  /// Constrói a view do formulário
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Ícone de cadeado
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_outlined,
              size: 60,
              color: AppColors.primary(context),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Título
          Text(
            'Esqueci minha senha',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Descrição
          Text(
            'Digite seu e-mail e enviaremos um link para redefinir sua senha.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Campo de e-mail
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
            decoration: InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary(context)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary(context), width: 2),
              ),
              labelStyle: TextStyle(color: AppColors.textSecondary(context)),
              hintStyle: TextStyle(color: AppColors.textHint(context)),
            ),
            validator: Validators.email,
          ),
          
          const SizedBox(height: 32),
          
          // Botão "Enviar link de recuperação"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.buttonText(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Enviar link de recuperação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Link para voltar ao login
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            },
            child: Text(
              'Voltar ao login',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
  
  /// Constrói a view de sucesso
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ícone de sucesso
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 60,
            color: AppColors.success,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Título
        Text(
          'Solicitação processada!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Descrição
        Text(
          'Se o e-mail ${_emailController.text} estiver cadastrado,\nvocê receberá as instruções de recuperação.\n\nVerifique sua caixa de entrada e spam.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary(context),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Botão "Reenviar e-mail"
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary(context),
              side: BorderSide(color: AppColors.primary(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
                    ),
                  )
                : const Text(
                    'Reenviar e-mail',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botão "Voltar ao login"
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              foregroundColor: AppColors.buttonText(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Voltar ao login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Envia o e-mail de recuperação de senha
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.sendPasswordResetEmail(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        ToastService.instance.showSuccess(
          message: 'Se o e-mail estiver cadastrado, você receberá as instruções de recuperação.',
          title: 'Solicitação Processada',
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