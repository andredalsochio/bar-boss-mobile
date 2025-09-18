# 🔐 FIRESTORE_RULES.md - Regras de Segurança

**Versão:** 3.0  
**Última Atualização:** 17 de Setembro de 2025  
**Objetivo:** Regras de segurança enxutas e robustas para o Firestore

> **⚠️ IMPORTANTE:** Este documento foi atualizado para refletir as regras simplificadas atualmente em produção. Para o fluxo completo de autenticação, consulte [FIRESTORE_AUTH_FLOW.md](./FIRESTORE_AUTH_FLOW.md).

---

## 📋 1. VISÃO GERAL

As regras atuais do Firestore foram simplificadas para facilitar o desenvolvimento e testes. Elas garantem:

- **Autenticação obrigatória** para a maioria das operações
- **Controle de propriedade** para dados sensíveis
- **Leitura pública** apenas para verificação de CNPJ durante cadastro
- **Segurança básica** sem complexidade desnecessária

---

## 📋 2. FUNÇÕES AUXILIARES

```javascript
// Verifica se o usuário está autenticado
function isAuthed() {
  return request.auth != null;
}

// Verifica se o usuário é o proprietário do documento
function isSelf(userId) {
  return request.auth.uid == userId;
}
```

---

## 📋 3. REGRAS IMPLEMENTADAS (SIMPLIFICADAS)

> **Nota:** As regras atuais foram simplificadas para facilitar desenvolvimento e testes. Regras mais granulares serão implementadas conforme necessário.

### 3.1 Coleção: `users`

```javascript
match /users/{userId} {
  // Leitura e escrita: apenas o próprio usuário
  allow read, write: if isAuthed() && isSelf(userId);
}
```

### 3.2 Coleção: `bars`

```javascript
match /bars/{barId} {
  // Leitura e escrita: apenas o proprietário do bar
  allow read, write: if isAuthed() && 
                        resource.data.ownerUid == request.auth.uid;
}
```

### 3.3 Subcoleção: `bars/{barId}/members`

```javascript
match /bars/{barId}/members/{memberId} {
  // Leitura e escrita: apenas o proprietário do bar
  allow read, write: if isAuthed() && 
                        get(/databases/$(database)/documents/bars/$(barId)).data.ownerUid == request.auth.uid;
}
```

### 3.4 Subcoleção: `bars/{barId}/events`

```javascript
match /bars/{barId}/events/{eventId} {
  // Leitura e escrita: apenas o proprietário do bar
  allow read, write: if isAuthed() && 
                        get(/databases/$(database)/documents/bars/$(barId)).data.ownerUid == request.auth.uid;
}
```

### 3.5 Coleção: `cnpj_registry`

```javascript
match /cnpj_registry/{cnpj} {
  // Leitura: qualquer usuário (para verificar unicidade durante cadastro)
  allow read: if true;
  
  // Escrita: apenas usuários autenticados
  allow write: if isAuthed();
}
```

### 3.6 Queries de Grupo de Coleções

```javascript
// Permite queries em grupo de coleções para eventos
match /{path=**}/events/{eventId} {
  allow read: if isAuthed();
}

// Permite queries em grupo de coleções para membros  
match /{path=**}/members/{memberId} {
  allow read: if isAuthed();
}
```

### 3.7 Regra Padrão

```javascript
// Bloqueia acesso a qualquer documento não especificado
match /{document=**} {
  allow read, write: if false;
}
```

---

## 🔧 4. DEPLOY E MONITORAMENTO

### 4.1 Deploy das Regras

```bash
# Deploy das regras para o projeto
firebase deploy --only firestore:rules

# Verificar regras ativas
firebase firestore:rules:get
```

### 4.2 Monitoramento

- **Console Firebase**: Monitore tentativas de acesso negadas
- **Cloud Logging**: Configure alertas para violações de segurança
- **Firestore Usage**: Monitore padrões de leitura/escrita

---

## 📚 5. DOCUMENTAÇÃO RELACIONADA

Para implementação completa, consulte:

- **[FIRESTORE_AUTH_FLOW.md](./FIRESTORE_AUTH_FLOW.md)**: Fluxo consolidado de autenticação
- **[BUSINESS_RULES_AUTH.md](./BUSINESS_RULES_AUTH.md)**: Regras de autenticação
- **[FIRESTORE_SCHEMA.md](./FIRESTORE_SCHEMA.md)**: Estrutura de dados
- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro

---

**🔒 Estas regras são críticas para a segurança do aplicativo. Teste thoroughly antes de fazer deploy em produção.**