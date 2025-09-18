# 🔐 FIRESTORE_RULES.md - Regras de Segurança

**Versão:** 2.0  
**Última Atualização:** 15 de Setembro de 2025  
**Objetivo:** Regras de segurança enxutas e robustas para o Firestore

---

## 🎯 1. PRINCÍPIOS

### Segurança por Padrão
- **Deny by default**: Tudo negado por padrão
- **Least privilege**: Menor privilégio necessário
- **Explicit permissions**: Permissões explícitas e claras
- **Data validation**: Validação rigorosa de dados

### Performance
- **Índices otimizados**: Consultas eficientes
- **Regras simples**: Evitar lógica complexa
- **Cache-friendly**: Regras que favorecem cache

---

## 🛠️ 2. FUNÇÕES DE APOIO

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Função para verificar autenticação
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Função para verificar se é o próprio usuário
    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }
    
    // Função para verificar email verificado
    function isEmailVerified() {
      return isAuthenticated() && request.auth.token.email_verified == true;
    }
    
    // Função para verificar usuários recém-criados (10 min)
    function isRecentlyCreated() {
      return isAuthenticated() && 
             request.auth.token.auth_time * 1000 > request.time.toMillis() - 600000;
    }
    
    // Função para verificar se pode acessar (email verificado OU recém-criado)
    function canAccess() {
      return isEmailVerified() || isRecentlyCreated();
    }
    
    // Função para verificar se email é de login social
    function isSocialLogin() {
      return isAuthenticated() && 
             (request.auth.token.firebase.sign_in_provider == 'google.com' ||
              request.auth.token.firebase.sign_in_provider == 'apple.com' ||
              request.auth.token.firebase.sign_in_provider == 'facebook.com');
    }
    
    // Função combinada para verificar email (verificado OU social)
    function isEmailVerifiedOrSocial() {
      return isEmailVerified() || isSocialLogin();
    }
    
    // Função para verificar se pode criar bar (alinhada com BUSINESS_RULES_AUTH.md)
    function canCreateBar() {
      return isEmailVerifiedOrSocial() || isRecentlyCreated();
    }
    
    // Função para verificar permissões de membro do bar
    function getBarMemberRole(barId, uid) {
      let barData = get(/databases/$(database)/documents/bars/$(barId)).data;
      
      // Proprietário principal tem role OWNER
      if (barData.primaryOwnerUid == uid) {
        return 'OWNER';
      }
      
      // Verifica se é membro explícito
      let memberDoc = get(/databases/$(database)/documents/bars/$(barId)/members/$(uid));
      if (memberDoc != null) {
        return memberDoc.data.role; // ADMIN ou MEMBER
      }
      
      return null;
    }
    
    // Função para verificar se tem permissão no bar
    function hasBarPermission(barId, requiredRole) {
      let userRole = getBarMemberRole(barId, request.auth.uid);
      
      if (userRole == 'OWNER') return true;
      if (requiredRole == 'ADMIN' && userRole == 'ADMIN') return true;
      if (requiredRole == 'MEMBER' && (userRole == 'ADMIN' || userRole == 'MEMBER')) return true;
      
      return false;
    }
    
    // Função para validar dados obrigatórios do usuário
    function isValidUserData(data) {
      return data.keys().hasAll(['email', 'displayName', 'completedFullRegistration', 'emailVerified']) &&
             data.email is string && data.email.size() > 0 &&
             data.displayName is string && data.displayName.size() > 0 &&
             data.completedFullRegistration is bool &&
             data.emailVerified is bool;
    }
    
    // Função para validar dados obrigatórios do bar
    function isValidBarData(data) {
      return data.keys().hasAll(['name', 'email', 'cnpj', 'responsibleName', 'phone', 'address', 'profile', 'primaryOwnerUid', 'createdByUid']) &&
             data.name is string && data.name.size() > 0 &&
             data.email is string && data.email.size() > 0 &&
             data.cnpj is string && data.cnpj.size() == 14 &&
             data.responsibleName is string && data.responsibleName.size() > 0 &&
             data.phone is string && data.phone.size() > 0 &&
             data.address is map &&
             data.profile is map &&
             data.primaryOwnerUid is string &&
             data.createdByUid is string;
    }
    
    // Função para validar endereço
    function isValidAddress(address) {
      return address.keys().hasAll(['cep', 'street', 'number', 'city', 'state']) &&
             address.cep is string && address.cep.size() > 0 &&
             address.street is string && address.street.size() > 0 &&
             address.number is string && address.number.size() > 0 &&
             address.city is string && address.city.size() > 0 &&
             address.state is string && address.state.size() == 2;
    }
    
    // Função para validar perfil do bar
    function isValidProfile(profile) {
      return profile.keys().hasAll(['contactsComplete', 'addressComplete', 'passwordComplete']) &&
             profile.contactsComplete is bool &&
             profile.addressComplete is bool &&
             profile.passwordComplete is bool;
    }
    
    // Função para validar dados de evento
    function isValidEventData(data) {
      return data.keys().hasAll(['title', 'date', 'barId', 'createdByUid']) &&
             data.title is string && data.title.size() > 0 &&
             data.date is timestamp &&
             data.barId is string && data.barId.size() > 0 &&
             data.createdByUid is string && data.createdByUid.size() > 0;
    }
}
```

---

## 📋 3. REGRAS POR COLEÇÃO

### 3.1 Coleção: `users`

```javascript
// Regras para usuários
match /users/{userId} {
  // Leitura: apenas o próprio usuário
  allow read: if isOwner(userId);
  
  // Criação: usuário autenticado criando seu próprio documento
  allow create: if isOwner(userId) && 
                   isValidUserData(resource.data) &&
                   resource.data.createdAt == request.time &&
                   resource.data.updatedAt == request.time;
  
  // Atualização: apenas o próprio usuário
  allow update: if isOwner(userId) && 
                   isValidUserData(resource.data) &&
                   resource.data.updatedAt == request.time &&
                   // Não pode alterar campos críticos
                   resource.data.createdAt == resource.data.createdAt;
  
  // Exclusão: não permitida (soft delete apenas)
  allow delete: if false;
}
```

### 3.2 Coleção: `bars`

```javascript
// Regras para bares
match /bars/{barId} {
  // Leitura: proprietário ou membros do bar
  allow read: if canAccess() && 
                 (resource.data.primaryOwnerUid == request.auth.uid ||
                  resource.data.createdByUid == request.auth.uid ||
                  hasBarPermission(barId, 'MEMBER'));
  
  // Criação: usuário com email verificado ou recém-criado
  allow create: if canCreateBar() && 
                   isValidBarData(resource.data) &&
                   isValidAddress(resource.data.address) &&
                   isValidProfile(resource.data.profile) &&
                   resource.data.primaryOwnerUid == request.auth.uid &&
                   resource.data.createdByUid == request.auth.uid &&
                   resource.data.createdAt == request.time &&
                   resource.data.updatedAt == request.time;
  
  // Atualização: proprietário ou admin
  allow update: if canAccess() && 
                   hasBarPermission(barId, 'ADMIN') &&
                   isValidBarData(resource.data) &&
                   isValidAddress(resource.data.address) &&
                   isValidProfile(resource.data.profile) &&
                   resource.data.updatedAt == request.time &&
                   // Não pode alterar campos críticos
                   resource.data.createdAt == resource.data.createdAt &&
                   resource.data.primaryOwnerUid == resource.data.primaryOwnerUid;
  
  // Exclusão: apenas proprietário (soft delete)
  allow delete: if canAccess() && 
                   resource.data.primaryOwnerUid == request.auth.uid;
}
```

### 3.3 Coleção: `members`

```javascript
// Regras para membros de bares
match /bars/{barId}/members/{memberId} {
  // Leitura: proprietário, admin ou o próprio membro
  allow read: if canAccess() && 
                 (hasBarPermission(barId, 'ADMIN') ||
                  memberId == request.auth.uid);
  
  // Criação: apenas proprietário ou admin
  allow create: if canAccess() && 
                   hasBarPermission(barId, 'ADMIN') &&
                   resource.data.keys().hasAll(['uid', 'role', 'addedAt', 'addedByUid']) &&
                   resource.data.uid is string &&
                   resource.data.role in ['ADMIN', 'MEMBER'] &&
                   resource.data.addedAt == request.time &&
                   resource.data.addedByUid == request.auth.uid;
  
  // Atualização: apenas proprietário ou admin (não pode promover a OWNER)
  allow update: if canAccess() && 
                   hasBarPermission(barId, 'ADMIN') &&
                   resource.data.role in ['ADMIN', 'MEMBER'] &&
                   resource.data.updatedAt == request.time;
  
  // Exclusão: proprietário, admin ou o próprio membro
  allow delete: if canAccess() && 
                   (hasBarPermission(barId, 'ADMIN') ||
                    memberId == request.auth.uid);
}
```

### 3.4 Coleção: `events`

```javascript
// Regras para eventos de bares
match /bars/{barId}/events/{eventId} {
  // Leitura: proprietário, admin ou membro do bar
  allow read: if canAccess() && 
                 hasBarPermission(barId, 'MEMBER');
  
  // Criação: proprietário, admin ou membro do bar
  allow create: if canAccess() && 
                   hasBarPermission(barId, 'MEMBER') &&
                   isValidEventData(resource.data) &&
                   resource.data.barId == barId &&
                   resource.data.createdByUid == request.auth.uid &&
                   resource.data.createdAt == request.time &&
                   resource.data.updatedAt == request.time;
  
  // Atualização: proprietário, admin ou criador do evento
  allow update: if canAccess() && 
                   (hasBarPermission(barId, 'ADMIN') ||
                    resource.data.createdByUid == request.auth.uid) &&
                   isValidEventData(resource.data) &&
                   resource.data.barId == barId &&
                   resource.data.updatedAt == request.time &&
                   // Não pode alterar campos críticos
                   resource.data.createdAt == resource.data.createdAt &&
                   resource.data.createdByUid == resource.data.createdByUid;
  
  // Exclusão: proprietário, admin ou criador do evento
  allow delete: if canAccess() && 
                   (hasBarPermission(barId, 'ADMIN') ||
                    resource.data.createdByUid == request.auth.uid);
}
```

### 3.5 Coleção: `cnpj_registry`

```javascript
// Regras para registro de CNPJs (controle de unicidade)
match /cnpj_registry/{cnpj} {
  // Leitura: qualquer usuário autenticado (para verificar unicidade)
  allow read: if isAuthenticated();
  
  // Criação: apenas durante criação de bar (alinhado com validação híbrida)
  allow create: if canCreateBar() && 
                   resource.data.keys().hasAll(['barId', 'createdAt']) &&
                   resource.data.barId is string &&
                   resource.data.createdAt == request.time;
  
  // Atualização: não permitida
  allow update: if false;
  
  // Exclusão: apenas quando bar é excluído
  allow delete: if canAccess() && 
                   exists(/databases/$(database)/documents/bars/$(resource.data.barId)) == false;
}
```

---

## 🧪 4. TESTES DE SEGURANÇA

### 4.1 Cenários de Teste

```javascript
// Teste 1: Usuário não autenticado
// Deve falhar em todas as operações

