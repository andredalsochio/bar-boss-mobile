# Fluxo de Autenticação com Verificação de E-mail

## Visão Geral

Este documento descreve o fluxo completo de autenticação implementado no Bar Boss Mobile, incluindo a verificação obrigatória de e-mail para todas as operações sensíveis.

## Arquitetura

### Componentes Principais

- **AuthService**: Camada de serviço que abstrai operações do Firebase Auth
- **FirebaseAuthRepository**: Implementação concreta das operações de autenticação
- **AuthViewModel**: Gerenciamento de estado da autenticação na UI
- **Guards de Navegação**: Proteção de rotas baseada no status de autenticação e verificação

## Fluxos de Autenticação

### 1. Cadastro com E-mail e Senha

```
1. Usuário preenche formulário de cadastro (Passo 3)
2. Sistema cria conta no Firebase Auth
3. Sistema envia automaticamente e-mail de verificação
4. Usuário é redirecionado para EmailVerificationPage
5. Usuário verifica e-mail através do link recebido
6. Sistema detecta verificação e redireciona para EmailVerificationSuccessPage
7. Usuário pode acessar funcionalidades completas
```

### 2. Login Social (Google, Apple, Facebook)

```
1. Usuário seleciona provedor social
2. Sistema autentica via provedor
3. E-mail é automaticamente verificado pelo provedor
4. Usuário acessa funcionalidades completas imediatamente
```

### 3. Login com E-mail e Senha

```
1. Usuário insere credenciais
2. Sistema autentica no Firebase Auth
3. Sistema verifica status de verificação do e-mail
4. Se não verificado: logout automático + erro
5. Se verificado: acesso liberado
```

### 4. Recuperação de Senha

```
1. Usuário acessa ForgotPasswordPage
2. Insere e-mail cadastrado
3. Sistema envia link de reset via Firebase Auth
4. Usuário redefine senha através do link
5. Nova senha mantém verificação de e-mail existente
```

## Guards de Navegação

### Hierarquia de Verificação

1. **Autenticação**: Usuário deve estar logado
2. **Verificação de E-mail**: E-mail deve estar verificado
3. **Cadastro de Bar**: Bar deve estar cadastrado (para certas funcionalidades)

### Implementação no GoRouter

```dart
String? _handleRedirect(BuildContext context, GoRouterState state) {
  final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
  
  // 1. Verificar autenticação
  if (!authViewModel.isAuthenticated) {
    return AppRoutes.login;
  }
  
  // 2. Verificar e-mail (exceto rotas de verificação)
  if (!authViewModel.isCurrentUserEmailVerified && 
      !_isEmailVerificationRoute(state.matchedLocation)) {
    return AppRoutes.emailVerification;
  }
  
  // 3. Verificar cadastro de bar (se necessário)
  return _handleBarRegistrationGuard(context, state);
}
```

## Segurança no Firestore

### Regras de Segurança

Todas as operações sensíveis exigem e-mail verificado:

```javascript
function isEmailVerified() { 
  return request.auth != null && request.auth.token.email_verified == true; 
}

// Exemplo de uso
allow create: if isAuth() && isEmailVerified() && validBar(request.resource.data);
```

### Operações Protegidas

- Criação de bares
- Atualização de bares
- Exclusão de bares
- Gerenciamento de membros
- Criação/edição de eventos
- Registro de CNPJ

## Estados da Verificação de E-mail

### AuthViewModel States

```dart
class AuthViewModel extends ChangeNotifier {
  bool get isAuthenticated => _currentUser != null;
  bool get isCurrentUserEmailVerified => _currentUser?.emailVerified ?? false;
  bool get isFromSocialProvider => _isFromSocialProvider;
  
  // Métodos de verificação
  Future<void> sendEmailVerification();
  Future<void> checkEmailVerificationStatus();
}
```

### UI States

