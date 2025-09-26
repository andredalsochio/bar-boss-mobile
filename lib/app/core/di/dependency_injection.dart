import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Domain interfaces
import 'package:bar_boss_mobile/app/domain/repositories/repositories.dart';

// Firebase implementations
import 'package:bar_boss_mobile/app/data/firebase/firebase_repositories.dart';

// Legacy services and repositories (for backward compatibility)
import 'package:bar_boss_mobile/app/modules/auth/services/auth_service.dart';
import 'package:bar_boss_mobile/app/modules/auth/repositories/user_repository.dart' as auth_user_repo;
import 'package:bar_boss_mobile/app/modules/events/repositories/event_repository.dart' as legacy_event_repo;

// ViewModels
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/bar_profile/viewmodels/bar_profile_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/settings/viewmodels/settings_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

// Providers
import 'package:bar_boss_mobile/app/core/providers/theme_provider.dart';

/// Configuração centralizada de injeção de dependências
class DependencyInjection {
  /// Retorna a lista de providers para o MultiProvider
  static List<SingleChildWidget> get providers => [
    // Domain interfaces com implementações Firebase
    Provider<AuthRepository>(
      create: (_) => FirebaseAuthRepository(),
    ),
    Provider<UserRepository>(
      create: (_) => FirebaseUserRepository(),
    ),
    Provider<BarRepositoryDomain>(
      create: (_) => FirebaseBarRepository(),
    ),
    Provider<EventRepositoryDomain>(
      create: (_) => FirebaseEventRepository(),
    ),
    
    // Legacy services e repositories (mantidos para compatibilidade temporária)
    Provider<AuthService>(
      create: (_) => AuthService(),
    ),
    Provider<auth_user_repo.UserRepository>(
      create: (_) => auth_user_repo.UserRepository(),
    ),

    Provider<legacy_event_repo.EventRepository>(
      create: (_) => legacy_event_repo.EventRepository(),
    ),
    
    // ViewModels usando interfaces de domínio
    ChangeNotifierProvider<AuthViewModel>(
      create: (context) => AuthViewModel(
        authRepository: context.read<AuthRepository>(),
        barRepository: context.read<BarRepositoryDomain>(),
        userRepository: context.read<UserRepository>(),
      ),
    ),
    ChangeNotifierProvider<BarRegistrationViewModel>(
      create: (context) => BarRegistrationViewModel(
        barRepository: context.read<BarRepositoryDomain>(),
        authRepository: context.read<AuthRepository>(),
        userRepository: context.read<UserRepository>(),
        authViewModel: context.read<AuthViewModel>(),
      ),
    ),
    ChangeNotifierProvider<EventsViewModel>(
      create: (context) => EventsViewModel(
        eventRepository: context.read<EventRepositoryDomain>(),
        barRepository: context.read<BarRepositoryDomain>(),
        authRepository: context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        authRepository: context.read<AuthRepository>(),
        barRepository: context.read<BarRepositoryDomain>(),
        userRepository: context.read<UserRepository>(),
        eventRepository: context.read<EventRepositoryDomain>(),
        authViewModel: context.read<AuthViewModel>(),
      ),
    ),
    ChangeNotifierProvider<BarProfileViewModel>(
      create: (context) => BarProfileViewModel(
        barRepository: context.read<BarRepositoryDomain>(),
        authViewModel: context.read<AuthViewModel>(),
      ),
    ),
    ChangeNotifierProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel(),
    ),
    
    // Theme Provider
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
  ];
}