import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import 'package:bar_boss_mobile/app/core/constants/app_routes.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/auth/views/login_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step1_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step2_page.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/views/step3_page.dart';
import 'package:bar_boss_mobile/app/modules/home/views/home_page.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/views/events_list_page.dart';
import 'package:bar_boss_mobile/app/modules/events/views/event_form_page.dart';

/// Widget principal do aplicativo
class AppWidget extends StatefulWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late final GoRouter _router;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = context.read<AuthViewModel>();
    _setupRouter();
  }

  void _setupRouter() {
    _router = GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: _authViewModel,
      redirect: _handleRedirect,
      routes: [
        // Rotas de autenticação
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        
        // Rotas de cadastro
        GoRoute(
          path: AppRoutes.registerStep1,
          builder: (context, state) => const Step1Page(),
        ),
        GoRoute(
          path: AppRoutes.registerStep2,
          builder: (context, state) => const Step2Page(),
        ),
        GoRoute(
          path: AppRoutes.registerStep3,
          builder: (context, state) => const Step3Page(),
        ),
        
        // Rotas principais
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.eventsList,
          builder: (context, state) => const EventsListPage(),
        ),
        GoRoute(
          path: AppRoutes.eventForm,
          builder: (context, state) => const EventFormPage(),
        ),
        GoRoute(
          path: AppRoutes.eventEdit,
          builder: (context, state) {
            final eventId = state.pathParameters['id'] ?? '';
            return EventFormPage(eventId: eventId);
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetails,
          builder: (context, state) {
            final eventId = state.pathParameters['id'] ?? '';
            return EventFormPage(eventId: eventId, readOnly: true);
          },
        ),
      ],
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _authViewModel.isAuthenticated(context);
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

    // Não redireciona
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: 'pk_test_YWdlbmRhLWRlLWJvdGVjby0xMC5jbGVyay5hY2NvdW50cy5kZXYk',
      ),
      child: ClerkAuthBuilder(
        builder: (context, authState) {
          return MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              background: AppColors.background,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          routerConfig: _router,
        );
      },
      ),
    );
  }
}