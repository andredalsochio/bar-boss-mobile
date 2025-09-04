import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/utils/validators.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/form_input_field_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// Tela de login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    // Navega para a tela inicial se o login foi bem-sucedido
    if (authViewModel.errorMessage == null) {
      context.goNamed('home');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.loginWithGoogle();

    if (!mounted) return;

    // Navega para a tela inicial se o login foi bem-sucedido
    if (authViewModel.errorMessage == null) {
      context.goNamed('home');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.loginWithApple();

    if (!mounted) return;

    // Navega para a tela inicial se o login foi bem-sucedido
    if (authViewModel.errorMessage == null) {
      context.goNamed('home');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.loginWithFacebook();

    if (!mounted) return;

    // Navega para a tela inicial se o login foi bem-sucedido
    if (authViewModel.errorMessage == null) {
      context.goNamed('home');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToRegisterBar() {
    context.pushNamed('registerStep1');
  }

  void _goToForgotPassword() {
    context.pushNamed('forgotPassword');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spacingXLarge),
                  // Logo ou título do app
                  Center(
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  Center(
                    child: Text(
                      AppStrings.loginSubtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXLarge),
                  // Formulário de login
                  FormInputFieldWidget(
                    label: AppStrings.emailLabel,
                    hint: AppStrings.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => Validators.email(value),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FormInputFieldWidget(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordHint,
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) => Validators.password(value),
                  ),
                  const SizedBox(height: AppSizes.spacingSmall),
                  // Link "Esqueci minha senha"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _goToForgotPassword,
                      child: Text(
                        AppStrings.forgotPasswordButton,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary(context),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  // Botão de login
                  ButtonWidget(
                    text: AppStrings.loginButton,
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  // Divisor
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                            color: AppColors.border(context),
                            thickness: 1,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingMedium,
                        ),
                        child: Text(
                          AppStrings.orLoginWith,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                            color: AppColors.border(context),
                            thickness: 1,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  // Botões de login social
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialLoginButton(
                        icon: FontAwesomeIcons.google,
                        color: AppColors.googleRed,
                        onPressed: _loginWithGoogle,
                      ),
                      _buildSocialLoginButton(
                        icon: FontAwesomeIcons.apple,
                        color: AppColors.black,
                        onPressed: _loginWithApple,
                      ),
                      _buildSocialLoginButton(
                        icon: FontAwesomeIcons.facebook,
                        color: AppColors.facebookBlue,
                        onPressed: _loginWithFacebook,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingXLarge),
                  // Link para cadastro de bar
                  Center(
                    child: TextButton(
                      onPressed: _goToRegisterBar,
                      child: Text(
                        AppStrings.dontHaveBarQuestion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary(context),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(
            color: AppColors.border(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context).withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: AppSizes.iconSizeMedium,
          ),
        ),
      ),
    );
  }
}