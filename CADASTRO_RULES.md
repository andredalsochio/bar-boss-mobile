# 🎯 CADASTRO_RULES.md - Fonte Única da Verdade

**Versão:** 2.0  
**Data:** 15 de Setembro de 2025  
**Objetivo:** Especificação definitiva dos fluxos de cadastro do Bar Boss Mobile

---

## 🔄 1. FLUXOS DE CADASTRO DEFINIDOS

### **A. Cadastro Completo (Email/Senha)**
```
Entrada: Tela de Login → "Não tem um bar?"
Fluxo: Passo 1 → Passo 2 → Passo 3 → Tela de Verificação de Email → Home
Banner: Não exibe (cadastro já completo)
Resultado: completedFullRegistration: true + emailVerified: true
```

**⚠️ REGRA CRÍTICA:** Após o Passo 3, o usuário é direcionado para a **Tela de Verificação de Email** e **NÃO PODE ACESSAR O APLICATIVO** até que o email seja verificado. O login só é permitido após a verificação.

### **B. Login Social + Complemento**
```
Entrada: Login Google/Apple/Facebook
Fluxo: Home (banner) → Passo 1 → Passo 2 → Passo 3 → Home
Banner: "Complete seu cadastro (0/3)"
Resultado: completedFullRegistration: true
```

**🎯 DECISÃO FINAL:** Login social completa em **3 passos** (incluindo senha).

---

## 📋 2. ESPECIFICAÇÃO DOS PASSOS

### **Passo 1: Dados de Contato**
**Campos Obrigatórios:**
- Email (validação de formato)
- CNPJ (validação de formato)
- Nome do bar
- Nome do responsável
- Telefone (DDD + 9 dígitos)

**Validações:**
- Email: formato válido
- CNPJ: formato + dígitos verificadores
- Telefone: DDD válido + 9 dígitos

### **Passo 2: Endereço**
**Campos Obrigatórios:**
- CEP (auto-preenchimento via API)
- Estado (dropdown)
- Cidade
- Rua
- Número
- Complemento (opcional)

### **Passo 3: Senha**
**Campos Obrigatórios:**
- Senha (mínimo 8 caracteres)
- Confirmação de senha

**Validações:**
- Senhas devem ser idênticas
- Mínimo 8 caracteres

---

## 🔒 3. REGRAS DE VALIDAÇÃO

### **A. Validação de Email**

#### **Cadastro Completo:**
```dart
Future<bool> validateEmailFormat(String email) async {
  final normalizedEmail = email.toLowerCase().trim();
  
  // Validar formato do email
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(normalizedEmail)) {
    throw ValidationException("Email inválido");
  }
  
  return true;
}
```

#### **Login Social:**
```dart
// Email vem do provedor (Google/Apple/Facebook)
// Apenas normalizar: email.toLowerCase().trim()
```

### **B. Validação de CNPJ**

```dart
Future<bool> validateCnpjFormat(String cnpj) async {
  final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');
  
  // Validar formato e dígitos verificadores
  if (!isValidCnpj(cleanCnpj)) {
    throw ValidationException("CNPJ inválido");
  }
  
  return true;
}

// Algoritmo de validação de CNPJ
bool isValidCnpj(String cnpj) {
  // Verificar se tem 14 dígitos
  if (cnpj.length != 14) return false;
  
  // Verificar se todos os dígitos são iguais
  if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;
  
  // Calcular primeiro dígito verificador
  int soma = 0;
  int peso = 2;
  for (int i = 11; i >= 0; i--) {
    soma += int.parse(cnpj[i]) * peso;
    peso = peso == 9 ? 2 : peso + 1;
  }
  int digito1 = soma % 11 < 2 ? 0 : 11 - (soma % 11);
  
  // Verificar primeiro dígito
  if (int.parse(cnpj[12]) != digito1) return false;
  
  // Calcular segundo dígito verificador
  soma = 0;
  peso = 2;
  for (int i = 12; i >= 0; i--) {
    soma += int.parse(cnpj[i]) * peso;
    peso = peso == 9 ? 2 : peso + 1;
  }
  int digito2 = soma % 11 < 2 ? 0 : 11 - (soma % 11);
  
  // Verificar segundo dígito
  return int.parse(cnpj[13]) == digito2;
}
```