// Teste 2: Usuário recém-criado (< 10 min)
// Deve conseguir criar bar mesmo sem email verificado

// Teste 3: Usuário com email não verificado (> 10 min)
// Deve falhar ao tentar criar bar

// Teste 4: Login social
// Deve conseguir criar bar imediatamente

// Teste 5: Tentativa de acesso a dados de outro usuário
// Deve falhar em todas as operações

// Teste 6: Validação de dados inválidos
// Deve falhar na criação/atualização

// Teste 7: Permissões de eventos
// OWNER/ADMIN: criar, ler, editar, deletar qualquer evento
// MEMBER: criar, ler, editar/deletar apenas próprios eventos
// Não-membro: nenhum acesso

// Teste 8: Validação CNPJ
// Deve permitir leitura para verificar unicidade
// Deve permitir criação apenas com bar válido
```

### 4.2 Comandos de Teste

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Executar testes de regras
firebase emulators:start --only firestore
firebase firestore:rules:test --project=your-project-id

# Teste específico de regras
firebase emulators:exec --only firestore "npm test"
```

---

## 🚀 5. DEPLOYMENT

### 5.1 Processo de Deploy

```bash
# 1. Validar regras localmente
firebase firestore:rules:validate

# 2. Deploy para staging
firebase deploy --only firestore:rules --project staging

# 3. Executar testes de integração
npm run test:integration

# 4. Deploy para produção
firebase deploy --only firestore:rules --project production
```

