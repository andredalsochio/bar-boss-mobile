import 'package:provider/provider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../services/remote_config_service.dart';

/// Providers para o serviço de Remote Config
class RemoteConfigProviders {
  static List<dynamic> get providers => [
    // Provider para FirebaseRemoteConfig
    Provider<FirebaseRemoteConfig>(
      create: (context) => FirebaseRemoteConfig.instance,
    ),
    
    // Provider para CacheRemoteConfigService
    ProxyProvider<FirebaseRemoteConfig, CacheRemoteConfigService>(
      create: (context) => CacheRemoteConfigService(
        Provider.of<FirebaseRemoteConfig>(context, listen: false),
      ),
      update: (context, remoteConfig, previous) => 
          previous ?? CacheRemoteConfigService(remoteConfig),
      dispose: (context, service) => service.dispose(),
    ),
  ];
}