# Arquitetura de Domínio - Bar Boss Mobile

Este documento descreve a implementação da camada de abstrações de domínio (Clean MVVM) no projeto Bar Boss Mobile, permitindo a troca futura de backend (Firebase ⇄ outro) mantendo compatibilidade com o código atual.

## 📁 Estrutura de Pastas

```
lib/app/
├── domain/
│   ├── entities/
│   │   └── user_profile.dart          # Entidade UserProfile
│   └── repositories/
│       ├── auth_repository.dart        # Interface de autenticação
│       ├── user_repository.dart        # Interface de usuário
│       ├── bar_repository_domain.dart  # Interface de bares
│       ├── event_repository_domain.dart # Interface de eventos
│       └── repositories.dart           # Exporta todas as interfaces
├── data/
│   └── firebase/
│       ├── firebase_auth_repository.dart    # Implementação Firebase Auth
│       ├── firebase_user_repository.dart    # Implementação Firebase User
│       ├── firebase_bar_repository.dart     # Implementação Firebase Bar
│       ├── firebase_event_repository.dart   # Implementação Firebase Event
│       └── firebase_repositories.dart       # Exporta todas as implementações
└── core/
    └── di/
        └── dependency_injection.dart       # Configuração de DI
```

## 🔧 Interfaces de Domínio

### AuthRepository
Gerencia autenticação com múltiplos provedores:
- `authStateChanges()` - Stream de mudanças de estado
- `signInWithEmail()`, `signInWithGoogle()`, `signInWithApple()`, `signInWithFacebook()`
- `sendEmailVerification()`, `isEmailVerified()`
- `linkEmailPassword()`, `signOut()`

### UserRepository
Gerencia perfis de usuário:
- `getMe()` - Busca perfil do usuário atual
- `upsert(UserProfile)` - Cria ou atualiza perfil

### BarRepositoryDomain
Gerencia bares com transações complexas:
- `create(Bar)` - Cria bar + cnpj_registry + members(OWNER) em transação
- `update(Bar)` - Atualiza dados do bar
- `listMyBars(String uid)` - Lista bares via collectionGroup('members')
- `addMember(String barId, String uid, String role)` - Adiciona membro

### EventRepositoryDomain
Gerencia eventos de bares:
- `upcomingByBar(String barId)` - Stream de eventos futuros ordenados por startAt
- `create(String barId, Event)` - Cria novo evento
- `update(String barId, Event)` - Atualiza evento existente
- `delete(String barId, String eventId)` - Remove evento

## 🔄 Implementações Firebase

Todas as implementações Firebase reutilizam a lógica existente dos repositórios atuais:

- **FirebaseAuthRepository**: Utiliza `AuthService` existente
- **FirebaseUserRepository**: Gerencia `UserProfile` no Firestore
- **FirebaseBarRepository**: Reutiliza `BarRepository.createBarWithReservation()`
- **FirebaseEventRepository**: Implementa validações de data (endAt >= startAt)

## 📋 Validações Implementadas

### Eventos
- **Regra de data**: `endAt == null || endAt >= startAt`
- **Eventos publicados**: Apenas eventos com `published: true` aparecem em `upcomingByBar()`
- **Ordenação**: Eventos ordenados por `startAt` crescente

### Bares
- **CNPJ**: Normalização automática (remove caracteres não numéricos)
- **Transação**: Criação atômica de bar + registro CNPJ + membro OWNER

## 🔌 Injeção de Dependências

O arquivo `DependencyInjection` centraliza toda a configuração:

```dart
// Domain interfaces com implementações Firebase
Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
Provider<UserRepository>(create: (_) => FirebaseUserRepository()),
Provider<BarRepositoryDomain>(create: (_) => FirebaseBarRepository()),
Provider<EventRepositoryDomain>(create: (_) => FirebaseEventRepository()),

// Legacy repositories (mantidos para compatibilidade)
Provider<BarRepository>(create: (_) => BarRepository()),
Provider<EventRepository>(create: (_) => EventRepository()),
```

## 🔄 Compatibilidade

### Código Atual
Todos os ViewModels e serviços existentes continuam funcionando normalmente:
- `AuthViewModel` usa `BarRepository` (legacy)
- `BarRegistrationViewModel` usa `BarRepository` (legacy)
- `EventsViewModel` usa `EventRepository` (legacy)

### Migração Futura
Para migrar um ViewModel para usar as novas interfaces:

```dart
// Antes (legacy)
class EventsViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  
// Depois (domain)
class EventsViewModel extends ChangeNotifier {
  final EventRepositoryDomain _eventRepository;
```

## 🚀 Benefícios

1. **Flexibilidade**: Troca de backend sem alterar ViewModels
2. **Testabilidade**: Interfaces facilitam mocks em testes
3. **Separação de responsabilidades**: Domínio isolado da infraestrutura
4. **Compatibilidade**: Zero breaking changes no código atual
5. **Escalabilidade**: Fácil adição de novos backends (Supabase, AWS, etc.)

## 📝 Próximos Passos

1. **Testes unitários**: Criar mocks das interfaces para testes
2. **Migração gradual**: Migrar ViewModels um por vez para usar interfaces de domínio
3. **Documentação**: Adicionar exemplos de uso das novas interfaces
4. **Validação**: Implementar validações de negócio nas interfaces
5. **Cache local**: Integrar Drift como camada de cache offline

---

*Esta arquitetura segue os princípios de Clean Architecture e SOLID, garantindo um código mais maintível e testável.*