### 5.2 Rollback

```bash
# Em caso de problemas, fazer rollback
firebase firestore:rules:release --project production --release-id PREVIOUS_RELEASE_ID
```

---

## 📊 6. MONITORAMENTO

### 6.1 Métricas Importantes

- **Denied requests**: Requisições negadas por regras
- **Rule evaluation time**: Tempo de avaliação das regras
- **Error rate**: Taxa de erro nas operações
- **Permission errors**: Erros específicos de permissão

### 6.2 Alertas

```javascript
// Configurar alertas no Firebase Console
// - Pico de requisições negadas
// - Tempo de resposta elevado
// - Erros de permissão frequentes
```

---

## 🔄 7. MANUTENÇÃO

### 7.1 Revisão Periódica

- **Mensal**: Revisar logs de segurança
- **Trimestral**: Atualizar regras conforme novos recursos
- **Anual**: Auditoria completa de segurança

### 7.2 Versionamento

```javascript
// Sempre incrementar version nas regras
rules_version = '2';

// Documentar mudanças no changelog
// v1.0 - Regras iniciais
// v2.0 - Adicionadas regras para eventos e sistema de membros
//      - Alinhada validação CNPJ com estratégia híbrida
//      - Implementadas permissões OWNER/ADMIN/MEMBER
```

