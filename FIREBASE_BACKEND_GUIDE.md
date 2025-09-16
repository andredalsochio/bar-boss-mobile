# 🔥 FIREBASE_BACKEND_GUIDE.md - Guia de Backend e Infraestrutura

**Versão:** 2.0  
**Data:** 15 de Setembro de 2025  
**Objetivo:** Documentação técnica da infraestrutura Firebase do Bar Boss Mobile

---

## 📊 1. ARQUITETURA GERAL

### **A. Serviços Firebase Utilizados**

| Serviço | Finalidade |
|---------|------------|
| **Authentication** | Autenticação de usuários (email/senha + social) |
| **Firestore** | Banco de dados principal (NoSQL) |
| **Cloud Functions** | Lógica de servidor e validações transacionais |
| **Storage** | Armazenamento de imagens e arquivos |
| **Remote Config** | Configurações remotas e feature flags |
| **Crashlytics** | Monitoramento de erros e crashes |
| **Analytics** | Métricas de uso e comportamento |

### **B. Diagrama de Integração**

```
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│  Flutter App    │◄────┤  Firebase Auth  │
│  (Cliente)      │     │  (Autenticação) │
│                 │     │                 │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Firestore      │◄────┤  Cloud Functions│◄────┤  Storage        │
│  (Dados)        │     │  (Lógica)       │     │  (Arquivos)     │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 🔐 2. AUTENTICAÇÃO

### **A. Métodos de Autenticação**

- **Email/Senha**: Cadastro tradicional com verificação de email
- **Google**: Login social com OAuth
- **Apple**: Login social com Sign in with Apple
- **Facebook**: Login social com OAuth

### **B. Fluxos de Autenticação**

#### **Cadastro Completo (Email/Senha)**
```javascript
// 1. Criar usuário no Firebase Auth
const userCredential = await firebase.auth().createUserWithEmailAndPassword(email, password);

// 2. Enviar email de verificação IMEDIATAMENTE
await userCredential.user.sendEmailVerification();

// 3. Criar perfil no Firestore
await firebase.firestore().collection('users').doc(uid).set({
  email: email.toLowerCase().trim(),
  displayName: responsibleName,
  completedFullRegistration: true,
  emailVerified: false, // Será true apenas após verificação
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});

// 4. IMPORTANTE: Usuário é direcionado para tela de verificação
// O login será BLOQUEADO até que emailVerified seja true
```

**⚠️ REGRA CRÍTICA:** O usuário NÃO pode fazer login até verificar o email. O método `signInWithEmailAndPassword` deve verificar `emailVerified` e bloquear o acesso se for `false`.

#### **Login Social**
```javascript
// 1. Autenticar com provedor social (Google, Apple, Facebook)
const userCredential = await firebase.auth().signInWithCredential(credential);

// 2. Verificar se usuário já existe
const userDoc = await firebase.firestore()
  .collection('users')
  .doc(userCredential.user.uid)
  .get();

// 3. Criar perfil se não existir
if (!userDoc.exists) {
  await firebase.firestore().collection('users').doc(userCredential.user.uid).set({
    email: userCredential.user.email.toLowerCase().trim(),
    displayName: userCredential.user.displayName,
    completedFullRegistration: false,
    emailVerified: true, // Considerado verificado por ser social
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  });
}
```

### **C. Reset de Senha Seguro**

```javascript
// Cloud Function para reset de senha com verificação de existência
exports.sendPasswordResetEmailSecure = functions.https.onCall(async (data, context) => {
  const { email } = data;
  const normalizedEmail = email.toLowerCase().trim();
  
  try {
    // 1. Verificar se email existe na coleção bars
    const barQuery = await admin.firestore()
      .collection('bars')
      .where('email', '==', normalizedEmail)
      .limit(1)
      .get();
    
    if (!barQuery.empty) {
      // 2. Email existe, pode enviar reset
      await admin.auth().generatePasswordResetLink(normalizedEmail);
    }
    
    // 3. SEMPRE retornar sucesso (segurança contra enumeração)
    return { 
      success: true, 
      message: "Se o email estiver cadastrado, você receberá as instruções." 
    };
  } catch (error) {
    // 4. SEMPRE retornar sucesso mesmo em caso de erro
    return { 
      success: true, 
      message: "Se o email estiver cadastrado, você receberá as instruções." 
    };
  }
});
```

### **D. Segurança e Tokens**

- **Duração do Token**: 1 hora (padrão Firebase)
- **Refresh Token**: 2 semanas
- **Custom Claims**: Utilizados para armazenar roles e permissões
- **Revogação**: Implementada via Admin SDK em caso de comprometimento
- **Reset de Senha**: Verificação de existência do email antes do envio (anti-enumeração)

---

## 📁 3. FIRESTORE

### **A. Estrutura de Coleções**

```
firestore/
├── users/                  # Perfis de usuários
│   └── {uid}/              # Documento do usuário
├── bars/                   # Bares cadastrados
│   ├── {barId}/            # Documento do bar
│   │   ├── members/        # Subcoleção de membros
│   │   │   └── {uid}/      # Documento de membro
│   │   └── events/         # Subcoleção de eventos
│   │       └── {eventId}/  # Documento de evento
├── cnpj_registry/          # Registro de CNPJs (unicidade)
│   └── {cnpj}/             # Documento de CNPJ
└── email_registry/         # Registro de emails (unicidade)
    └── {email}/            # Documento de email
