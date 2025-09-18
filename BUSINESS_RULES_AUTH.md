# 🔐 BUSINESS_RULES_AUTH.md - Regras de Negócio para Autenticação

**Versão:** 2.0  
**Última Atualização:** 15 de Setembro de 2025  
**Objetivo:** Definição completa das regras de negócio para autenticação e cadastro

---

## 🎯 1. DECISÕES DE PRODUTO (FINAL)

### Autenticação por Email/Senha
- **Verificação obrigatória:** Email deve ser verificado antes de usar o app
- **Bloqueio de login:** Até `emailVerified=true`, com tela de verificação e "reenviar e-mail"
- **Fluxo:** Cadastro → Verificação → Acesso liberado

### Login Social
- **Acesso imediato:** Entra na Home, mas exibe banner para completar 3 passos
- **Completude:** Passo 1/2/3 até `completedFullRegistration=true`
- **Verificação:** `emailVerified=true` automático do provedor

### Unicidade
- **Email único:** Por bar, verificação no cliente + confirmação no servidor
- **CNPJ único:** Por bar, validação híbrida (cliente + Firestore)
- **Anti-race:** Debounce de 500ms + botão travado durante validação

### Sessão
- **ID Token:** ~1h de duração, refresh automático
- **UX:** Lidar com expiração sem travar o app
- **Logout:** Limpeza completa de dados locais

### Alternativa Robusta (Opcional)
- **Email link/passwordless:** Simplifica verificação, pois o email é verificado no próprio fluxo

---

## 🔄 2. FLUXOS DETALHADOS

### A) Cadastro por Email/Senha

#### Sequência
1. **Passo 1:** Dados de contato (email, cnpj, nome do bar, nome do responsável, telefone)
2. **Passo 2:** Endereço (CEP com auto-preenchimento), cidade e estado. 
3. **Passo 3:** Criação de senha
4. **Criação:** Usuário no Auth + envio de verificação + criação de `users/{uid}` e rascunho do bar
5. **Redirecionamento:** Tela de Verificação de E-mail
6. **Bloqueio:** App bloqueia acesso até verificar

#### Critérios de Aceite
- `emailVerified=false` ⇒ **SEM ACESSO** à Home, apenas tela de verificação
- **Polling:** Verificação a cada 3 segundos
- **Reenvio:** Botão "reenviar e-mail" disponível
- **Navegação:** Só libera após `emailVerified=true`

#### Estados do Sistema
```javascript
// Após Passo 3 (antes da verificação)
{
  emailVerified: false,
  completedFullRegistration: true,
  // Usuário criado mas bloqueado
}

// Após verificação de email
{
  emailVerified: true,
  completedFullRegistration: true,
  // Acesso liberado
}
```

### B) Social Login + Complemento

#### Sequência
1. **Login:** Google/Apple/Facebook
2. **Home:** Banner "Complete seu cadastro (0/3)"
3. **Complemento:** Passo 1 → Passo 2 → Passo 3
4. **Finalização:** `completedFullRegistration=true`

#### Estados do Sistema
```javascript
// Após login social (antes do complemento)
{
  emailVerified: true, // Do provedor
  completedFullRegistration: false,
  // Banner exibido na Home
}

// Após completar 3 passos
{
  emailVerified: true,
  completedFullRegistration: true,
  // Banner removido
}
```

### C) Estados Não-Autenticados Durante Cadastro

#### Pré-Rascunho Local
- **Somente Passo 1:** Pode aceitar dados em memória até autenticar
- **Persistência:** No Firestore só após existir `request.auth`
- **Exceção:** Fila de pré-cadastro via Callable Function (servidor) para validar unicidade

#### Validação de Unicidade
- **Cliente:** Verificação inicial via consulta Firestore
- **Servidor:** Confirmação via Rules/Cloud Function para evitar race conditions
- **Fluxo:** Cliente valida → Servidor confirma → Prossegue ou bloqueia

---

## ⚙️ 3. VALIDAÇÕES E CONTROLES

### Validação de Campos

#### Email
```dart
// Regex básico
final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

// Normalização
String normalizeEmail(String email) {
  return email.toLowerCase().trim();
}

// Verificação de unicidade
Future<bool> isEmailUnique(String email) async {
  final normalized = normalizeEmail(email);
  final query = await FirebaseFirestore.instance
      .collection('bars')
      .where('email', isEqualTo: normalized)
      .limit(1)
      .get();
  return query.docs.isEmpty;
}
```

#### CNPJ
```dart
// Limpeza de máscara
String cleanCnpj(String cnpj) {
  return cnpj.replaceAll(RegExp(r'[^\d]'), '');
}

// Validação de dígitos verificadores
bool isValidCnpj(String cnpj) {
  final clean = cleanCnpj(cnpj);
  if (clean.length != 14) return false;
  // Implementar algoritmo de validação
  return validateCnpjDigits(clean);
}

// Verificação de unicidade
Future<bool> isCnpjUnique(String cnpj) async {
  final clean = cleanCnpj(cnpj);
  final query = await FirebaseFirestore.instance
      .collection('bars')
      .where('cnpj', isEqualTo: clean)
      .limit(1)
      .get();
  return query.docs.isEmpty;
}
```

#### Telefone
```dart
// Validação DDD + 9 dígitos
bool isValidPhone(String phone) {
  final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (clean.length != 11) return false;
  
  final ddd = int.tryParse(clean.substring(0, 2));
  return ddd != null && ddd >= 11 && ddd <= 99;
}
```

