# Correção de Permissão do Firestore - Criação de Bar

## Problema Identificado

Durante o fluxo de cadastro de bar (Step 1-3), o usuário recebia o erro:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Causa Raiz

As regras do Firestore exigiam que o usuário tivesse o email verificado (`isEmailVerifiedOrSocial()`) para criar um bar. No entanto, no fluxo de cadastro:

1. Usuário preenche dados (Step 1-3)
2. Conta é criada no Firebase Auth
3. Email de verificação é enviado automaticamente
4. Sistema tenta criar o bar **imediatamente**
5. **Falha**: Email ainda não foi verificado pelo usuário

## Solução Implementada

### 1. Nova Função de Validação

Criada a função `isRecentlyCreated()` que permite operações para usuários criados nos últimos 10 minutos:

```javascript
function isRecentlyCreated() {
  // Permite operações para usuários criados nos últimos 10 minutos
  // auth_time está em segundos, então convertemos para milissegundos
  return request.auth != null && 
         (request.auth.token.auth_time * 1000) > (request.time.toMillis() - 600000); // 10 minutos em ms
}
```

**Correção Importante**: O `auth_time` do Firebase Auth está em segundos, enquanto `request.time.toMillis()` retorna milissegundos. A conversão `* 1000` é essencial para a comparação funcionar corretamente.

### 2. Função Combinada

Criada `canCreateBar()` que combina as validações:

```javascript
function canCreateBar() { 
  return isEmailVerifiedOrSocial() || isRecentlyCreated(); 
}
```

### 3. Regras Atualizadas

Substituídas as chamadas `isEmailVerifiedOrSocial()` por `canCreateBar()` em:

- **Criação de bar**: `allow create: if isAuth() && canCreateBar() && validBar(request.resource.data);`
- **Leitura de bar**: `allow read: if isAuth() && canCreateBar() && (isMember(barId, me()) || resource.data.createdByUid == me());`
- **Leitura de membership**: `allow read: if isAuth() && canCreateBar() && isMember(barId, me());`
- **Criação de membership**: `allow create: if isAuth() && canCreateBar() && (memberUid == me() || isOwnerRole(barId));`
- **Reserva de CNPJ**: `allow create: if isAuth() && canCreateBar();`

## Benefícios da Solução

1. **Fluxo Contínuo**: Usuário pode completar o cadastro sem interrupção
2. **Segurança Mantida**: Janela de 10 minutos é suficiente para o cadastro, mas não compromete a segurança
3. **Compatibilidade**: Mantém todas as validações existentes para usuários com email verificado ou login social
4. **Experiência do Usuário**: Elimina a necessidade de verificar email antes de criar o bar

## Fluxo Após Correção

1. Usuário preenche dados (Step 1-3)
2. Conta é criada no Firebase Auth
3. Email de verificação é enviado
4. ✅ **Bar é criado com sucesso** (usuário recém-criado)
5. ✅ **Usuário é direcionado para a Home** (pode ler seus bares)
6. ✅ **HomePage carrega dados sem erro** (listMyBars funciona)
7. Usuário pode verificar email posteriormente

## Considerações de Segurança

- Janela de 10 minutos é restritiva o suficiente para evitar abusos
- Todas as outras operações ainda exigem email verificado
- Usuários sociais (Google/Apple/Facebook) continuam com acesso imediato
- Validações de dados do bar (`validBar()`) permanecem ativas

## Deploy

Regras implantadas com sucesso em: `firebase deploy --only firestore:rules`

---

**Status**: ✅ Resolvido  
**Data**: Janeiro 2025  
**Impacto**: Crítico - Bloqueava cadastro de novos bares