```

### **B. Esquema de Documentos**

#### **users**
```javascript
{
  uid: string,                   // UID do usuário (Firebase Auth)
  email: string,                 // Email normalizado (lowercase, trim)
  displayName: string,           // Nome de exibição
  completedFullRegistration: boolean, // Cadastro completo?
  emailVerified: boolean,        // Email verificado?
  createdAt: timestamp,          // Data de criação
  updatedAt: timestamp           // Data de atualização
}
```

#### **bars**
```javascript
{
  id: string,                    // ID do bar (auto-gerado)
  name: string,                  // Nome do bar
  email: string,                 // Email de contato (normalizado)
  cnpj: string,                  // CNPJ (apenas dígitos)
  responsibleName: string,       // Nome do responsável
  phone: string,                 // Telefone formatado
  address: {
    cep: string,                 // CEP formatado
    street: string,              // Rua
    number: string,              // Número
    complement: string,          // Complemento (opcional)
    city: string,                // Cidade
    state: string                // Estado (UF)
  },
  profile: {
    contactsComplete: boolean,   // Dados de contato completos?
    addressComplete: boolean,    // Endereço completo?
    passwordComplete: boolean    // Senha definida?
  },
  primaryOwnerUid: string,       // UID do proprietário principal
  createdByUid: string,          // UID do criador
  createdAt: timestamp,          // Data de criação
  updatedAt: timestamp           // Data de atualização
}
```

#### **bars/{barId}/members**
```javascript
{
  uid: string,                   // UID do usuário
  email: string,                 // Email do usuário
  displayName: string,           // Nome de exibição
  role: string,                  // Papel: OWNER, ADMIN, MEMBER
  addedByUid: string,            // UID de quem adicionou
  addedAt: timestamp             // Data de adição
}
```

#### **bars/{barId}/events**
```javascript
{
  id: string,                    // ID do evento (auto-gerado)
  barId: string,                 // ID do bar
  title: string,                 // Título do evento
  description: string,           // Descrição (opcional)
  startAt: timestamp,            // Data/hora de início
  endAt: timestamp,              // Data/hora de término (opcional)
  attractions: string[],         // Lista de atrações
  promotions: {
    imageUrl: string,            // URL da imagem
    description: string          // Descrição da promoção
  }[],                           // Até 3 promoções
  published: boolean,            // Evento publicado?
  createdByUid: string,          // UID do criador
  createdAt: timestamp,          // Data de criação
  updatedAt: timestamp           // Data de atualização
}
```

#### **cnpj_registry**
```javascript
{
  cnpj: string,                  // CNPJ (apenas dígitos)
  barId: string,                 // ID do bar associado
  createdAt: timestamp           // Data de criação
}
```

#### **email_registry**
```javascript
{
  email: string,                 // Email normalizado
  barId: string,                 // ID do bar associado
  createdAt: timestamp           // Data de criação
}
```

### **C. Índices**

| Coleção | Campo | Ordem | Finalidade |
|---------|-------|-------|------------|
| **bars** | email | ASC | Verificação de unicidade de email |
| **bars** | cnpj | ASC | Verificação de unicidade de CNPJ |
| **bars** | createdByUid | ASC | Listar bares do usuário |
| **bars/{barId}/events** | startAt | DESC | Listar eventos por data |
| **bars/{barId}/events** | published | ASC | Filtrar eventos publicados |

---

## 🔄 4. CLOUD FUNCTIONS

### **A. Funções Callable**

#### **createBarWithUniqueValidation**
```javascript
// Função para criar bar com validação transacional de unicidade
exports.createBarWithUniqueValidation = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  }
  
  const { email, cnpj, barData } = data;
  
  // Normalizar dados
  const normalizedEmail = email.toLowerCase().trim();
  const cleanCnpj = cnpj.replace(/[^\d]/g, '');
  
  return await admin.firestore().runTransaction(async (transaction) => {
    // 1. Verificar unicidade de CNPJ
    const cnpjRef = admin.firestore().collection('cnpj_registry').doc(cleanCnpj);
    const cnpjDoc = await transaction.get(cnpjRef);
    
    if (cnpjDoc.exists) {
      throw new functions.https.HttpsError('already-exists', 'CNPJ já está em uso');
    }
    
    // 2. Verificar unicidade de email na coleção bars
    const emailQuery = admin.firestore().collection('bars').where('email', '==', normalizedEmail).limit(1);
    const emailDocs = await transaction.get(emailQuery);
    
    if (!emailDocs.empty) {
      throw new functions.https.HttpsError('already-exists', 'Email já está em uso');
    }
    
    // 3. Criar registros atomicamente
    const barRef = admin.firestore().collection('bars').doc();
    
    transaction.set(cnpjRef, {
      barId: barRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    transaction.set(barRef, {
      ...barData,
      cnpj: cleanCnpj,
      email: normalizedEmail,
      createdByUid: context.auth.uid,
      primaryOwnerUid: context.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { barId: barRef.id };
  });
});
```

#### **checkEmailUniqueness**
```javascript
// Função para verificar unicidade de email
exports.checkEmailUniqueness = functions.https.onCall(async (data, context) => {
  const { email } = data;
  
  // Normalizar email
  const normalizedEmail = email.toLowerCase().trim();
  
  // Verificar na coleção bars
  const emailQuery = await admin.firestore()
    .collection('bars')
    .where('email', '==', normalizedEmail)
    .limit(1)
    .get();
  
  return { isUnique: emailQuery.empty };
});
```

#### **checkCnpjUniqueness**
```javascript
// Função para verificar unicidade de CNPJ
exports.checkCnpjUniqueness = functions.https.onCall(async (data, context) => {
  const { cnpj } = data;
  
  // Normalizar CNPJ
  const cleanCnpj = cnpj.replace(/[^\d]/g, '');
  
  // Verificar na coleção cnpj_registry
  const cnpjDoc = await admin.firestore()
    .collection('cnpj_registry')
    .doc(cleanCnpj)
    .get();
  
  return { isUnique: !cnpjDoc.exists };
});
```

### **B. Triggers**

#### **onUserCreated**
```javascript
// Trigger quando um usuário é criado no Firebase Auth
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Criar perfil no Firestore
  await admin.firestore().collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email.toLowerCase().trim(),
    displayName: user.displayName || '',
    completedFullRegistration: false,
    emailVerified: user.emailVerified,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
});
```

#### **onBarDeleted**
```javascript
// Trigger quando um bar é excluído
exports.onBarDeleted = functions.firestore
  .document('bars/{barId}')
  .onDelete(async (snapshot, context) => {
    const barData = snapshot.data();
    const barId = context.params.barId;
    
    // Remover CNPJ do registro
    await admin.firestore()
      .collection('cnpj_registry')
      .doc(barData.cnpj)
      .delete();
    
    // Remover membros e eventos (opcional, depende da regra de negócio)
    // Neste caso, mantemos para histórico
  });
