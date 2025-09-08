import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/core/constants/app_routes.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

/// Tela para verificação de e-mail
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  bool _isResending = false;
  bool _isChecking = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }
  

  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final userEmail = authViewModel.userEmail ?? 'seu e-mail';
        
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                debugPrint('🔙 [EmailVerificationPage] Botão voltar pressionado');
        debugPrint('🔙 [EmailVerificationPage] context.canPop(): ${context.canPop()}');
        
        if (context.canPop()) {
          debugPrint('🔙 [EmailVerificationPage] Usando context.pop()');
          context.pop();
        } else {
          debugPrint('🔙 [EmailVerificationPage] Usando context.go(AppRoutes.login)');
          debugPrint('🔙 [EmailVerificationPage] AppRoutes.login = ${AppRoutes.login}');
          context.go(AppRoutes.login);
        }
        
        debugPrint('✅ [EmailVerificationPage] Navegação executada com sucesso');
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de e-mail animado
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade100,
                                Colors.blue.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 60,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título animado
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Verifique seu e-mail',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Descrição melhorada
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'Enviamos um link de verificação para:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Clique no link para ativar sua conta.\nVerificamos automaticamente a cada 3 segundos.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botão "Já validei, verificar novamente"
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkEmailVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Já validei, verificar novamente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botão "Reenviar e-mail de verificação" com cooldown
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: (_isResending || _resendCooldown > 0) ? null : _resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _resendCooldown > 0 
                          ? Colors.grey.shade400
                          : Colors.blue.shade600,
                      side: BorderSide(
                        color: _resendCooldown > 0 
                            ? Colors.grey.shade300
                            : Colors.blue.shade600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isResending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            ),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Aguarde ${_resendCooldown}s para reenviar'
                                : 'Reenviar e-mail de verificação',
                            style: const TextStyle(
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
                    debugPrint('🔙 [EmailVerificationPage] Botão voltar pressionado');
                    debugPrint('🔙 [EmailVerificationPage] context.canPop(): ${context.canPop()}');
                    
                    try {
                      if (context.canPop()) {
                        debugPrint('🔙 [EmailVerificationPage] Usando context.pop()');
                        context.pop();
                      } else {
                        debugPrint('🔙 [EmailVerificationPage] Usando context.go(AppRoutes.login)');
                        context.go(AppRoutes.login);
                      }
                      debugPrint('✅ [EmailVerificationPage] Navegação executada com sucesso');
                    } catch (e) {
                      debugPrint('❌ [EmailVerificationPage] Erro na navegação: $e');
                    }
                  },
                  child: const Text(
                    'Voltar ao login',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  

  
  /// Verifica se o e-mail foi verificado
  Future<void> _checkEmailVerification() async {
    setState(() {
      _isChecking = true;
    });
    
    try {
      final authViewModel = context.read<AuthViewModel>();
      final isVerified = await authViewModel.checkEmailVerified();
      
      if (isVerified) {
        if (mounted) {
          ToastService.instance.showSuccess(message: 'E-mail verificado com sucesso!');
          context.go(AppRoutes.home);
        }
      } else {
        if (mounted) {
          ToastService.instance.showWarning(message: 'E-mail ainda não foi verificado. Verifique sua caixa de entrada.');
        }
      }
    } catch (e) {
      debugPrint('❌ [EmailVerificationPage] Erro ao verificar e-mail: $e');
      if (mounted) {
        ToastService.instance.showError(message: 'Erro ao verificar e-mail. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }
  
  /// Reenvia o e-mail de verificação
  Future<void> _resendVerificationEmail() async {
    debugPrint('📧 [EmailVerificationPage] Iniciando reenvio de e-mail...');
    
    setState(() {
      _isResending = true;
    });
    
    try {
      final authViewModel = context.read<AuthViewModel>();
      debugPrint('📧 [EmailVerificationPage] Chamando authViewModel.sendEmailVerification()...');
      final success = await authViewModel.sendEmailVerification();
      
      if (mounted) {
        if (success) {
          debugPrint('✅ [EmailVerificationPage] E-mail reenviado com sucesso!');
          ToastService.instance.showSuccess(message: 'E-mail de verificação reenviado!');
          _startResendCooldown();
        } else {
          debugPrint('⚠️ [EmailVerificationPage] Falha ao reenviar e-mail');
          ToastService.instance.showWarning(message: 'Falha ao reenviar e-mail. Tente novamente.');
        }
      }
    } catch (e) {
      debugPrint('❌ [EmailVerificationPage] Erro ao reenviar e-mail: $e');
      if (mounted) {
        ToastService.instance.showError(message: 'Erro ao reenviar e-mail. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }
  
  /// Inicia o cooldown para reenvio de e-mail
  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 segundos de cooldown
    });
    
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });
      
      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }
}