---

## 👤 2. REGRAS: users/{uid}

### Leitura
```javascript
// Usuário pode ler apenas seus próprios dados
match /users/{uid} {
  allow read: if isAuthenticated() && isOwner(uid);
}
```

### Escrita
```javascript
// Usuário pode criar/atualizar apenas seus próprios dados
match /users/{uid} {
  allow create: if isAuthenticated() 
    && isOwner(uid)
    && isValidUserData(request.resource.data);
    
  allow update: if isAuthenticated() 
    && isOwner(uid)
    && isValidUserUpdate(request.resource.data, resource.data);
}

// Validação de dados do usuário
function isValidUserData(data) {
  return data.keys().hasAll(['uid', 'email', 'displayName', 'emailVerified', 'completedFullRegistration', 'createdAt', 'updatedAt'])
    && data.uid == request.auth.uid
    && data.email == request.auth.token.email.lower()
    && data.displayName is string
    && data.emailVerified is bool
    && data.completedFullRegistration is bool
    && data.createdAt == request.time
    && data.updatedAt == request.time;
}

// Validação de atualização do usuário
function isValidUserUpdate(newData, oldData) {
  return newData.keys().hasAll(['uid', 'email', 'displayName', 'emailVerified', 'completedFullRegistration', 'createdAt', 'updatedAt'])
    && newData.uid == oldData.uid
    && newData.email == oldData.email
    && newData.createdAt == oldData.createdAt
    && newData.updatedAt == request.time
    && (newData.completedFullRegistration == true || newData.completedFullRegistration == oldData.completedFullRegistration);
}
```

---

## 🏪 3. REGRAS: bars/{barId}

### Leitura
```javascript
// Membros do bar podem ler dados do bar
match /bars/{barId} {
  allow read: if isAuthenticated() 
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
}
```