```

---

## 🔒 5. REGRAS DE SEGURANÇA

### **A. Firestore Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helpers
    function isAuth() { return request.auth != null; }
    function isEmailVerified() { return request.auth != null && request.auth.token.email_verified == true; }
    function isSocialUser() { 
      return request.auth != null && 
             (request.auth.token.firebase.sign_in_provider == 'google.com' ||
              request.auth.token.firebase.sign_in_provider == 'facebook.com' ||
              request.auth.token.firebase.sign_in_provider == 'apple.com');
    }
    function isRecentlyCreated() {
      // Permite operações para usuários criados nos últimos 10 minutos
      // auth_time está em segundos, então convertemos para milissegundos
      return request.auth != null && 
             (request.auth.token.auth_time * 1000) > (request.time.toMillis() - 600000); // 10 minutos em ms
    }
    function isEmailVerifiedOrSocial() { return isEmailVerified() || isSocialUser(); }
    function canCreateBar() { 
      // Permite criação para usuários sociais (independente de email verificado),
      // usuários com email verificado ou usuários criados recentemente
      return isSocialUser() || isEmailVerified() || isRecentlyCreated(); 
    }
    function me() { return request.auth.uid; }

    function isMember(barId, uid) {
      return exists(/databases/$(database)/documents/bars/$(barId)/members/$(uid));
    }
    function myRole(barId) {
      return get(/databases/$(database)/documents/bars/$(barId)/members/$(me())).data.role;
    }
    function isOwnerRole(barId) {
      return myRole(barId) == 'OWNER';
    }
    function canManageBar(barId) {
      return ['OWNER','ADMIN'].hasAny([myRole(barId)]);
    }

    // Validação de endereço (complement é opcional)
    function validAddress(address) {
      return address is map
        && address.keys().hasAll(['cep','street','number','state','city'])
        && address.cep is string && address.cep.size() > 0
        && address.street is string && address.street.size() > 0
        && address.number is string && address.number.size() > 0
        && address.state is string && address.state.size() > 0
        && address.city is string && address.city.size() > 0;
    }

    // Validação mínima de bar no create/update
    function validBar(data) {
      return data.keys().hasAll([
        'cnpj','name','responsibleName','email','phone',
        'address','profile','primaryOwnerUid','createdByUid'
      ])
      && data.name is string && data.name.size() > 0
      && data.cnpj is string && data.cnpj.size() > 0
      && data.cnpj.matches('^[0-9]{14}$') // CNPJ limpo
      && data.responsibleName is string && data.responsibleName.size() > 0
      && data.email is string && data.email.size() > 0
      && data.email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')
      && data.phone is string && data.phone.size() > 0
      && validAddress(data.address)
      && (data.profile.contactsComplete is bool)
      && (data.profile.addressComplete is bool)
      && (data.profile.passwordComplete is bool)
      && data.primaryOwnerUid == me()
      && data.createdByUid == me();
    }

    // Validação de evento
    function validEvent(data) {
      return data.keys().hasAll(['title','startAt','published','createdByUid'])
        && data.title is string && data.title.size() > 0
        && data.published is bool
        && data.createdByUid == me()
        && (!('endAt' in data) || data.endAt >= data.startAt);
    }

    // users
    match /users/{uid} {
      allow read, write: if isAuth() && uid == me();
    }

    // bars
    match /bars/{barId} {
      // Somente membros (ou criador) leem, com email verificado, usuário social ou recém-criado
      allow read: if isAuth() && canCreateBar() && (isMember(barId, me()) ||
                                  resource.data.createdByUid == me());

      // Criar bar - permitir se o usuário é o criador e tem e-mail verificado, é usuário social ou foi criado recentemente
      allow create: if isAuth() && canCreateBar() && validBar(request.resource.data);

      // Atualizar bar - somente membros com permissão e e-mail verificado ou usuário social
      allow update: if isAuth() && isEmailVerifiedOrSocial() && isMember(barId, me()) && canManageBar(barId) &&
                    validBar(request.resource.data);

      // Deletar bar - requer e-mail verificado ou usuário social
      allow delete: if isAuth() && isEmailVerifiedOrSocial() && (isOwnerRole(barId) ||
                    resource.data.createdByUid == me());

      // MEMBERS
      match /members/{memberUid} {
        allow read: if isAuth() && canCreateBar() && isMember(barId, me());
        // Permitir criação se é o próprio usuário (criação inicial) ou se é owner - requer e-mail verificado, usuário social ou recém-criado
        allow create: if isAuth() && canCreateBar() && (memberUid == me() || isOwnerRole(barId));
        allow update, delete: if isAuth() && isEmailVerifiedOrSocial() && isOwnerRole(barId);
      }

      // EVENTS
      match /events/{eventId} {
        allow read: if isAuth() && isMember(barId, me());
        allow create: if isAuth() && isEmailVerifiedOrSocial() && isMember(barId, me()) &&
                      validEvent(request.resource.data);
        allow update, delete: if isAuth() && isEmailVerifiedOrSocial() && isMember(barId, me());
      }
    }

    // CNPJ REGISTRY
    match /cnpj_registry/{cnpj} {
      allow read: if true;               // permitir verificação de unicidade sem auth
      allow create: if isAuth() && canCreateBar();         // criado no batch - requer e-mail verificado, usuário social ou recém-criado
      allow update, delete: if false;    // imutável (ou política interna)
    }

    // EMAIL REGISTRY
    match /email_registry/{email} {
      allow read: if true;               // permitir verificação de unicidade sem auth
      allow create: if isAuth() && canCreateBar();         // criado no batch - requer e-mail verificado, usuário social ou recém-criado
      allow update, delete: if false;    // imutável (ou política interna)
    }

    // Collection group query para members
    match /{path=**}/members/{memberUid} {
      allow read: if isAuth() && resource.data.uid == me();
    }
  }
}
```

