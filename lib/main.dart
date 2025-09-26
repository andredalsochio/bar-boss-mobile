import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

import 'package:bar_boss_mobile/app/app_widget.dart';
import 'package:bar_boss_mobile/app/core/di/dependency_injection.dart';

void main() async {
  // Garante que os widgets sejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura o App Check por ambiente
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode 
        ? AndroidProvider.playIntegrity   // Produção: Play Integrity
        : AndroidProvider.debug,          // Desenvolvimento: Debug Token
    appleProvider: kReleaseMode
        ? AppleProvider.appAttest         // Produção: App Attest
        : AppleProvider.debug,            // Desenvolvimento: Debug Token
  );

  // Inicializa a localização de datas
  await initializeDateFormatting('pt_BR', null);

  // Configura o Crashlytics
  await _setupCrashlytics();

  // Configura o Remote Config
  await _setupRemoteConfig();

  // Executa o aplicativo
  runApp(
    MultiProvider(
      providers: DependencyInjection.providers,
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
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );

  // Define valores padrão
  await remoteConfig.setDefaults({

    'max_promotions_per_event': 3,
  });

  // Busca e ativa os valores
  await remoteConfig.fetchAndActivate();
}