### Criação
```javascript
// Usuário pode criar bar se email verificado OU recém-criado
match /bars/{barId} {
  allow create: if isAuthenticated()
    && canCreateBar()
    && isValidBarData(request.resource.data)
    && request.resource.data.createdByUid == request.auth.uid
    && request.resource.data.primaryOwnerUid == request.auth.uid;
}

// Validação de dados do bar
function isValidBarData(data) {
  return data.keys().hasAll(['name', 'email', 'cnpj', 'responsibleName', 'phone', 'address', 'profile', 'primaryOwnerUid', 'createdByUid', 'createdAt', 'updatedAt'])
    && data.name is string && data.name.size() > 0
    && data.email is string && data.email.matches('.*@.*\\..*')
    && data.cnpj is string && data.cnpj.size() == 14
    && data.responsibleName is string && data.responsibleName.size() > 0
    && data.phone is string && data.phone.size() > 0
    && isValidAddress(data.address)
    && isValidProfile(data.profile)
    && data.createdAt == request.time
    && data.updatedAt == request.time;
}

// Validação de endereço
function isValidAddress(address) {
  return address.keys().hasAll(['cep', 'street', 'number', 'city', 'state'])
    && address.cep is string && address.cep.size() > 0
    && address.street is string && address.street.size() > 0
    && address.number is string && address.number.size() > 0
    && address.city is string && address.city.size() > 0
    && address.state is string && address.state.size() == 2;
}

// Validação de perfil de completude
function isValidProfile(profile) {
  return profile.keys().hasAll(['contactsComplete', 'addressComplete', 'passwordComplete'])
    && profile.contactsComplete is bool
    && profile.addressComplete is bool
    && profile.passwordComplete is bool;
}
```

### Atualização
```javascript
// Apenas OWNER e ADMIN podem atualizar dados do bar
match /bars/{barId} {
  allow update: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN'])
    && isValidBarUpdate(request.resource.data, resource.data);
}

// Validação de atualização do bar
function isValidBarUpdate(newData, oldData) {
  return newData.keys().hasAll(['name', 'email', 'cnpj', 'responsibleName', 'phone', 'address', 'profile', 'primaryOwnerUid', 'createdByUid', 'createdAt', 'updatedAt'])
    && newData.primaryOwnerUid == oldData.primaryOwnerUid
    && newData.createdByUid == oldData.createdByUid
    && newData.createdAt == oldData.createdAt
    && newData.updatedAt == request.time
    && (newData.cnpj == oldData.cnpj || isCnpjAvailable(newData.cnpj));
}
```

### Exclusão
```javascript
// Apenas OWNER pode excluir bar
match /bars/{barId} {
  allow delete: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER']);
}
```

---

## 👥 4. REGRAS: bars/{barId}/members/{uid}

### Leitura
```javascript
// Membros podem ler lista de membros do bar
match /bars/{barId}/members/{uid} {
  allow read: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
}
```

### Criação
```javascript
// OWNER e ADMIN podem adicionar membros
match /bars/{barId}/members/{uid} {
  allow create: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN'])
    && isValidMemberData(request.resource.data)
    && request.resource.data.addedByUid == request.auth.uid;
}

// Validação de dados do membro
function isValidMemberData(data) {
  return data.keys().hasAll(['uid', 'email', 'displayName', 'role', 'addedByUid', 'addedAt'])
    && data.uid is string && data.uid.size() > 0
    && data.email is string && data.email.matches('.*@.*\\..*')
    && data.displayName is string && data.displayName.size() > 0
    && data.role in ['OWNER', 'ADMIN', 'MEMBER']
    && data.addedAt == request.time;
}
```

### Atualização
```javascript
// OWNER pode atualizar qualquer membro, ADMIN pode atualizar MEMBER
match /bars/{barId}/members/{uid} {
  allow update: if isAuthenticated()
    && (
      (hasBarPermission(barId, ['OWNER']))
      || (hasBarPermission(barId, ['ADMIN']) && resource.data.role == 'MEMBER')
    )
    && isValidMemberUpdate(request.resource.data, resource.data);
}

// Validação de atualização do membro
function isValidMemberUpdate(newData, oldData) {
  return newData.keys().hasAll(['uid', 'email', 'displayName', 'role', 'addedByUid', 'addedAt'])
    && newData.uid == oldData.uid
    && newData.addedByUid == oldData.addedByUid
    && newData.addedAt == oldData.addedAt
    && newData.role in ['OWNER', 'ADMIN', 'MEMBER']
    && (oldData.role != 'OWNER' || newData.role == 'OWNER'); // OWNER não pode perder role
}
```