### **B. Storage Rules**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Regra padrão: negar tudo
    match /{allPaths=**} {
      allow read, write: if false;
    }
    
    // Imagens de perfil de bar
    match /bars/{barId}/profile/{fileName} {
      // Permitir leitura para todos
      allow read: if true;
      
      // Permitir upload apenas para membros do bar
      allow write: if request.auth != null &&
                   exists(/databases/$(database)/documents/bars/$(barId)/members/$(request.auth.uid));
    }
    
    // Imagens de eventos
    match /bars/{barId}/events/{eventId}/{fileName} {
      // Permitir leitura para todos
      allow read: if true;
      
      // Permitir upload apenas para membros do bar
      allow write: if request.auth != null &&
                   exists(/databases/$(database)/documents/bars/$(barId)/members/$(request.auth.uid));
    }
    
    // Validações comuns para imagens
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isValidSize() {
      return request.resource.size <= 5 * 1024 * 1024; // 5MB
    }
  }
}
```

---

## 📈 6. MONITORAMENTO E MÉTRICAS

### **A. Crashlytics**

- **Configuração**: Habilitado para iOS e Android
- **Grupos de Erros**: Agrupados por tipo e stack trace
- **Alertas**: Configurados para erros críticos e spikes
- **Logs**: Integrados com Firebase Analytics para contexto

### **B. Analytics**

#### **Eventos Customizados**
- **bar_created**: Quando um bar é criado
- **event_created**: Quando um evento é criado
- **registration_step_completed**: Quando um passo do cadastro é concluído
- **login_method_used**: Método de login utilizado (email, Google, Apple, Facebook)

#### **User Properties**
- **user_type**: Tipo de usuário (owner, admin, member)
- **registration_complete**: Se o cadastro está completo
- **bar_count**: Número de bares associados
- **event_count**: Número de eventos criados

### **C. Performance Monitoring**

- **Tempo de Carregamento**: Telas principais e fluxos críticos
- **Tempo de Resposta**: Operações de rede e Firebase
- **Uso de Memória**: Monitoramento de picos e vazamentos
- **Tamanho do App**: Monitoramento de crescimento

---

## 🔧 7. LIMITES E QUOTAS

### **A. Firestore**

- **Leituras/Escritas**: 50.000/dia (plano gratuito)
- **Armazenamento**: 1GB (plano gratuito)
- **Tamanho do Documento**: Máximo 1MB
- **Campos por Documento**: Máximo 20.000
- **Índices Compostos**: Máximo 200 por banco de dados
- **Taxa de Escrita**: Máximo 500/segundo por coleção com valores sequenciais

### **B. Storage**

- **Armazenamento**: 5GB (plano gratuito)
- **Transferência**: 1GB/dia (plano gratuito)
- **Tamanho do Arquivo**: Máximo 5MB (definido nas regras)

### **C. Cloud Functions**

- **Invocações**: 2 milhões/mês (plano gratuito)
- **Tempo de Execução**: 400.000 GB-segundos/mês (plano gratuito)
- **Timeout**: 60 segundos (plano gratuito)
- **Memória**: 256MB (plano gratuito)

---

## 🚀 8. ESTRATÉGIAS DE ESCALABILIDADE

### **A. Sharding**

Para coleções com alta taxa de escrita, implementar sharding:

```javascript
// Exemplo: Sharding de eventos por mês
const eventId = generateId();
const month = new Date().getMonth() + 1;
const year = new Date().getFullYear();
const shardId = `${year}_${month}`;

