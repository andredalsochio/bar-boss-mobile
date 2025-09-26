# 🔐 Firebase App Check - Guia de Configuração

**Versão:** 1.0  
**Última Atualização:** 17 de Janeiro de 2025  
**Objetivo:** Eliminar avisos de "Too many attempts", "empty reCAPTCHA token" e "App attestation failed"

---

## 🎯 Visão Geral

Este guia resolve os seguintes problemas:
- ❌ `FirebaseException: Too many attempts`
- ❌ `Linking email account with empty reCAPTCHA token`
- ❌ `App attestation failed`

**Estratégia:**
- **Desenvolvimento (emulador):** App Check Debug Token
- **Produção:** Play Integrity API (Android) + App Attest (iOS)

---

## 🚀 1. Configuração no Console Firebase

### 1.1 Configurar App Check

1. **Acesse o Console Firebase:**
   - Vá para [console.firebase.google.com](https://console.firebase.google.com)
   - Selecione seu projeto

2. **Navegue para App Check:**
   - Menu lateral → App Check
   - Clique em "Get started"

3. **Configure o Provider Android:**
   - Selecione seu app Android
   - Clique em "Configure provider"
   - Escolha **"Play Integrity"**
   - Clique em "Save"

4. **Configure o Provider iOS (se aplicável):**
   - Selecione seu app iOS
   - Clique em "Configure provider"
   - Escolha **"App Attest"**
   - Clique em "Save"

### 1.2 Configurar SHA Keys

1. **Acesse Project Settings:**
   - Ícone de engrenagem → Project settings
   - Aba "Your apps"

2. **Adicione SHA Keys:**
   ```bash
   # Para debug (desenvolvimento)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Para release (produção)
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
   ```

3. **Adicione no Console:**
   - Copie SHA-1 e SHA-256
   - Cole em "SHA certificate fingerprints"
   - Clique em "Add fingerprint"

4. **Baixe novo google-services.json:**
   - Após adicionar SHA keys
   - Substitua o arquivo em `android/app/google-services.json`

---

## 🛠️ 2. Configuração de Desenvolvimento (Debug)

### 2.1 Obter Debug Token

1. **Execute o app no emulador:**
   ```bash
   flutter run
   ```

2. **Procure no log por:**
   ```
   D/FirebaseAppCheck: App Check debug token: 9ee7ac52-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

3. **Copie o token completo**

### 2.2 Adicionar Debug Token ao Console

1. **No Console Firebase → App Check:**
   - Clique em "Manage debug tokens"
   - Clique em "Add debug token"
   - Cole o token copiado
   - Adicione uma descrição (ex: "Emulador Android - Dev")
   - Clique em "Save"

### 2.3 Verificar Configuração

1. **Reinicie o app**
2. **Verifique os logs:**
   ```
   I/FirebaseAppCheck: App Check debug token accepted
   ```

---

## 🏭 3. Configuração de Produção

### 3.1 Enforcement

⚠️ **IMPORTANTE:** Só ative o Enforcement após configurar todos os clientes!

1. **No Console Firebase → App Check:**
   - Selecione cada serviço (Auth, Firestore, etc.)
   - Clique em "Enforce"
   - Confirme a ação

### 3.2 Teste em Dispositivo Real

1. **Build release:**
   ```bash
   flutter build apk --release
   # ou
   flutter build appbundle --release
   ```

2. **Instale em dispositivo com Play Store**
3. **Verifique logs de produção**

---

## 🔧 4. Implementação no Código

### 4.1 Dependências Atualizadas

**pubspec.yaml:**
```yaml
dependencies:
  firebase_app_check: ^0.3.1+4
  # outras dependências...
```

**android/app/build.gradle.kts:**
```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
```

### 4.2 Configuração no main.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura App Check por ambiente
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode 
        ? AndroidProvider.playIntegrity   // Produção
        : AndroidProvider.debug,          // Desenvolvimento
    appleProvider: kReleaseMode
        ? AppleProvider.appAttest         // Produção
        : AppleProvider.debug,            // Desenvolvimento
  );

  runApp(const MyApp());
}
```

### 4.3 ThrottlingService (Mitigação de "Too many attempts")

O projeto agora inclui um `ThrottlingService` que:
- Implementa backoff exponencial
- Faz coalescing de operações redundantes
- Reduz chamadas simultâneas ao Firebase

**Uso em ViewModels:**
```dart
class AuthViewModel extends ChangeNotifier with ThrottlingMixin {
  Future<void> validateUser() async {
    final result = await executeThrottled<bool>(
      operationKey: 'user_validation',
      operation: () => _performValidation(),
    );
  }
}
```

---

## ✅ 5. Checklist de Validação

### 5.1 Desenvolvimento (Emulador)

- [ ] App abre sem "App attestation failed"
- [ ] Não há "Too many attempts" nos logs
- [ ] Debug token aparece no log na primeira execução
- [ ] Debug token foi adicionado ao Console Firebase
- [ ] Log mostra "App Check debug token accepted"
- [ ] Fluxo de autenticação funciona sem warnings relevantes
- [ ] Operações do Firestore funcionam normalmente

### 5.2 Console Firebase

- [ ] App Check configurado para Android (Play Integrity)
- [ ] App Check configurado para iOS (App Attest) - se aplicável
- [ ] SHA-1 e SHA-256 de debug adicionadas
- [ ] SHA-1 e SHA-256 de release adicionadas
- [ ] google-services.json atualizado após mudanças de SHA
- [ ] Debug tokens adicionados para desenvolvimento
- [ ] Enforcement configurado apenas após testes

### 5.3 Produção (Dispositivo Real)

- [ ] Build release funciona em dispositivo com Play Store
- [ ] Não há erros de App Check em produção
- [ ] Autenticação funciona sem reCAPTCHA manual
- [ ] "Linking email account with empty reCAPTCHA token" não aparece
- [ ] Performance normal das operações Firebase

---

## 🚨 6. Troubleshooting

### 6.1 "Too many attempts" ainda aparece

**Possíveis causas:**
- Debug token não foi adicionado ao Console
- Debug token mudou (reinstalação do app)
- Múltiplas inicializações do Firebase

**Soluções:**
1. Verifique se o debug token atual está no Console
2. Reinstale o app e obtenha novo token se necessário
3. Verifique se `FirebaseAppCheck.instance.activate()` é chamado apenas uma vez

### 6.2 "App attestation failed" em produção

**Possíveis causas:**
- SHA keys incorretas ou ausentes
- Dispositivo sem Play Store ou GMS desatualizado
- App não assinado corretamente

**Soluções:**
1. Verifique SHA keys no Console Firebase
2. Teste em dispositivo com Play Store atualizado
3. Confirme assinatura do APK/AAB

### 6.3 "empty reCAPTCHA token" persiste

**Possíveis causas:**
- App Check não está funcionando corretamente
- Enforcement ativo sem configuração adequada

**Soluções:**
1. Verifique logs do App Check
2. Temporariamente desative Enforcement para testar
3. Confirme que Play Integrity está ativo

### 6.4 Debug token não funciona

**Possíveis causas:**
- Token copiado incorretamente
- Token expirado ou inválido
- Configuração de ambiente incorreta

**Soluções:**
1. Copie o token completo do log
2. Verifique se está em modo debug (`kReleaseMode = false`)
3. Limpe e reinstale o app para gerar novo token

---

## 📊 7. Monitoramento

### 7.1 Logs Importantes

**Sucesso:**
```
I/FirebaseAppCheck: App Check debug token accepted
I/FirebaseAppCheck: App Check token refreshed successfully
```

**Problemas:**
```
E/FirebaseAppCheck: App Check token request failed
W/FirebaseAppCheck: App attestation failed
E/FirebaseAppCheck: Too many attempts, please try again later
```

### 7.2 Métricas no Console

1. **Firebase Console → App Check:**
   - Monitore requests e success rate
   - Verifique tokens válidos vs inválidos

2. **Firebase Console → Analytics:**
   - Acompanhe eventos de autenticação
   - Monitore crashes relacionados ao App Check

---

## 🔄 8. Manutenção

### 8.1 Atualizações Regulares

- **Firebase BOM:** Mantenha atualizado
- **Play Services:** Verifique compatibilidade
- **Debug Tokens:** Renovar quando necessário

### 8.2 Testes Periódicos

- **Emulador:** Teste após atualizações
- **Dispositivos reais:** Teste builds de produção
- **Console Firebase:** Monitore métricas regularmente

---

## 📚 9. Referências

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Play Integrity API](https://developer.android.com/google/play/integrity)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [SHA Certificate Fingerprints](https://developers.google.com/android/guides/client-auth)

---

**🔄 Mantenha este documento atualizado após mudanças na configuração do Firebase App Check.**