### Exclusão
```javascript
// OWNER pode remover qualquer membro (exceto a si mesmo), ADMIN pode remover MEMBER
match /bars/{barId}/members/{uid} {
  allow delete: if isAuthenticated()
    && uid != request.auth.uid // Não pode remover a si mesmo
    && (
      (hasBarPermission(barId, ['OWNER']) && resource.data.role != 'OWNER')
      || (hasBarPermission(barId, ['ADMIN']) && resource.data.role == 'MEMBER')
    );
}
```

---

## 🎉 5. REGRAS: bars/{barId}/events/{eventId}

### Leitura
```javascript
// Membros podem ler eventos do bar
match /bars/{barId}/events/{eventId} {
  allow read: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
}

// Listar eventos (necessário para queries)
match /bars/{barId}/events/{eventId} {
  allow list: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
}
```

### Criação
```javascript
// Qualquer membro pode criar eventos
match /bars/{barId}/events/{eventId} {
  allow create: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
    && isValidEventData(request.resource.data)
    && request.resource.data.createdByUid == request.auth.uid;
}

// Validação de dados do evento
function isValidEventData(data) {
  return data.keys().hasAll(['title', 'startAt', 'attractions', 'promotions', 'published', 'createdByUid', 'createdAt', 'updatedAt'])
    && data.title is string && data.title.size() > 0 && data.title.size() <= 100
    && data.startAt is timestamp && data.startAt > request.time
    && data.attractions is list && data.attractions.size() <= 10
    && data.promotions is list && data.promotions.size() <= 3
    && data.published is bool
    && data.createdAt == request.time
    && data.updatedAt == request.time
    && (data.endAt == null || (data.endAt is timestamp && data.endAt > data.startAt));
}
```

### Atualização
```javascript
// Criador pode atualizar próprio evento, OWNER/ADMIN podem atualizar qualquer evento
match /bars/{barId}/events/{eventId} {
  allow update: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
    && (
      resource.data.createdByUid == request.auth.uid
      || hasBarPermission(barId, ['OWNER', 'ADMIN'])
    )
    && isValidEventUpdate(request.resource.data, resource.data);
}

// Validação de atualização do evento
function isValidEventUpdate(newData, oldData) {
  return newData.keys().hasAll(['title', 'startAt', 'attractions', 'promotions', 'published', 'createdByUid', 'createdAt', 'updatedAt'])
    && newData.createdByUid == oldData.createdByUid
    && newData.createdAt == oldData.createdAt
    && newData.updatedAt == request.time
    && isValidEventData(newData);
}
```

### Exclusão
```javascript
// Criador pode excluir próprio evento, OWNER/ADMIN podem excluir qualquer evento
match /bars/{barId}/events/{eventId} {
  allow delete: if isAuthenticated()
    && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
    && (
      resource.data.createdByUid == request.auth.uid
      || hasBarPermission(barId, ['OWNER', 'ADMIN'])
    );
}
```

---

## 🔒 6. REGRAS: cnpj_registry/{cnpj}

### Leitura
```javascript
// Qualquer usuário autenticado pode verificar disponibilidade de CNPJ
match /cnpj_registry/{cnpj} {
  allow read: if isAuthenticated();
}
```

### Criação
```javascript
// Apenas durante criação de bar
match /cnpj_registry/{cnpj} {
  allow create: if isAuthenticated()
    && canCreateBar()
    && isValidCnpjRegistry(request.resource.data);
}

// Validação de registro de CNPJ
function isValidCnpjRegistry(data) {
  return data.keys().hasAll(['cnpj', 'barId', 'createdAt'])
    && data.cnpj is string && data.cnpj.size() == 14
    && data.barId is string && data.barId.size() > 0
    && data.createdAt == request.time;
}
```

### Exclusão
```javascript
// Apenas quando bar é excluído (via Cloud Function)
match /cnpj_registry/{cnpj} {
  allow delete: if false; // Apenas via Cloud Function
}
```

---

