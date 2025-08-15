import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Domain interfaces
import 'package:bar_boss_mobile/app/domain/repositories/repositories.dart';

// Legacy interfaces that adapters implement (same names as domain interfaces)
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository.dart' as BarRepo;
import 'package:bar_boss_mobile/app/domain/repositories/event_repository.dart' as EventRepo;

// Firebase implementations
import 'package:bar_boss_mobile/app/data/firebase/firebase_repositories.dart';

// Legacy services and repositories (for backward compatibility)
import 'package:bar_boss_mobile/app/modules/auth/services/auth_service.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/repositories/bar_repository.dart' as LegacyBarRepo;
import 'package:bar_boss_mobile/app/modules/events/repositories/event_repository.dart' as LegacyEventRepo;

// Adapters to bridge domain repos to legacy-style interfaces used by ViewModels
import 'package:bar_boss_mobile/app/core/adapters/bar_repository_adapter.dart';
import 'package:bar_boss_mobile/app/core/adapters/event_repository_adapter.dart';

// ViewModels
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/viewmodels/bar_registration_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

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
    
    // Adapters que expõem as interfaces esperadas pelos ViewModels
    Provider<BarRepo.BarRepository>(
      create: (context) => BarRepositoryAdapter(context.read<BarRepositoryDomain>()),
    ),
    Provider<EventRepo.EventRepository>(
      create: (context) => EventRepositoryAdapter(context.read<EventRepositoryDomain>()),
    ),
    
    // Legacy services e repositories (mantidos para compatibilidade em outras partes do app)
    Provider<AuthService>(
      create: (_) => AuthService(),
    ),
    Provider<LegacyBarRepo.BarRepository>(
      create: (_) => LegacyBarRepo.BarRepository(),
    ),
    Provider<LegacyEventRepo.EventRepository>(
      create: (_) => LegacyEventRepo.EventRepository(),
    ),
    
    // ViewModels
    ChangeNotifierProvider<AuthViewModel>(
      create: (context) => AuthViewModel(
        authRepository: context.read<AuthRepository>(),
        barRepository: context.read<BarRepo.BarRepository>(),
      ),
    ),
    ChangeNotifierProvider<BarRegistrationViewModel>(
      create: (context) => BarRegistrationViewModel(
        barRepository: context.read<BarRepo.BarRepository>(),
        authRepository: context.read<AuthRepository>(),
        legacyBarRepository: context.read<LegacyBarRepo.BarRepository>(),
      ),
    ),
    ChangeNotifierProvider<EventsViewModel>(
      create: (context) => EventsViewModel(
        eventRepository: context.read<EventRepo.EventRepository>(),
        barRepository: context.read<BarRepo.BarRepository>(),
        authRepository: context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        authRepository: context.read<AuthRepository>(),
        barRepository: context.read<BarRepo.BarRepository>(),
      ),
    ),
  ];
}