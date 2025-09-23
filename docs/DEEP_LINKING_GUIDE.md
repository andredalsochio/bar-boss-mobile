# 🔗 Deep Linking Guide - Bar Boss Mobile

**Versão:** 1.0  
**Última Atualização:** 17 de Janeiro de 2025  
**Objetivo:** Guia completo para implementação e teste de deep links

---

## 📋 Visão Geral

O Bar Boss Mobile implementa deep linking usando o plugin `app_links` para permitir:
- Verificação de email via links enviados pelo Firebase Auth
- Navegação direta para telas específicas do app
- Integração com Firebase Dynamic Links (futuro)

### Domínios Configurados
- **Produção:** `https://bar-boss-mobile.web.app`
- **Custom Scheme:** `com.barboss.mobile://`

---

## 🏗️ Arquitetura

### AppLinksService
Localização: `lib/app/core/services/app_links_service.dart`

**Responsabilidades:**
- Inicializar o serviço de App Links
- Processar links iniciais (app aberto via deep link)
- Escutar links recebidos enquanto o app está ativo
- Rotear para handlers específicos baseado no tipo de link

### Tipos de Links Suportados

#### 1. Verificação de Email
```
https://bar-boss-mobile.web.app/login?mode=verifyEmail&oobCode=ABC123&continueUrl=...
```
- **Handler:** `_handleEmailVerificationLink()`
- **Ação:** Navega para `/login` com parâmetros de verificação
- **Feedback:** Exibe SnackBar de sucesso

#### 2. Autenticação (Futuro)
```
https://bar-boss-mobile.web.app/auth?token=...
```
- **Handler:** `_handleAuthLink()`
- **Status:** Placeholder para implementação futura

#### 3. Bar Específico (Futuro)
```
https://bar-boss-mobile.web.app/bar/123
```
- **Handler:** `_handleBarLink()`
- **Status:** Placeholder para implementação futura

#### 4. Evento Específico (Futuro)
```
https://bar-boss-mobile.web.app/event/456
```
- **Handler:** `_handleEventLink()`
- **Status:** Placeholder para implementação futura

---

## ⚙️ Configuração

### Android (AndroidManifest.xml)
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Intent filters para App Links -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="bar-boss-mobile.web.app" />
    </intent-filter>
    
    <!-- Custom scheme -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.barboss.mobile" />
    </intent-filter>
</activity>
```

### iOS (Info.plist)
```xml
<!-- Universal Links -->
<key>com.apple.developer.associated-domains</key>
<string>applinks:bar-boss-mobile.web.app</string>

<!-- URL Schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.barboss.mobile</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.barboss.mobile</string>
            <string>https</string>
        </array>
    </dict>
</array>
```

### Firebase Auth ActionCodeSettings
```dart
final actionCodeSettings = ActionCodeSettings(
  url: 'https://bar-boss-mobile.web.app/login',
  handleCodeInApp: true,
  iOSBundleId: 'com.barboss.mobile',
  androidPackageName: 'com.barboss.mobile',
  androidInstallApp: true,
  androidMinimumVersion: '21',
);
```

---

## 🧪 Como Testar

### 1. Verificação de Email

#### No Simulador iOS
```bash
# Simular link de verificação
xcrun simctl openurl booted "https://bar-boss-mobile.web.app/login?mode=verifyEmail&oobCode=test123"
```

#### No Android Emulator
```bash
# Simular link de verificação
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "https://bar-boss-mobile.web.app/login?mode=verifyEmail&oobCode=test123" \
  com.barboss.mobile
```

#### Teste Real
1. Fazer cadastro com email/senha
2. Verificar email recebido
3. Clicar no link de verificação
4. App deve abrir na tela de login com mensagem de sucesso

### 2. Custom Scheme

#### iOS
```bash
xcrun simctl openurl booted "com.barboss.mobile://login"
```

#### Android
```bash
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "com.barboss.mobile://login" \
  com.barboss.mobile
```

---

## 🔍 Debug e Logs

### Logs do AppLinksService
```
🔗 [AppLinksService] Inicializando serviço...
🔗 [AppLinksService] Link inicial encontrado: https://...
🔗 [AppLinksService] Processando link: https://...
📧 [AppLinksService] Link de verificação de email detectado
✅ [AppLinksService] Navegando para /login com parâmetros
✅ [AppLinksService] Serviço inicializado com sucesso!
```

### Tratamento de Erros
- **MissingPluginException:** Plugin não disponível (comum em simuladores)
- **Navegação:** Verifica se contexto está disponível antes de navegar
- **Parâmetros:** Valida presença de parâmetros obrigatórios

---

## 🚨 Problemas Conhecidos

### 1. Simulador iOS
- **Problema:** MissingPluginException em alguns simuladores
- **Solução:** Usar dispositivo físico ou comando `xcrun simctl openurl`
- **Status:** ✅ Tratado com catch específico

### 2. Android Emulator
- **Problema:** Links podem não funcionar em emuladores antigos
- **Solução:** Usar emulador com API 21+ ou dispositivo físico
- **Status:** ✅ Configuração mínima definida

### 3. Firebase Auth
- **Problema:** Links de verificação podem expirar
- **Solução:** Implementar reenvio de email
- **Status:** ✅ Implementado na tela de verificação

---

## 🔄 Próximos Passos

### Funcionalidades Planejadas
1. **Deep links para bares específicos**
   - URL: `/bar/{barId}`
   - Ação: Abrir perfil do bar

2. **Deep links para eventos**
   - URL: `/event/{eventId}`
   - Ação: Abrir detalhes do evento

3. **Compartilhamento de eventos**
   - Gerar links dinâmicos para eventos
   - Integração com Firebase Dynamic Links

4. **Analytics de deep links**
   - Rastrear origem dos acessos
   - Métricas de conversão

---

## 📚 Referências

- [App Links Plugin](https://pub.dev/packages/app_links)
- [Firebase Auth Action Code Settings](https://firebase.google.com/docs/auth/web/email-link-auth)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)

---

**🔁 Mantenha este documento atualizado conforme novas funcionalidades de deep linking forem implementadas.**