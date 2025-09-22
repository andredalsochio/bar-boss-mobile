import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/providers/theme_provider.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/navigation/app_router.dart';

/// Widget principal do aplicativo
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

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
    _router = AppRouter.createRouter(_authViewModel);
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            routerConfig: _router,
            // Configuração de localização para português brasileiro
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
            ],
          );
        },
      ),
    );
  }
}