## 🛡️ 7. REGRAS COMPLETAS (ARQUIVO FINAL)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== FUNÇÕES DE APOIO =====
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isEmailVerifiedOrSocial() {
      return request.auth.token.email_verified == true;
    }
    
    function isRecentlyCreated() {
      return request.auth.token.auth_time * 1000 > request.time.toMillis() - 600000;
    }
    
    function canCreateBar() {
      return isEmailVerifiedOrSocial() || isRecentlyCreated();
    }
    
    function isOwner(uid) {
      return request.auth.uid == uid;
    }
    
    function hasBarPermission(barId, requiredRoles) {
      let memberDoc = get(/databases/$(database)/documents/bars/$(barId)/members/$(request.auth.uid));
      return memberDoc != null && memberDoc.data.role in requiredRoles;
    }
    
    function isValidUserData(data) {
      return data.keys().hasAll(['uid', 'email', 'displayName', 'emailVerified', 'completedFullRegistration', 'createdAt', 'updatedAt'])
        && data.uid == request.auth.uid
        && data.email == request.auth.token.email.lower()
        && data.displayName is string
        && data.emailVerified is bool
        && data.completedFullRegistration is bool
        && data.createdAt == request.time
        && data.updatedAt == request.time;
    }
    
    function isValidBarData(data) {
      return data.keys().hasAll(['name', 'email', 'cnpj', 'responsibleName', 'phone', 'address', 'profile', 'primaryOwnerUid', 'createdByUid', 'createdAt', 'updatedAt'])
        && data.name is string && data.name.size() > 0
        && data.email is string && data.email.matches('.*@.*\\..*')
        && data.cnpj is string && data.cnpj.size() == 14
        && data.responsibleName is string && data.responsibleName.size() > 0
        && data.phone is string && data.phone.size() > 0
        && isValidAddress(data.address)
        && isValidProfile(data.profile)
        && data.createdAt == request.time
        && data.updatedAt == request.time;
    }
    
    function isValidAddress(address) {
      return address.keys().hasAll(['cep', 'street', 'number', 'city', 'state'])
        && address.cep is string && address.cep.size() > 0
        && address.street is string && address.street.size() > 0
        && address.number is string && address.number.size() > 0
        && address.city is string && address.city.size() > 0
        && address.state is string && address.state.size() == 2;
    }
    
    function isValidProfile(profile) {
      return profile.keys().hasAll(['contactsComplete', 'addressComplete', 'passwordComplete'])
        && profile.contactsComplete is bool
        && profile.addressComplete is bool
        && profile.passwordComplete is bool;
    }
    
    function isValidEventData(data) {
      return data.keys().hasAll(['title', 'startAt', 'attractions', 'promotions', 'published', 'createdByUid', 'createdAt', 'updatedAt'])
        && data.title is string && data.title.size() > 0 && data.title.size() <= 100
        && data.startAt is timestamp && data.startAt > request.time
        && data.attractions is list && data.attractions.size() <= 10
        && data.promotions is list && data.promotions.size() <= 3
        && data.published is bool
        && data.createdAt == request.time
        && data.updatedAt == request.time;
    }
    
    // ===== REGRAS DE COLEÇÕES =====
    
    // USERS
    match /users/{uid} {
      allow read: if isAuthenticated() && isOwner(uid);
      allow create: if isAuthenticated() && isOwner(uid) && isValidUserData(request.resource.data);
      allow update: if isAuthenticated() && isOwner(uid);
    }
    
    // BARS
    match /bars/{barId} {
      allow read: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
      allow create: if isAuthenticated() && canCreateBar() && isValidBarData(request.resource.data) 
        && request.resource.data.createdByUid == request.auth.uid;
      allow update: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN']);
      allow delete: if isAuthenticated() && hasBarPermission(barId, ['OWNER']);
      
      // MEMBERS
      match /members/{uid} {
        allow read: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
        allow create: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN']);
        allow update: if isAuthenticated() && (
          hasBarPermission(barId, ['OWNER']) || 
          (hasBarPermission(barId, ['ADMIN']) && resource.data.role == 'MEMBER')
        );
        allow delete: if isAuthenticated() && uid != request.auth.uid && (
          (hasBarPermission(barId, ['OWNER']) && resource.data.role != 'OWNER') ||
          (hasBarPermission(barId, ['ADMIN']) && resource.data.role == 'MEMBER')
        );
      }
      
      // EVENTS
      match /events/{eventId} {
        allow read, list: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER']);
        allow create: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
          && isValidEventData(request.resource.data) && request.resource.data.createdByUid == request.auth.uid;
        allow update: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
          && (resource.data.createdByUid == request.auth.uid || hasBarPermission(barId, ['OWNER', 'ADMIN']));
        allow delete: if isAuthenticated() && hasBarPermission(barId, ['OWNER', 'ADMIN', 'MEMBER'])
          && (resource.data.createdByUid == request.auth.uid || hasBarPermission(barId, ['OWNER', 'ADMIN']));
      }
    }
    
    // CNPJ REGISTRY
    match /cnpj_registry/{cnpj} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && canCreateBar();
      allow delete: if false; // Apenas via Cloud Function
    }
  }
}
```

---

## 🧪 8. TESTES DE SEGURANÇA

### Cenários de Teste

#### Teste 1: Usuário não autenticado
```javascript
// Deve falhar
firestore.collection('users').doc('any-uid').get()
firestore.collection('bars').doc('any-bar').get()
```

#### Teste 2: Email não verificado (recém-criado)
```javascript
// Deve passar (janela de tolerância)
firestore.collection('bars').add({...validBarData})

