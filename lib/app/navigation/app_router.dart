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
  /// Lógica principal de redirecionamento baseada no estado de autenticação
  static String? _handleRedirect(
    BuildContext context,
    GoRouterState state,
    AuthViewModel authViewModel,
  ) {
    final isLoggedIn = authViewModel.isAuthenticated;
    final currentLocation = state.matchedLocation;
    
    // Log de debug para diagnóstico
    debugPrint('🔄 [AppRouter] Redirect check - Location: $currentLocation, LoggedIn: $isLoggedIn');
    
    // Definir rotas permitidas por estado
    const publicRoutes = [
      AppRoutes.login,
      AppRoutes.registerStep1,
      AppRoutes.registerStep2,
      AppRoutes.registerStep3,
      AppRoutes.forgotPassword,
    ];

    // ← NOVO: Verificação idempotente - se já está na rota certa, não redirecionar
    if (!isLoggedIn && publicRoutes.contains(currentLocation)) {
      debugPrint('✅ [AppRouter] Usuário não logado em rota pública - sem redirect');
      return null;
    }

    // Se o usuário não está logado, redirecionar para login
    if (!isLoggedIn) {
      debugPrint('🔄 [AppRouter] Usuário não logado - redirecionando para login');
      return AppRoutes.login;
    }

    // === USUÁRIO LOGADO ===
    final emailVerified = authViewModel.isCurrentUserEmailVerified;
    final isFromSocialFlow = authViewModel.isFromSocialFlow;
    final canAccessApp = emailVerified || isFromSocialFlow;
    
    debugPrint('📧 [AppRouter] Email verified: $emailVerified, Social: $isFromSocialFlow, CanAccess: $canAccessApp');

    // ← MELHORADO: Lógica mais clara para verificação de email
    if (!canAccessApp) {
      // Se não pode acessar o app e já está na tela de verificação, não redirecionar
      if (currentLocation == AppRoutes.emailVerification) {
        debugPrint('✅ [AppRouter] Usuário na tela de verificação - sem redirect');
        return null;
      }
      
      // Se não pode acessar e não está na tela de verificação, redirecionar
      debugPrint('🔄 [AppRouter] Email não verificado - redirecionando para verificação');
      return AppRoutes.emailVerification;
    }

    // ← NAVEGAÇÃO AUTOMÁTICA: Se pode acessar e está na tela de verificação, ir para home
    if (canAccessApp && currentLocation == AppRoutes.emailVerification) {
      debugPrint('🎉 [AppRouter] Email verificado - navegação automática para home');
      return AppRoutes.home;
    }

    // ← NOVO: Verificar se usuário de login social pode acessar rotas de registro
    const registerRoutes = [
      AppRoutes.registerStep1,
      AppRoutes.registerStep2,
      AppRoutes.registerStep3,
    ];
    
    // Se está em rota de registro e é usuário social que não completou cadastro, permitir acesso
    if (registerRoutes.contains(currentLocation) && 
        isFromSocialFlow && 
        !authViewModel.hasCompletedFullRegistration) {
      debugPrint('✅ [AppRouter] Usuário social em rota de registro - permitindo acesso para completar cadastro');
      return null;
    }
    
    // ← NOVO: Se está em rota pública mas pode acessar o app, ir para home
    if (canAccessApp && publicRoutes.contains(currentLocation)) {
      debugPrint('🔄 [AppRouter] Usuário autenticado em rota pública - redirecionando para home');
      return AppRoutes.home;
    }

    // ← MELHORADO: Guard de completude mais simples (não bloqueia, apenas informa)
    // A verificação de completude será feita na HomePage via banner
    
    debugPrint('✅ [AppRouter] Nenhum redirect necessário');
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
  /// Usa cache para evitar chamadas assíncronas no redirect
  static String? _handleBarRegistrationGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Primeiro, verificar se o usuário está autenticado
      if (!authViewModel.isAuthenticated) {
        debugPrint('🔒 [AppRouter] BLOCKED - Usuário não autenticado');
        return AppRoutes.login;
      }
      
      final hasBarCached = authViewModel.hasBarRegisteredCached;
      final completedFullRegistration = authViewModel.hasCompletedFullRegistration;
      
      // Telemetria clara para debug
      debugPrint('🔍 [AppRouter] GUARD Estado:');
      debugPrint('  - isAuthenticated: ${authViewModel.isAuthenticated}');
      debugPrint('  - hasBarCached: $hasBarCached (${hasBarCached == null ? 'LOADING' : hasBarCached ? 'FRESH-TRUE' : 'FRESH-FALSE'})');
      debugPrint('  - completedFullRegistration: $completedFullRegistration (${authViewModel.isFromSocialFlow ? 'SOCIAL' : 'EMAIL'})');
      debugPrint('  - location: ${state.uri.toString()}');
      
      // ✅ CORREÇÃO 1: Tratar hasBarCached=null como estado de carregamento
      // Não decidir rota enquanto hasBarCached for null
      if (hasBarCached == null) {
        debugPrint('⏳ [AppRouter] LOADING - Cache não disponível, disparando ensureFresh()');
        
        // Disparar hasBarRegistered() para repopular o cache antes da decisão
        authViewModel.hasBarRegistered().then((hasBar) {
          debugPrint('🔄 [AppRouter] Cache repovoado: hasBar=$hasBar');
          
          // Após repovoamento, verificar se precisa redirecionar
          if (!hasBar && context.mounted && authViewModel.isAuthenticated) {
            debugPrint('🏪 [AppRouter] REDIRECT - Usuário sem bar após cache fresh');
            context.go(AppRoutes.registerStep1);
          }
        }).catchError((e) {
          debugPrint('❌ [AppRouter] Erro ao repopular cache: $e');
        });
        
        // Retornar null para não bloquear navegação durante loading
        debugPrint('✅ [AppRouter] ALLOWED - Permitindo navegação durante loading');
        return null;
      }
      
      // ✅ CORREÇÃO 2: Fonte única de verdade - ler apenas do AuthViewModel
      // Se tem cache e não tem bar, redirecionar
      if (!hasBarCached) {
        debugPrint('🔒 [AppRouter] BLOCKED - Cache indica usuário sem bar (FRESH-FALSE)');
        return AppRoutes.registerStep1;
      }
      
      debugPrint('✅ [AppRouter] ALLOWED - Usuário tem bar cadastrado (FRESH-TRUE)');
      return null; // Permite navegação
    } catch (e) {
      debugPrint('❌ [AppRouter] ERRO no guard: $e');
      return AppRoutes.login; // Redireciona para login em caso de erro
    }
  }
}