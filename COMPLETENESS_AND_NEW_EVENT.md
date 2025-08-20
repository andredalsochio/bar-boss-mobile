# Implementação da Lógica de Verificação de Completude e Botão Novo Evento

## Visão Geral

Este documento detalha a implementação da lógica de verificação de completude do perfil do bar e a funcionalidade do botão "Novo Evento" na aplicação Bar Boss Mobile.

## 1. Verificação de Completude do Perfil

### 1.1 Campos de Completude

O perfil do bar possui dois flags de completude:

- `contactsComplete`: Indica se as informações de contato foram preenchidas
- `addressComplete`: Indica se as informações de endereço foram preenchidas

### 1.2 Critérios de Completude

#### Contatos Completos (`contactsComplete = true`)
- Email válido e verificado
- CNPJ válido e único
- Nome do bar preenchido
- Nome do responsável preenchido
- Telefone com DDD válido

#### Endereço Completo (`addressComplete = true`)
- CEP válido
- Logradouro preenchido
- Estado selecionado
- Cidade preenchida
- Número preenchido
- Complemento (opcional)

### 1.3 Implementação Técnica

#### Localização do Código
- **Arquivo**: `lib/app/navigation/app_router.dart`
- **Linha**: 130
- **TODO**: Implementar lógica de verificação de completude

#### Estrutura da Implementação

```dart
// Método para verificar completude do perfil
bool _isProfileComplete(BarProfile? profile) {
  if (profile == null) return false;
  
  return profile.contactsComplete && profile.addressComplete;
}

// Guard de navegação baseado na completude
String? _profileCompletenessRedirect(BuildContext context, GoRouterState state) {
  final authState = context.read<AuthViewModel>();
  final userProfile = authState.userProfile;
  final barProfile = authState.barProfile;
  
  // Se não há perfil de bar, redirecionar para cadastro
  if (barProfile == null) {
    return '/register-step1';
  }
  
  // Verificar se o perfil está completo
  final isComplete = _isProfileComplete(barProfile);
  
  // Se incompleto, permitir navegação mas exibir banner na Home
  // (não bloquear navegação conforme PROJECT_RULES.md)
  return null;
}
```

### 1.4 UX de Completude na Home

#### Banner de Completude
- **Exibição**: Quando `contactsComplete == false` ou `addressComplete == false`
- **Texto**: "Complete seu cadastro (X/2)"
- **CTA**: "Completar agora" → navega para o passo incompleto
- **Não exibir**: Após fluxo completo iniciado por "Não tem um bar?"

#### Implementação no HomeViewModel

```dart
class HomeViewModel extends ChangeNotifier {
  bool get shouldShowCompletenesseBanner {
    final profile = _authRepository.currentBarProfile;
    if (profile == null) return false;
    
    // Não exibir se veio do fluxo completo de cadastro
    if (profile.createdViaFullRegistration == true) return false;
    
    return !profile.contactsComplete || !profile.addressComplete;
  }
  
  String get completenessMessage {
    final profile = _authRepository.currentBarProfile;
    if (profile == null) return "";
    
    int completed = 0;
    if (profile.contactsComplete) completed++;
    if (profile.addressComplete) completed++;
    
    return "Complete seu cadastro ($completed/2)";
  }
  
  String get nextStepRoute {
    final profile = _authRepository.currentBarProfile;
    if (profile == null) return '/register-step1';
    
    if (!profile.contactsComplete) return '/register-step1';
    if (!profile.addressComplete) return '/register-step2';
    
    return '/home'; // Fallback
  }
}
```

## 2. Botão Novo Evento

### 2.1 Comportamento

- **Localização**: Tela Home
- **Ação**: Navegar para `/events/new`
- **Restrições**: Nenhuma (não bloquear por perfil incompleto)
- **Lembrete**: Pode exibir bottom sheet após criação se perfil incompleto

### 2.2 Implementação

#### Widget do Botão

```dart
class NewEventButton extends StatelessWidget {
  const NewEventButton({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _onNewEventPressed(context),
      icon: const Icon(Icons.add),
      label: const Text('Novo Evento'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  void _onNewEventPressed(BuildContext context) {
    // Navegar para criação de evento
    context.go('/events/new');
    
    // Opcional: verificar completude e exibir lembrete
    _checkAndShowCompletenessReminder(context);
  }
  
  void _checkAndShowCompletenessReminder(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    
    if (homeViewModel.shouldShowCompletenesseBanner) {
      // Exibir bottom sheet com lembrete (opcional)
      showModalBottomSheet(
        context: context,
        builder: (context) => const CompletenessReminderBottomSheet(),
      );
    }
  }
}
```

#### Bottom Sheet de Lembrete (Opcional)

```dart
class CompletenessReminderBottomSheet extends StatelessWidget {
  const CompletenessReminderBottomSheet({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Perfil Incompleto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete seu perfil para melhorar a visibilidade dos seus eventos.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Agora não'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final homeViewModel = context.read<HomeViewModel>();
                    context.go(homeViewModel.nextStepRoute);
                  },
                  child: const Text('Completar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## 3. Fluxo de Navegação

### 3.1 Cenários de Navegação

1. **Usuário autenticado com perfil completo**:
   - Home → sem banner
   - "Novo Evento" → `/events/new` diretamente

2. **Usuário autenticado com perfil incompleto**:
   - Home → exibe banner de completude
   - "Novo Evento" → `/events/new` + opcional lembrete
   - Banner CTA → navega para passo incompleto

3. **Usuário sem perfil de bar**:
   - Redirecionamento automático para `/register-step1`

### 3.2 Guards de Navegação

```dart
// No app_router.dart
GoRoute(
  path: '/home',
  builder: (context, state) => const HomePage(),
  redirect: _authGuard, // Verificar autenticação
),

GoRoute(
  path: '/events/new',
  builder: (context, state) => const EventFormPage(),
  redirect: (context, state) {
    // Verificar autenticação primeiro
    final authRedirect = _authGuard(context, state);
    if (authRedirect != null) return authRedirect;
    
    // Verificar se tem perfil de bar (mínimo necessário)
    final authState = context.read<AuthViewModel>();
    if (authState.barProfile == null) {
      return '/register-step1';
    }
    
    return null; // Permitir acesso mesmo com perfil incompleto
  },
),
```

## 4. Considerações Técnicas

### 4.1 Performance
- Usar `Consumer` ou `Selector` para otimizar rebuilds
- Cache do estado de completude no ViewModel
- Lazy loading dos dados de perfil

### 4.2 Testes
- Unit tests para lógica de completude
- Widget tests para exibição do banner
- Integration tests para fluxo completo

## 5. Próximos Passos

1. Implementar método `_isProfileComplete` no `app_router.dart`
2. Adicionar propriedades de completude no `HomeViewModel`
3. Criar widget `CompletenesseBanner` para a Home
4. Implementar `NewEventButton` com navegação

## 6. Referências

- `PROJECT_RULES.md` - Seção 7 (UX — Fase 2)
- `FIRESTORE_SCHEMA.md` - Estrutura do BarProfile
- `lib/app/modules/home/viewmodels/home_viewmodel.dart`
- `lib/app/navigation/app_router.dart`