// Criar em subcoleção com shard
await firestore.collection('bars').doc(barId)
  .collection('event_shards').doc(shardId)
  .collection('events').doc(eventId)
  .set(eventData);
```

### **B. Denormalização**

Para reduzir número de leituras, denormalizar dados frequentemente acessados:

```javascript
// Exemplo: Denormalizar dados do bar em eventos
await firestore.collection('bars').doc(barId)
  .collection('events').doc(eventId)
  .set({
    ...eventData,
    barName: barData.name,
    barAddress: {
      city: barData.address.city,
      state: barData.address.state
    }
  });
```

### **C. Paginação**

Para listas grandes, implementar paginação com cursores:

```javascript
// Primeira página
const firstPage = await firestore.collection('bars')
  .doc(barId).collection('events')
  .orderBy('startAt', 'desc')
  .limit(10)
  .get();

// Próxima página
const lastDoc = firstPage.docs[firstPage.docs.length - 1];
const nextPage = await firestore.collection('bars')
  .doc(barId).collection('events')
  .orderBy('startAt', 'desc')
  .startAfter(lastDoc)
  .limit(10)
  .get();
```

---

## 🔍 9. TROUBLESHOOTING

### **A. Problemas Comuns e Soluções**

| Problema | Causa | Solução |
|----------|-------|---------|
| **Permissão negada** | Regras de segurança | Verificar autenticação e regras |
| **Documento não encontrado** | Path incorreto ou documento excluído | Verificar path e existência |
| **Limite de quota excedido** | Uso excessivo | Implementar cache e otimizações |
| **Timeout em função** | Operação longa | Otimizar código ou aumentar timeout |
| **Índice ausente** | Query complexa sem índice | Criar índice composto |

### **B. Logs e Debugging**

```javascript
// Cliente: Logging estruturado
function logError(module, action, error) {
  console.error(`[${module}] Error in ${action}:`, error);
  
  // Enviar para Crashlytics se disponível
  if (firebase.crashlytics) {
    firebase.crashlytics().recordError(error);
    firebase.crashlytics().setCustomKey('module', module);
    firebase.crashlytics().setCustomKey('action', action);
  }
}

