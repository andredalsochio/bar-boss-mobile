import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Serviço para acesso ao Firebase Remote Config.
/// Controla parâmetros de versão mínima do aplicativo.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String minAppVersionAndroid = 'min_app_version_android';
  static const String minAppVersionIos = 'min_app_version_ios';

  /// Inicializa o Remote Config com cache padrão de 12 horas.
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ));
    await _remoteConfig.setDefaults(const {
      minAppVersionAndroid: '0',
      minAppVersionIos: '0',
    });
    await _remoteConfig.fetchAndActivate();
  }

  /// Verifica se a versão atual do app atende a versão mínima exigida.
  Future<bool> isVersionSupported() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final minVersion = int.tryParse(
      Platform.isIOS
          ? _remoteConfig.getString(minAppVersionIos)
          : _remoteConfig.getString(minAppVersionAndroid),
    ) ??
        0;
    return buildNumber >= minVersion;
  }
}