### **C. Esqueci Minha Senha**

**Regra de Segurança:** O sistema deve verificar se o email existe na base de dados antes de enviar o email de recuperação, para evitar ataques de enumeração de usuários.

```dart
Future<void> sendPasswordResetEmailSecure(String email) async {
  final normalizedEmail = email.toLowerCase().trim();
  
  try {
    // 1. Verificar se email existe na coleção bars
    final barQuery = await FirebaseFirestore.instance
      .collection('bars')
      .where('email', isEqualTo: normalizedEmail)
      .limit(1)
      .get();
    
    // 2. Verificar se email existe no Firebase Auth (tentativa de reset)
    if (barQuery.docs.isNotEmpty) {
      // Email existe na base, pode enviar reset
      await FirebaseAuth.instance.sendPasswordResetEmail(email: normalizedEmail);
      // Sempre mostrar mensagem de sucesso (mesmo se email não existir no Auth)
      showSuccessMessage("Se o email estiver cadastrado, você receberá as instruções de recuperação.");
    } else {
      // Email não existe na base, simular sucesso por segurança
      showSuccessMessage("Se o email estiver cadastrado, você receberá as instruções de recuperação.");
    }
  } catch (e) {
    // Sempre mostrar mensagem genérica por segurança
    showSuccessMessage("Se o email estiver cadastrado, você receberá as instruções de recuperação.");
  }
}
```

---

## 🚫 4. ESTRATÉGIAS ANTI-DUPLO-CLIQUE

### **A. Estado do Botão "Continuar"**

| Estado | Condição | Ação |
|--------|----------|------|
| **Habilitado** | Todos os campos válidos + sem erro | Permite clique |
| **Desabilitado** | Campos inválidos OU validando OU erro | Bloqueia clique |
| **Loading** | Validação em andamento | Mostra spinner |
| **Erro** | Validação falhou | Mostra mensagem |

### **B. Implementação Anti-Race-Condition**

```dart
class BarRegistrationViewModel extends ChangeNotifier {
  bool _isValidating = false;
  bool _hasValidationError = false;
  String? _errorMessage;
  CancelToken? _currentValidationToken;
  Timer? _debounceTimer;
  
  // Estado reativo do botão
  bool get canProceed => 
    _areAllFieldsValid && 
    !_isValidating && 
    !_hasValidationError;
  
  // Validação com debounce
  Future<void> validateWithDebounce(String value, Function(String) validator) async {
    // Cancelar timer anterior se existir
    _debounceTimer?.cancel();
    
    // Iniciar novo timer de debounce (500ms)
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      await validator(value);
    });
  }

  Future<void> validateAndProceed() async {
    // 1. Bloquear duplo-clique
    if (_isValidating) return;
    
    // 2. Cancelar validação anterior
    _currentValidationToken?.cancel();
    _currentValidationToken = CancelToken();
    
    // 3. Iniciar validação
    _setValidating(true);
    _clearError();
    
    try {
      // 4. Validar email e CNPJ
      await _validateEmailUniqueness();
      await _validateCnpjUniqueness();
      
      // 5. Só navegar se tudo passou
      _navigateToNextStep();
      
    } catch (e) {
      // 6. Persistir erro (impede navegação)
      if (!_currentValidationToken!.isCancelled) {
        _setError(e.message);
      }
    } finally {
      // 7. Liberar botão
      _setValidating(false);
    }
  }
  
  void _setValidating(bool value) {
    _isValidating = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _hasValidationError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _hasValidationError = false;
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

## 🏠 5. REGRAS DA HOME E BANNER

### **A. Exibição do Banner**

```dart
bool shouldShowCompletionBanner(User user) {
  // Só exibir para usuários de login social incompletos
  return user.isFromSocialLogin && 
         !user.completedFullRegistration;
}

