# 🔧 Guia de Configuração - Firebase

Este guia te ajudará a configurar Firebase **fora do código** para integrar com o projeto Bar Boss Mobile.

---

## 📱 1. Configuração do Firebase

### 1.1 Criar Projeto Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em **"Criar um projeto"**
3. Nome do projeto: `bar-boss-mobile`
4. Ative o Google Analytics (recomendado)
5. Selecione uma conta do Analytics ou crie uma nova
6. Clique em **"Criar projeto"**

### 1.2 Configurar Authentication

1. No painel do Firebase, vá em **"Authentication"**
2. Clique em **"Começar"**
3. Na aba **"Sign-in method"**, ative os provedores:
   - **Email/Password**: Ative e configure
   - **Google**: Ative e configure
   - **Facebook**: Ative e configure (opcional)
   - **Apple**: Ative e configure (para iOS)

### 1.3 Configurar Firestore Database

1. No painel do Firebase, vá em **"Firestore Database"**
2. Clique em **"Criar banco de dados"**
3. Escolha **"Iniciar no modo de teste"** (por enquanto)
4. Selecione uma localização (ex: `southamerica-east1`)
5. Clique em **"Concluído"**

### 1.4 Configurar Apps (iOS e Android)

#### Android:
1. No painel do Firebase, clique em **"Adicionar app"** → **Android**
2. Package name: `com.barboss.mobile`
3. App nickname: `Bar Boss Mobile (Android)`
4. SHA-1: Deixe em branco por enquanto
5. Baixe o arquivo `google-services.json`
6. Coloque o arquivo em: `android/app/google-services.json`

#### iOS:
1. No painel do Firebase, clique em **"Adicionar app"** → **iOS**
2. Bundle ID: `com.barboss.mobile`
3. App nickname: `Bar Boss Mobile (iOS)`
4. Baixe o arquivo `GoogleService-Info.plist`
5. Coloque o arquivo em: `ios/Runner/GoogleService-Info.plist`

---

## 🔐 2. Configuração da Autenticação Social

### 2.1 Google Sign-In

1. No Firebase Console, vá em **"Authentication"** → **"Sign-in method"**
2. Clique em **"Google"**
3. Ative o provedor
4. Configure o email de suporte do projeto
5. Baixe o arquivo de configuração atualizado

#### Para Android:
- O `google-services.json` já contém as configurações necessárias

#### Para iOS:
- Abra o projeto no Xcode
- Adicione o `GoogleService-Info.plist` ao projeto
- Configure o URL Scheme no `Info.plist`

### 2.2 Apple Sign-In (iOS)

1. No Firebase Console, ative o provedor **Apple**
2. No Apple Developer Console:
   - Configure o App ID com Sign In with Apple capability
   - Crie um Service ID
   - Configure as URLs de redirecionamento

### 2.3 Facebook Login (Opcional)

1. Crie um app no [Facebook Developers](https://developers.facebook.com/)
2. Configure o Facebook Login
3. No Firebase Console, ative o provedor **Facebook**
4. Adicione o App ID e App Secret do Facebook

---

## 🔗 3. Configuração do FlutterFire CLI

### 3.1 Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3.2 Configurar o Projeto

```bash
flutterfire configure
```

1. Selecione o projeto Firebase criado
2. Selecione as plataformas (iOS e Android)
3. Confirme os Bundle IDs/Package names
4. O CLI irá gerar o arquivo `firebase_options.dart`

---

## 📋 4. Checklist Final

### Firebase:
- [ ] Projeto Firebase criado
- [ ] Authentication configurado (Email, Google, Apple, Facebook)
- [ ] Firestore Database criado
- [ ] Apps Android e iOS adicionados
- [ ] Arquivos de configuração baixados e posicionados
- [ ] FlutterFire CLI configurado

### Arquivos necessários:
- [ ] `android/app/google-services.json`
- [ ] `ios/Runner/GoogleService-Info.plist`
- [ ] `lib/firebase_options.dart` (gerado pelo FlutterFire CLI)

---

## 🚀 5. Testando a Configuração

1. Execute o projeto:
   ```bash
   flutter run
   ```

2. Teste os fluxos de autenticação:
   - Login com email/senha
   - Login com Google
   - Login com Apple (iOS)
   - Login com Facebook (se configurado)

3. Verifique no Firebase Console se os usuários estão sendo criados

---

## 📚 6. Recursos Úteis

- [Documentação Firebase](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Auth Flutter](https://firebase.flutter.dev/docs/auth/overview/)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Apple Sign-In Flutter](https://pub.dev/packages/sign_in_with_apple)
- [Facebook Auth Flutter](https://pub.dev/packages/flutter_facebook_auth)

---

## ⚠️ Notas Importantes

1. **Segurança**: Nunca commite arquivos de configuração com chaves sensíveis
2. **Produção**: Configure regras de segurança adequadas no Firestore antes do deploy
3. **iOS**: Apple Sign-In é obrigatório se você oferece outros métodos de login social
4. **Android**: Configure o SHA-1 fingerprint para produção
5. **Testes**: Use o modo de teste do Firestore apenas durante desenvolvimento

---

✅ **Configuração concluída!** Agora você pode desenvolver e testar o app com autenticação Firebase completa.