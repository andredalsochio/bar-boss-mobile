import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


import 'firebase_options.dart';

import 'package:bar_boss_mobile/app/app_widget.dart';
import 'package:bar_boss_mobile/app/modules/auth/services/auth_service.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/repositories/event_repository.dart';
import 'package:bar_boss_mobile/app/modules/events/repositories/vip_request_repository.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/repositories/bar_repository.dart';

// Configurações do Clerk - usando variável de ambiente
const String clerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
);

void main() async {
  // Garante que os widgets sejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Valida se a chave do Clerk foi configurada
  if (clerkPublishableKey.isEmpty) {
    throw Exception(
      'CLERK_PUBLISHABLE_KEY não foi configurada. '
      'Verifique o arquivo launch.json ou as variáveis de ambiente.',
    );
  }
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configura o Crashlytics
  await _setupCrashlytics();
  
  // Configura o Remote Config
  await _setupRemoteConfig();
  
  // Clerk será inicializado no AppWidget
  
  // Executa o aplicativo
  runApp(
    MultiProvider(
      providers: [
        // Serviços
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // Repositórios
        Provider<BarRepository>(
          create: (_) => BarRepository(),
        ),
        Provider<EventRepository>(
          create: (_) => EventRepository(),
        ),
        Provider<VipRequestRepository>(
          create: (_) => VipRequestRepository(),
        ),
        
        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            barRepository: context.read<BarRepository>(),
          ),
        ),
        ChangeNotifierProvider<BarRegistrationViewModel>(
          create: (context) => BarRegistrationViewModel(
            barRepository: context.read<BarRepository>(),
          ),
        ),
        ChangeNotifierProvider<EventsViewModel>(
          create: (context) => EventsViewModel(
            eventRepository: context.read<EventRepository>(),
            barRepository: context.read<BarRepository>(),
          ),
        ),
      ],
      child: const AppWidget(),
    ),
  );
}

Future<void> _setupCrashlytics() async {
  // Passa todos os erros não tratados para o Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Ativa a coleta de relatórios de falhas
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}

Future<void> _setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  
  // Configura os padrões
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  
  // Define valores padrão
  await remoteConfig.setDefaults({
    'enable_vip_feature': true,
    'max_promotions_per_event': 3,
  });
  
  // Busca e ativa os valores
  await remoteConfig.fetchAndActivate();
}