Widget buildCompletionBanner() {
  return Banner(
    text: "Complete seu cadastro (0/3)",
    action: "Completar agora",
    onTap: () => context.go('/cadastro/passo1'),
  );
}
```

### **B. Regras de Acesso**

| Funcionalidade | Cadastro Incompleto | Cadastro Completo |
|----------------|-------------------|------------------|
| **Criar Eventos** | ✅ Permitido (com aviso) | ✅ Permitido |
| **Editar Perfil** | ✅ Permitido | ✅ Permitido |
| **Funcionalidades Premium** | ❌ Bloqueado | ✅ Permitido |

---

## 🔥 6. REGRAS DO FIRESTORE (SERVIDOR)

### **A. Validação de Criação de Bar**

```javascript
// firestore.rules
function canCreateBar() {
  return isAuth() && 
         (isEmailVerified() || isFromSocialLogin()) &&
         isRecentlyCreated();
}

function validateBarData(data) {
  return data.keys().hasAll(['email', 'cnpj', 'name', 'responsibleName', 'contactPhone']) &&
         data.email is string &&
         data.email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$') &&
         data.cnpj is string &&
         data.cnpj.matches('^[0-9]{14}$'); // CNPJ limpo
}

// Regra de criação
match /bars/{barId} {
  allow create: if canCreateBar() && validateBarData(resource.data);
}
```

---

## 🧪 7. CENÁRIOS DE TESTE

### **A. Testes de Validação**

```dart
// Test: Validação de formato de email
testWidgets('should validate email format', (tester) async {
  // Act: Inserir email inválido
  await tester.enterText(emailField, 'email-invalido');
  await tester.tap(continueButton);
  await tester.pumpAndSettle();
  
  // Assert: Deve mostrar erro de formato
  expect(find.text('Email inválido'), findsOneWidget);
  expect(find.byType(Step2Page), findsNothing);
});

testWidgets('should validate CNPJ format', (tester) async {
  // Act: Inserir CNPJ inválido
  await tester.enterText(cnpjField, '12345678000100');
  await tester.tap(continueButton);
  await tester.pumpAndSettle();
  
  // Assert: Deve mostrar erro de formato
  expect(find.text('CNPJ inválido'), findsOneWidget);
  expect(find.byType(Step2Page), findsNothing);
});
```

### **B. Testes de Fluxo Social**

```dart
// Test: Login social deve mostrar banner 0/3
testWidgets('should show 0/3 banner after social login', (tester) async {
  // Arrange: Usuário logado via Google, cadastro incompleto
  when(mockAuth.currentUser).thenReturn(mockSocialUser);
  when(mockUser.completedFullRegistration).thenReturn(false);
  
  // Act: Navegar para Home
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  
  // Assert: Banner deve mostrar 0/3
  expect(find.text('Complete seu cadastro (0/3)'), findsOneWidget);
});
```

---

## 📊 8. CONTRATOS DE VIEWMODEL

### **A. Estados Obrigatórios**

```dart
abstract class RegistrationViewModelContract {
  // Estados de validação
  bool get isValidating;
  bool get hasValidationError;
  String? get validationErrorMessage;
  
  // Estados de campos
  bool get isEmailValid;
  bool get isCnpjValid;
  bool get areAllFieldsValid;
  
  // Estado do botão
  bool get canProceed;
  
  // Eventos
  Future<void> validateEmail(String email);
  Future<void> validateCnpj(String cnpj);
  Future<void> validateAndProceed();
  
  // Navegação
  void navigateToNextStep();
  void navigateBack();
}
```

### **B. Side Effects**

```dart
enum RegistrationSideEffect {
  showEmailError(String message),
  showCnpjError(String message),
  showGenericError(String message),
  navigateToStep2(),
  navigateToStep3(),
  navigateToHome(),
}
```

---

## ✅ 9. CHECKLIST DE IMPLEMENTAÇÃO

### **Frontend (Flutter)**
- [ ] Implementar validações de formato
- [ ] Bloquear botão durante validação
- [ ] Persistir estado de erro até correção
- [ ] Implementar banner 0/3 para login social
- [ ] Validar CNPJ com dígitos verificadores

### **Backend (Firebase)**
- [ ] Configurar regras básicas do Firestore
- [ ] Implementar autenticação com Firebase Auth
- [ ] Configurar estrutura de dados dos bares

### **Testes**
- [ ] Testes unitários de validação de formato
- [ ] Testes de widget para formulários
- [ ] Testes E2E de fluxos completos
- [ ] Testes de navegação entre passos

---

**🎯 Esta é a fonte única da verdade para todas as regras de cadastro. Qualquer divergência deve ser resolvida seguindo esta especificação.**