- **Não Autenticado**: LoginPage
- **Autenticado + E-mail Não Verificado (E-mail/Senha)**: EmailVerificationPage
- **Autenticado + Login Social**: Acesso completo (e-mail automaticamente verificado)
- **Autenticado + E-mail Verificado**: Acesso completo
- **Verificação Concluída**: EmailVerificationSuccessPage (temporário)

### Estados de Verificação por Tipo de Login

#### E-mail Verificado
- Usuário pode acessar todas as funcionalidades
- Não há restrições de navegação
- Estado normal de operação

#### E-mail Não Verificado
- **Para usuários de e-mail/senha:** Redirecionado para `EmailVerificationPage`
- **Para usuários de login social:** Verificação ignorada (e-mail já verificado pelo provedor)
- Não pode acessar outras telas até verificar (apenas e-mail/senha)
- Pode reenviar e-mail de verificação
- Pode fazer logout

#### Verificação de Provedor Social
- Usuários do Google, Apple e Facebook têm e-mails automaticamente considerados verificados
- Propriedade `isFromSocialProvider` no `AuthViewModel` identifica esses usuários
- Guards de navegação respeitam essa condição

## Telas de Verificação

### EmailVerificationPage

**Funcionalidades:**
- Exibe e-mail do usuário atual
- Botão para reenviar e-mail de verificação
- Botão para verificar status manualmente
- Timer automático de verificação (30s)
- Logout para trocar de conta

### EmailVerificationSuccessPage

**Funcionalidades:**
- Confirmação visual de sucesso
- Redirecionamento automático para Home
- Design consistente com tema do app

## Tratamento de Erros

### Cenários Comuns

1. **E-mail já cadastrado**: Erro específico no cadastro
2. **E-mail não verificado no login**: Logout + redirecionamento
3. **Falha no envio de verificação**: Retry automático
4. **Token de verificação expirado**: Reenvio necessário

### Logs de Segurança

```dart
// Exemplo de log seguro (sem expor dados sensíveis)
logger.info('Email verification sent to user: ${email.substring(0, 3)}***');
```

## Configuração do Firebase

### ActionCodeSettings

```dart
ActionCodeSettings actionCodeSettings = ActionCodeSettings(
  url: 'https://barboss.page.link/verify',
  handleCodeInApp: true,
  iOSBundleId: 'com.barboss.mobile',
  androidPackageName: 'com.barboss.mobile',
  androidInstallApp: true,
  androidMinimumVersion: '21',
);
```

### Deep Links

- **Verificação**: `https://barboss.page.link/verify`
- **Reset de Senha**: `https://barboss.page.link/reset`

## Testes

### Cenários de Teste

1. **Cadastro completo**: E-mail → Verificação → Acesso
2. **Login social**: Acesso imediato
3. **Login sem verificação**: Bloqueio + erro
4. **Reenvio de verificação**: Funcionalidade
5. **Recuperação de senha**: Fluxo completo
6. **Guards de navegação**: Redirecionamentos corretos

### Testes de Segurança

1. **Firestore Rules**: Operações bloqueadas sem verificação
2. **Token Validation**: Verificação server-side
3. **Deep Link Security**: Validação de origem

## Manutenção

### Monitoramento

- Taxa de verificação de e-mail
- Tempo médio para verificação
- Erros de envio de e-mail
- Tentativas de acesso não verificado

### Atualizações Futuras

- Verificação por SMS (opcional)
- Verificação em duas etapas
- Biometria para re-autenticação
- Gestão de sessões múltiplas

## Conclusão

O fluxo de verificação de e-mail implementado garante:

✅ **Segurança**: Apenas usuários verificados acessam funcionalidades sensíveis  
✅ **UX Consistente**: Fluxos claros e intuitivos  
✅ **Conformidade**: Boas práticas de autenticação  
✅ **Escalabilidade**: Arquitetura preparada para expansão  

---

**Última atualização**: Janeiro 2025  
**Versão**: 1.0  
**Responsável**: Equipe de Desenvolvimento Bar Boss Mobile