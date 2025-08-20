import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bar_boss_mobile/app/core/constants/app_routes.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/login_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step1_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step2_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step3_page.dart';
import 'package:bar_boss_mobile/app/modules/home/views/home_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/events_list_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/event_form_page.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

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
          builder: (context, state) => const EventsListPage(),
        ),
        GoRoute(
          path: AppRoutes.eventForm,
          name: 'eventForm',
          builder: (context, state) => const EventFormPage(),
        ),
        GoRoute(
          path: AppRoutes.eventEdit,
          name: 'eventEdit',
          builder: (context, state) {
            final eventId = state.pathParameters['id'] ?? '';
            return EventFormPage(eventId: eventId);
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetails,
          name: 'eventDetails',
          builder: (context, state) {
            final eventId = state.pathParameters['id'] ?? '';
            return EventFormPage(eventId: eventId, readOnly: true);
          },
        ),

        // Rota para perfil do bar (placeholder)
        GoRoute(
          path: '/profile',
          name: 'barProfile',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Text('Perfil do Bar - Em desenvolvimento'),
            ),
          ),
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

    // Se o usuário não está logado e não está na tela de login ou cadastro
    if (!isLoggedIn && !isLoggingIn && !isRegistering) {
      return AppRoutes.login;
    }

    // Se o usuário está logado e está na tela de login
    if (isLoggedIn && isLoggingIn) {
      return AppRoutes.home;
    }

    // Implementar guard de completude de perfil conforme PROJECT_RULES.md
    if (isLoggedIn && !isLoggingIn && !isRegistering) {
      return _handleProfileCompletenessGuard(context, state);
    }

    // Não redireciona
    return null;
  }

  /// Guard para verificar completude do perfil conforme PROJECT_RULES.md
  /// Não bloqueia navegação, apenas exibe banner na Home
  static String? _handleProfileCompletenessGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    // TODO: Implementar lógica de verificação de completude
    // Por enquanto, não bloqueia navegação conforme especificado:
    // "Não bloquear criação de evento por perfil incompleto; apenas avisar"
    
    // A verificação de completude será feita na HomePage via HomeViewModel
    // que exibirá o banner "Complete seu cadastro (X/2)" quando necessário
    
    return null; // Não redireciona
  }
}