// Deve falhar após 10 minutos
setTimeout(() => {
  firestore.collection('bars').add({...validBarData}) // Falha
}, 11 * 60 * 1000)
```

#### Teste 3: Permissões de membro
```javascript
// MEMBER pode ler mas não pode gerenciar outros membros
firestore.collection('bars').doc(barId).collection('members').get() // Passa
firestore.collection('bars').doc(barId).collection('members').add({...}) // Falha
```

#### Teste 4: Criação de evento
```javascript
// Qualquer membro pode criar evento
firestore.collection('bars').doc(barId).collection('events').add({
  title: 'Show de Rock',
  startAt: futureTimestamp,
  attractions: ['Banda XYZ'],
  promotions: [],
  published: false,
  createdByUid: currentUserUid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp()
}) // Passa para qualquer membro
```

### Ferramentas de Teste
```bash
# Instalar emulador do Firestore
npm install -g firebase-tools

# Executar testes
firebase emulators:start --only firestore
firebase emulators:exec --only firestore "npm test"
```

---

## 🔧 9. DEPLOYMENT E MONITORAMENTO

### Deploy das Regras
```bash
# Validar regras localmente
firebase firestore:rules:validate

# Deploy para produção
firebase deploy --only firestore:rules

# Verificar status
firebase firestore:rules:list
```

### Monitoramento
```javascript
// Cloud Function para monitorar violações de segurança
exports.monitorSecurityViolations = functions.firestore
  .document('{collection}/{document}')
  .onWrite((change, context) => {
    // Log de tentativas de acesso negado
    if (context.auth == null) {
      console.warn('Tentativa de acesso não autenticado:', context);
    }
  });
```

### Alertas
```yaml
# alerting.yaml
alertPolicy:
  displayName: "Firestore Security Violations"
  conditions:
    - displayName: "High number of permission denied errors"
      conditionThreshold:
        filter: 'resource.type="firestore_database" AND severity="ERROR"'
        comparison: COMPARISON_GREATER_THAN
        thresholdValue: 10
        duration: "300s"
```

---

## 📚 10. DOCUMENTAÇÃO RELACIONADA

Para implementação completa, consulte:

- **[BUSINESS_RULES_AUTH.md](./BUSINESS_RULES_AUTH.md)**: Regras de autenticação
- **[FIRESTORE_SCHEMA.md](./FIRESTORE_SCHEMA.md)**: Estrutura de dados
- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro

---

**🔒 Estas regras são críticas para a segurança do aplicativo. Teste thoroughly antes de fazer deploy em produção.**