### Anti-Duplo-Clique e Debounce

#### Implementação no ViewModel
```dart
class RegistrationViewModel extends ChangeNotifier {
  bool _isValidating = false;
  Timer? _debounceTimer;
  
  bool get isValidating => _isValidating;
  bool get canProceed => !_isValidating && _allFieldsValid;
  
  void validateAndProceed() {
    if (_isValidating) return; // Previne duplo-clique
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _performValidation();
    });
  }
  
  Future<void> _performValidation() async {
    _setValidating(true);
    
    try {
      // 1. Validação de formato
      if (!_validateFormats()) {
        _showFormatError();
        return;
      }
      
      // 2. Validação de unicidade
      if (!await _validateUniqueness()) {
        _showDuplicateError();
        return;
      }
      
      // 3. Navegação (só após sucesso)
      _navigateToNextStep();
      
    } catch (e) {
      _showGenericError();
    } finally {
      _setValidating(false);
    }
  }
  
  void _setValidating(bool value) {
    _isValidating = value;
    notifyListeners();
  }
}
```

#### UI - Botão com Estado
```dart
ElevatedButton(
  onPressed: viewModel.canProceed ? viewModel.validateAndProceed : null,
  child: viewModel.isValidating 
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Validando...'),
        ],
      )
    : Text('Continuar'),
)
```

---

## 🔒 4. SEGURANÇA E SESSÃO

### Gerenciamento de Token

#### Renovação Automática
```dart
class AuthService {
  StreamSubscription<User?>? _authSubscription;
  
  void initializeAuth() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _scheduleTokenRefresh(user);
      }
    });
  }
  
  void _scheduleTokenRefresh(User user) {
    Timer.periodic(Duration(minutes: 50), (timer) async {
      try {
        await user.getIdToken(true); // Force refresh
      } catch (e) {
        // Handle token refresh error
        _handleTokenError(e);
      }
    });
  }
}
```

#### Tratamento de Expiração
```dart
class ApiService {
  Future<T> makeRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on FirebaseException catch (e) {
      if (e.code == 'unauthenticated') {
        // Token expirado, tentar renovar
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        return await request(); // Retry
      }
      rethrow;
    }
  }
}
```

### Logout Seguro
```dart
Future<void> secureLogout() async {
  try {
    // 1. Limpar cache local
    await _clearLocalCache();
    
    // 2. Logout do Firebase
    await FirebaseAuth.instance.signOut();
    
    // 3. Limpar Provider states
    _clearProviderStates();
    
    // 4. Navegar para login
    context.go('/login');
    
  } catch (e) {
    // Log error mas não bloquear logout
    debugPrint('Erro no logout: $e');
  }
}
```

---

## 📱 5. UX - TELA DE VERIFICAÇÃO DE EMAIL

### Funcionalidades Obrigatórias

#### Auto-Verificação
```dart
class EmailVerificationPage extends StatefulWidget {
  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _verificationTimer;
  
  @override
  void initState() {
    super.initState();
    _startVerificationPolling();
  }
  
  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user?.emailVerified == true) {
        timer.cancel();
        context.go('/home');
      }
    });
  }
  
  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }
}
```

#### Reenvio de Email
```dart
Future<void> resendVerificationEmail() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      _showSuccessMessage('Email de verificação reenviado');
    }
  } catch (e) {
    _showErrorMessage('Erro ao reenviar email');
  }
}
```

#### Interface
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email_outlined, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'Verifique seu e-mail',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          Text(
            'Enviamos um link de verificação para:\n${user?.email}',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: resendVerificationEmail,
            child: Text('Reenviar e-mail'),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Voltar ao login'),
          ),
        ],
      ),
    ),
  );
}
```

---

## 🎯 6. CRITÉRIOS DE ACEITE FINAIS

### Cadastro Email/Senha
- [ ] Passo 1/2/3 funcionais com validação
- [ ] Criação de usuário no Firebase Auth
- [ ] Envio automático de email de verificação
- [ ] Redirecionamento para tela de verificação
- [ ] Bloqueio de acesso até `emailVerified=true`
- [ ] Polling de verificação a cada 3 segundos
- [ ] Botão "reenviar email" funcional
- [ ] Navegação para Home após verificação

### Login Social + Complemento
- [ ] Login Google/Apple/Facebook funcional
- [ ] Banner "Complete seu cadastro (0/3)" na Home
- [ ] Fluxo Passo 1/2/3 para complemento
- [ ] Remoção do banner após completar
- [ ] `completedFullRegistration=true` após Passo 3

### Validações e Segurança
- [ ] Debounce de 500ms em validações
- [ ] Botão travado durante validação
- [ ] Verificação de unicidade (email/CNPJ)
- [ ] Tratamento de race conditions
- [ ] Renovação automática de token
- [ ] Logout seguro com limpeza de dados

### Estados e Navegação
- [ ] Estados corretos no Firestore
- [ ] Navegação condicional baseada em flags
- [ ] Tratamento de expiração de sessão
- [ ] UX fluida sem travamentos

---

## 📚 7. DOCUMENTAÇÃO RELACIONADA

Para implementação técnica, consulte:

- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro
- **[FIRESTORE_SCHEMA.md](./FIRESTORE_SCHEMA.md)**: Estrutura de dados
- **[FIRESTORE_RULES.md](./FIRESTORE_RULES.md)**: Regras de segurança

---

**🔒 Este documento define as regras de negócio imutáveis. Qualquer alteração deve ser discutida e aprovada antes da implementação.**