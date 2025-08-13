# 🔧 Guia de Configuração - Firebase

Este guia te ajudará a configurar Firebase fora do código para integrar com o projeto Bar Boss Mobile.

---

## 🔐 0. Configuração das Variáveis de Ambiente

### 0.1 Configurar dart_defines.json

1. Copie o arquivo de exemplo:
   ```bash
   cp dart_defines.example.json dart_defines.json
   ```

2. Edite o arquivo `dart_defines.json` com suas chaves reais:
   ```json
   {     "ENVIRONMENT": "development",
     "DEBUG_MODE": "true"
   }
   ```

3. **IMPORTANTE**: O arquivo `dart_defines.json` está no `.gitignore` e não deve ser commitado!

### 0.2 Como Funciona

- O VS Code usa o arquivo `launch.json` que referencia `dart_defines.json`
- As variáveis são injetadas em tempo de compilação usando `--dart-define-from-file`
- No código, acessamos via `String.fromEnvironment` para variáveis sensíveis
- Isso garante que chaves sensíveis não fiquem hardcoded no código

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
   - **Email/senha** ✅
   - **Google** ✅
   - **Facebook** ✅
   - **Apple** ✅ (para iOS)

#### Configuração Google Sign-In:
1. Clique em **"Google"** → **"Ativar"**
2. Adicione seu email como administrador
3. Salve as configurações

#### Configuração Facebook:
1. Acesse [Facebook Developers](https://developers.facebook.com/)
2. Crie um novo app
3. Copie o **App ID** e **App Secret**
4. No Firebase, cole essas informações
5. Copie a URL de redirecionamento do Firebase
6. No Facebook Developers, adicione essa URL em **"Valid OAuth Redirect URIs"**

#### Configuração Apple (iOS):
1. Acesse [Apple Developer](https://developer.apple.com/)
2. Configure Sign in with Apple
3. No Firebase, ative Apple e configure com suas credenciais

### 1.3 Configurar Firestore Database

1. No painel Firebase, vá em **"Firestore Database"**
2. Clique em **"Criar banco de dados"**
3. Escolha **"Iniciar no modo de teste"** (por enquanto)
4. Selecione a localização: **"southamerica-east1 (São Paulo)"**
5. Clique em **"Concluído"**

### 1.4 Configurar Regras de Segurança

Na aba **"Regras"** do Firestore, substitua por:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir acesso apenas para usuários autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Regras específicas para coleções
    match /bars/{barId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.ownerId;
    }
    
    match /events/{eventId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 1.5 Registrar Apps (iOS e Android)

#### Para Android:
1. Clique em **"Adicionar app"** → ícone Android
2. Package name: `com.barboss.mobile`
3. App nickname: `Bar Boss Mobile Android`
4. Baixe o arquivo `google-services.json`
5. **IMPORTANTE**: Coloque este arquivo em `bar_boss_mobile/android/app/`

#### Para iOS:
1. Clique em **"Adicionar app"** → ícone iOS
2. Bundle ID: `com.barboss.mobile`
3. App nickname: `Bar Boss Mobile iOS`
4. Baixe o arquivo `GoogleService-Info.plist`
5. **IMPORTANTE**: Coloque este arquivo em `bar_boss_mobile/ios/Runner/`

---

## 📝 4. Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com:

```env
# Firebase
FIREBASE_PROJECT_ID=bar-boss-mobile
FIREBASE_API_KEY=...
FIREBASE_AUTH_DOMAIN=bar-boss-mobile.firebaseapp.com
FIREBASE_STORAGE_BUCKET=bar-boss-mobile.appspot.com
```

**⚠️ IMPORTANTE**: Adicione `.env` ao `.gitignore`!

---

## ✅ 5. Verificação da Configuração

### Checklist Firebase:
- [ ] Projeto criado
- [ ] Authentication configurado com todos os provedores
- [ ] Firestore Database criado
- [ ] Regras de segurança configuradas
- [ ] Apps Android e iOS registrados
- [ ] Arquivos de configuração baixados e posicionados corretamente

### Checklist Integração:
- [ ] Chave de serviço Firebase gerada
- [ ] Variáveis de ambiente definidas
- [ ] Arquivos sensíveis adicionados ao .gitignore

---

## 🚀 Próximos Passos

Após completar este guia:

1. ✅ Configuração externa concluída
2. 🔄 Implementar código de integração no Flutter
3. 🧪 Testar autenticação em desenvolvimento
4. 🚀 Deploy e configuração de produção

---

## 📞 Suporte

- [Documentação Firebase](https://firebase.google.com/docs)

---

**⚠️ Lembrete de Segurança**: Nunca commite chaves secretas, tokens ou arquivos de configuração sensíveis no repositório Git!