// Servidor: Logging em Cloud Functions
function logServerError(context, action, error) {
  console.error(`[${context}] Error in ${action}:`, error);
  
  // Estruturar para fácil busca no console
  console.error(JSON.stringify({
    severity: 'ERROR',
    context: context,
    action: action,
    message: error.message,
    stack: error.stack
  }));
}
```

---

## 🔮 10. EVOLUÇÃO E ROADMAP

### **A. Melhorias Planejadas**

- **Cache Local**: Implementação de Drift para persistência offline
- **Batch Processing**: Otimização de operações em lote
- **Real-time Sync**: Melhorias na sincronização em tempo real
- **Segurança Avançada**: Implementação de verificação em duas etapas
- **Analytics Avançado**: Implementação de funis de conversão e métricas de engajamento

### **B. Migração para Plano Pago**

Quando o app atingir os limites do plano gratuito, migrar para:

- **Blaze Plan**: Pay-as-you-go com controle de gastos
- **Configurar Orçamentos**: Alertas de uso e limites de gastos
- **Otimizar Índices**: Remover índices não utilizados
- **Implementar TTL**: Expiração automática de documentos antigos
- **Compressão de Dados**: Reduzir tamanho de documentos e arquivos

---

**📝 Nota:** Este documento deve ser consultado e atualizado regularmente para refletir o estado atual da infraestrutura Firebase do Bar Boss Mobile.