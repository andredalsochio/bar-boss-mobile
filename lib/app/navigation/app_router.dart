import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bar_boss_mobile/app/core/constants/app_routes.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/login_page.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/email_verification_page.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/email_verification_success_page.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/forgot_password_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step1_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step2_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step3_page.dart';
import 'package:bar_boss_mobile/app/modules/home/views/home_page.dart';
import 'package:bar_boss_mobile/app/modules/bar_profile/views/bar_profile_page.dart';
import 'package:bar_boss_mobile/app/modules/settings/views/settings_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/events_list_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/event_form_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/event_details_page.dart';

/// Configuração centralizada de navegação com GoRouter
class AppRouter {
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: authViewModel,
      redirect: (context, state) => _handleRedirect(context, state, authViewModel),
      routes: [
        // Rotas de autenticação
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.emailVerification,
          name: 'emailVerification',
          builder: (context, state) => const EmailVerificationPage(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.emailVerificationSuccess,
          name: 'emailVerificationSuccess',
          builder: (context, state) => const EmailVerificationSuccessPage(),
        ),

        // Rotas de cadastro
        GoRoute(
          path: AppRoutes.registerStep1,
          name: 'registerStep1',
          builder: (context, state) => const Step1Page(),
        ),
        GoRoute(
          path: AppRoutes.registerStep2,
          name: 'registerStep2',
          builder: (context, state) => const Step2Page(),
        ),
        GoRoute(
          path: AppRoutes.registerStep3,
          name: 'registerStep3',
          builder: (context, state) => const Step3Page(),
        ),

        // Rotas principais (protegidas por autenticação)
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.eventsList,
          name: 'eventsList',
          redirect: _handleBarRegistrationGuard,
          builder: (context, state) => const EventsListPage(),
        ),
        GoRoute(
          path: AppRoutes.eventForm,
          name: 'eventForm',
          redirect: _handleBarRegistrationGuard,
          builder: (context, state) => const EventFormPage(),
        ),
        GoRoute(
          path: AppRoutes.eventEdit,
          name: 'eventEdit',
          redirect: _handleBarRegistrationGuard,
          builder: (context, state) {
            final eventId = state.pathParameters['id'];
            if (eventId == null) {
              // Se não há ID, redireciona para lista de eventos
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.pushReplacementNamed('eventsList');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return EventFormPage(eventId: eventId);
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetails,
          name: 'eventDetails',
          redirect: _handleBarRegistrationGuard,
          builder: (context, state) {
            final eventId = state.pathParameters['id'];
            if (eventId == null) {
              // Se não há ID, redireciona para lista de eventos
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.pushReplacementNamed('eventsList');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return EventDetailsPage(eventId: eventId);
          },
        ),

        // Rota para perfil do bar
        GoRoute(
          path: AppRoutes.barProfile,
          name: 'barProfile',
          builder: (context, state) => const BarProfilePage(),
        ),

        // Rota para configurações
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    );
  }

  /// Guard de autenticação e redirecionamento
  static String? _handleRedirect(
    BuildContext context,
    GoRouterState state,
    AuthViewModel authViewModel,
  ) {
    final isLoggedIn = authViewModel.isAuthenticated;
    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isRegistering = state.matchedLocation.startsWith('/register');
    final isEmailVerificationFlow = state.matchedLocation == AppRoutes.emailVerification ||
        state.matchedLocation == AppRoutes.forgotPassword;

    // Se o usuário não está logado e não está na tela de login, cadastro ou verificação
    if (!isLoggedIn && !isLoggingIn && !isRegistering && !isEmailVerificationFlow) {
      return AppRoutes.login;
    }

    // Se o usuário está logado
    if (isLoggedIn) {
      // Verificar se o e-mail está verificado
      final emailVerified = authViewModel.isCurrentUserEmailVerified;
      final isFromSocialProvider = authViewModel.isFromSocialProvider;
      
      // Se está na tela de login e e-mail verificado, vai para home
      if (isLoggingIn && emailVerified) {
        return AppRoutes.home;
      }
      
      // Se e-mail não verificado e não está na tela de verificação
      // IMPORTANTE: Usuários de login social não precisam verificar e-mail
      if (!emailVerified && !isFromSocialProvider && state.matchedLocation != AppRoutes.emailVerification) {
        return AppRoutes.emailVerification;
      }
      
      // Se e-mail verificado OU é de provedor social e está na tela de verificação, vai para home
      if ((emailVerified || isFromSocialProvider) && state.matchedLocation == AppRoutes.emailVerification) {
        return AppRoutes.home;
      }
      
      // Guard de completude de perfil (apenas se e-mail verificado OU é de provedor social)
      if ((emailVerified || isFromSocialProvider) && !isLoggingIn && !isRegistering && !isEmailVerificationFlow) {
        return _handleProfileCompletenessGuard(context, state);
      }
    }

    // Não redireciona
    return null;
  }

  /// Guard para verificar completude do perfil conforme BUSINESS_RULES.md
  /// Não bloqueia navegação, apenas exibe banner na Home
  static String? _handleProfileCompletenessGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    // TODO: Implementar lógica de verificação de completude
    // Por enquanto, não bloqueia navegação conforme especificado:
    // "Não bloquear criação de evento por perfil incompleto; apenas avisar"
    
    // A verificação de completude será feita na HomePage via HomeViewModel
    // que exibirá o banner "Complete seu cadastro (X/3)" quando necessário
    
    return null; // Não redireciona
  }

  /// Guard para verificar se o usuário tem bar cadastrado
  /// Bloqueia acesso a telas de eventos se não tiver bar
  static Future<String?> _handleBarRegistrationGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final hasBar = await authViewModel.hasBarRegistered();
      
      if (!hasBar) {
        // Redireciona para cadastro de bar se não tiver
        return AppRoutes.registerStep1;
      }
      
      return null; // Permite navegação
    } catch (e) {
      debugPrint('Erro no guard de bar: $e');
      return '/login'; // Redireciona para login em caso de erro
    }
  }
}