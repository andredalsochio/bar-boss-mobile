# 🗄️ FIRESTORE_SCHEMA.md - Estrutura de Dados

**Versão:** 2.1  
**Última Atualização:** 17 de Setembro de 2025  
**Objetivo:** Definição completa das coleções, campos e relacionamentos do Firestore

> **📋 NOTA:** Para regras de segurança e permissões, consulte [FIRESTORE_AUTH_FLOW.md](./FIRESTORE_AUTH_FLOW.md).

---

## 📊 1. VISÃO GERAL DO SCHEMA

### Estrutura Principal
```
firestore/
├── users/{uid}                    # Dados do usuário
├── bars/{barId}                   # Dados do bar
├── bars/{barId}/members/{uid}     # Membros do bar (permissões)
├── bars/{barId}/events/{eventId} # Eventos do bar
└── cnpj_registry/{cnpj}          # Registro de unicidade CNPJ
```

### Relacionamentos
- **1:N** - User → Bars (um usuário pode ter múltiplos bares)
- **N:M** - Users ↔ Bars (via subcoleção members)
- **1:N** - Bar → Events (um bar pode ter múltiplos eventos)
- **1:1** - CNPJ → Bar (unicidade garantida)

---

## 👤 2. COLEÇÃO: users/{uid}

### Estrutura
```typescript
interface User {
  uid: string;                    // UID do usuário (Firebase Auth)
  email: string;                  // Email normalizado (lowercase, trim)
  displayName: string;            // Nome de exibição
  emailVerified: boolean;         // Email verificado? (reflete token)
  completedFullRegistration: boolean; // Cadastro completo?
  createdAt: Timestamp;           // Data de criação
  updatedAt: Timestamp;           // Data de atualização
}
```

### Exemplo de Documento
```json
{
  "uid": "abc123def456",
  "email": "joao@exemplo.com",
  "displayName": "João Silva",
  "emailVerified": true,
  "completedFullRegistration": true,
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

### Regras de Negócio
- **uid:** Sempre igual ao UID do Firebase Auth
- **email:** Normalizado (lowercase + trim) para consistência
- **emailVerified:** Reflete o token, mas não substitui checagem de rules
- **completedFullRegistration:** `true` apenas após completar todos os 3 passos
- **Timestamps:** Sempre em UTC

### Índices Necessários
```javascript
// Índice composto para consultas de usuários por email
users: {
  email: "asc",
  createdAt: "desc"
}
```

---

## 🏪 3. COLEÇÃO: bars/{barId}

### Estrutura
```typescript
interface Bar {
  id: string;                     // ID do bar (auto-gerado)
  name: string;                   // Nome do bar
  email: string;                  // Email de contato (normalizado)
  cnpj: string;                   // CNPJ (apenas dígitos)
  responsibleName: string;        // Nome do responsável
  phone: string;                  // Telefone formatado
  address: Address;               // Endereço completo
  profile: ProfileCompleteness;   // Status de completude
  primaryOwnerUid: string;        // UID do proprietário principal
  createdByUid: string;           // UID do criador
  createdAt: Timestamp;           // Data de criação
  updatedAt: Timestamp;           // Data de atualização
}

interface Address {
  cep: string;                    // CEP formatado (12345-678)
  street: string;                 // Rua/Avenida
  number: string;                 // Número
  complement?: string;            // Complemento (opcional)
  city: string;                   // Cidade
  state: string;                  // Estado (UF - 2 caracteres)
}

interface ProfileCompleteness {
  contactsComplete: boolean;      // Dados de contato completos?
  addressComplete: boolean;       // Endereço completo?
  passwordComplete: boolean;      // Senha definida?
}
```

### Exemplo de Documento
```json
{
  "id": "bar_abc123",
  "name": "Bar do João",
  "email": "contato@bardojoao.com",
  "cnpj": "12345678000195",
  "responsibleName": "João Silva",
  "phone": "(11) 99999-9999",
  "address": {
    "cep": "01234-567",
    "street": "Rua das Flores",
    "number": "123",
    "complement": "Sala 1",
    "city": "São Paulo",
    "state": "SP"
  },
  "profile": {
    "contactsComplete": true,
    "addressComplete": true,
    "passwordComplete": true
  },
  "primaryOwnerUid": "abc123def456",
  "createdByUid": "abc123def456",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

### Regras de Negócio
- **id:** Auto-gerado pelo Firestore
- **email:** Normalizado e único por bar
- **cnpj:** Apenas dígitos, único por bar
- **phone:** Formato brasileiro (11) 99999-9999
- **address.cep:** Formato brasileiro 12345-678
- **address.state:** Sempre 2 caracteres (UF)
- **profile:** Atualizado conforme completude dos passos
- **primaryOwnerUid:** Sempre o criador inicial
- **createdByUid:** Pode ser diferente em casos de migração

### Índices Necessários
```javascript
// Índice para busca por criador
bars: {
  createdByUid: "asc",
  createdAt: "desc"
}

// Índice para busca por email (unicidade)
bars: {
  email: "asc"
}

// Índice para busca por CNPJ (unicidade)
bars: {
  cnpj: "asc"
}
```

---

## 👥 4. SUBCOLEÇÃO: bars/{barId}/members/{uid}

### Estrutura
```typescript
interface BarMember {
  uid: string;                    // UID do membro
  email: string;                  // Email do membro
  displayName: string;            // Nome de exibição
  role: MemberRole;               // Papel no bar
  addedByUid: string;             // UID de quem adicionou
  addedAt: Timestamp;             // Data de adição
}

enum MemberRole {
  OWNER = "OWNER",                // Proprietário (controle total)
  ADMIN = "ADMIN",                // Administrador (quase tudo)
  MEMBER = "MEMBER"               // Membro (acesso limitado)
}
```

### Exemplo de Documento
```json
{
  "uid": "abc123def456",
  "email": "joao@exemplo.com",
  "displayName": "João Silva",
  "role": "OWNER",
  "addedByUid": "abc123def456",
  "addedAt": "2025-01-15T10:30:00Z"
}
```

### Regras de Negócio
- **uid:** Sempre igual ao UID do usuário
- **role:** Define permissões no bar
- **OWNER:** Criador do bar, não pode ser removido
- **ADMIN:** Pode gerenciar eventos e membros
- **MEMBER:** Pode apenas visualizar
- **addedByUid:** Rastreabilidade de quem adicionou

### Permissões por Role
```typescript
const permissions = {
  OWNER: {
    canDeleteBar: true,
    canManageMembers: true,
    canManageEvents: true,
    canEditBarInfo: true,
    canViewAnalytics: true
  },
  ADMIN: {
    canDeleteBar: false,
    canManageMembers: true,
    canManageEvents: true,
    canEditBarInfo: true,
    canViewAnalytics: true
  },
  MEMBER: {
    canDeleteBar: false,
    canManageMembers: false,
    canManageEvents: false,
    canEditBarInfo: false,
    canViewAnalytics: false
  }
};
```

---

## 🎉 5. SUBCOLEÇÃO: bars/{barId}/events/{eventId}

### Estrutura
```typescript
interface Event {
  id: string;                     // ID do evento (auto-gerado)
  title: string;                  // Título do evento
  description?: string;           // Descrição (opcional)
  startAt: Timestamp;             // Data/hora de início
  endAt?: Timestamp;              // Data/hora de fim (opcional)
  attractions: string[];          // Lista de atrações
  promotions: Promotion[];        // Lista de promoções
  published: boolean;             // Evento publicado?
  createdByUid: string;           // UID do criador
  createdAt: Timestamp;           // Data de criação
  updatedAt: Timestamp;           // Data de atualização
}

interface Promotion {
  id: string;                     // ID da promoção
  title: string;                  // Título da promoção
  description?: string;           // Descrição (opcional)
  imageUrl?: string;              // URL da imagem (Firebase Storage)
  validFrom?: Timestamp;          // Válida a partir de
  validUntil?: Timestamp;         // Válida até
}
```

### Exemplo de Documento
```json
{
  "id": "event_xyz789",
  "title": "Show de Rock - Banda XYZ",
  "description": "Uma noite incrível de rock nacional",
  "startAt": "2025-01-20T20:00:00Z",
  "endAt": "2025-01-21T02:00:00Z",
  "attractions": [
    "Banda XYZ",
    "DJ João",
    "Banda ABC"
  ],
  "promotions": [
    {
      "id": "promo_001",
      "title": "Happy Hour",
      "description": "Cerveja pela metade do preço até 22h",
      "imageUrl": "gs://bar-boss/bars/bar_abc123/events/event_xyz789/promo_001.jpg",
      "validFrom": "2025-01-20T18:00:00Z",
      "validUntil": "2025-01-20T22:00:00Z"
    }
  ],
  "published": true,
  "createdByUid": "abc123def456",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

### Regras de Negócio
- **id:** Auto-gerado pelo Firestore
- **title:** Obrigatório, máximo 100 caracteres
- **startAt:** Obrigatório, deve ser no futuro
- **endAt:** Opcional, deve ser após startAt se informado
- **attractions:** Array de strings, máximo 10 itens
- **promotions:** Máximo 3 promoções por evento
- **published:** Controla visibilidade pública
- **imageUrl:** Seguir estrutura do Storage Architecture

### Índices Necessários
```javascript
// Índice para eventos por data (mais recentes primeiro)
events: {
  startAt: "desc",
  published: "asc"
}

// Índice para eventos por criador
events: {
  createdByUid: "asc",
  startAt: "desc"
}
```

---

## 🔒 6. COLEÇÃO: cnpj_registry/{cnpj}

### Estrutura
```typescript
interface CNPJRegistry {
  cnpj: string;                   // CNPJ (apenas dígitos) - usado como ID
  barId: string;                  // ID do bar associado
  createdAt: Timestamp;           // Data de criação
}
```

### Exemplo de Documento
```json
{
  "cnpj": "12345678000195",
  "barId": "bar_abc123",
  "createdAt": "2025-01-15T10:30:00Z"
}
```

### Regras de Negócio
- **cnpj:** Usado como ID do documento (garantia de unicidade)
- **barId:** Referência ao bar que possui este CNPJ
- **Criação:** Apenas durante criação de bar
- **Exclusão:** Apenas quando bar é excluído

### Uso
```dart
// Verificar se CNPJ já existe
Future<bool> isCnpjAvailable(String cnpj) async {
  final doc = await FirebaseFirestore.instance
      .collection('cnpj_registry')
      .doc(cnpj)
      .get();
  return !doc.exists;
}

// Registrar CNPJ
Future<void> registerCnpj(String cnpj, String barId) async {
  await FirebaseFirestore.instance
      .collection('cnpj_registry')
      .doc(cnpj)
      .set({
    'cnpj': cnpj,
    'barId': barId,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

---

## 🔗 7. RELACIONAMENTOS E CONSULTAS

### Consultas Comuns

#### Buscar bares de um usuário
```dart
Future<List<Bar>> getUserBars(String uid) async {
  final query = await FirebaseFirestore.instance
      .collection('bars')
      .where('createdByUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .get();
  
  return query.docs.map((doc) => Bar.fromFirestore(doc)).toList();
}
```

#### Buscar eventos de um bar
```dart
Future<List<Event>> getBarEvents(String barId, {bool publishedOnly = false}) async {
  var query = FirebaseFirestore.instance
      .collection('bars')
      .doc(barId)
      .collection('events')
      .orderBy('startAt', descending: true);
  
  if (publishedOnly) {
    query = query.where('published', isEqualTo: true);
  }
  
  final result = await query.get();
  return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
}
```

#### Verificar permissão de usuário em bar
```dart
Future<MemberRole?> getUserRoleInBar(String barId, String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('bars')
      .doc(barId)
      .collection('members')
      .doc(uid)
      .get();
  
  if (!doc.exists) return null;
  return MemberRole.values.firstWhere(
    (role) => role.toString().split('.').last == doc.data()!['role'],
  );
}
```

### Transações para Consistência

#### Criar bar com membro owner
```dart
Future<void> createBarWithOwner(Bar bar, String ownerUid) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    // 1. Criar documento do bar
    final barRef = FirebaseFirestore.instance.collection('bars').doc();
    transaction.set(barRef, bar.toMap()..['id'] = barRef.id);
    
    // 2. Adicionar owner como membro
    final memberRef = barRef.collection('members').doc(ownerUid);
    transaction.set(memberRef, {
      'uid': ownerUid,
      'email': bar.email,
      'displayName': bar.responsibleName,
      'role': 'OWNER',
      'addedByUid': ownerUid,
      'addedAt': FieldValue.serverTimestamp(),
    });
    
    // 3. Registrar CNPJ
    final cnpjRef = FirebaseFirestore.instance
        .collection('cnpj_registry')
        .doc(bar.cnpj);
    transaction.set(cnpjRef, {
      'cnpj': bar.cnpj,
      'barId': barRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });
}
```

---

## 📈 8. OTIMIZAÇÕES E PERFORMANCE

### Estratégias de Cache

#### Cache Local com Drift
```dart
// Tabela local para cache de bares
@DataClassName('BarEntity')
class Bars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  // ... outros campos
  DateTimeColumn get lastSyncAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Sincronização inteligente
class BarRepository {
  Future<List<Bar>> getBars(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Tentar cache local primeiro
      final cached = await _getFromLocalCache(uid);
      if (cached.isNotEmpty) {
        // Sync em background
        _syncInBackground(uid);
        return cached;
      }
    }
    
    // Buscar do Firestore
    return await _getFromFirestore(uid);
  }
}
```

#### Paginação para Eventos
```dart
class EventRepository {
  static const int pageSize = 20;
  
  Future<List<Event>> getEvents(String barId, {DocumentSnapshot? lastDoc}) async {
    var query = FirebaseFirestore.instance
        .collection('bars')
        .doc(barId)
        .collection('events')
        .orderBy('startAt', descending: true)
        .limit(pageSize);
    
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    
    final result = await query.get();
    return result.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }
}
```

### Listeners Eficientes

#### Listener para mudanças em tempo real
```dart
class BarViewModel extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _barsSubscription;
  
  void listenToUserBars(String uid) {
    _barsSubscription = FirebaseFirestore.instance
        .collection('bars')
        .where('createdByUid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      _updateBarsFromSnapshot(snapshot);
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _barsSubscription?.cancel();
    super.dispose();
  }
}
```

---

## 🔧 9. MIGRAÇÃO E VERSIONAMENTO

### Estratégia de Migração
```dart
class SchemaVersion {
  static const int current = 1;
  
  static Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt('schema_version') ?? 0;
    
    if (currentVersion < current) {
      await _runMigrations(currentVersion, current);
      await prefs.setInt('schema_version', current);
    }
  }
  
  static Future<void> _runMigrations(int from, int to) async {
    for (int version = from + 1; version <= to; version++) {
      switch (version) {
        case 1:
          await _migrateToV1();
          break;
        // Futuras migrações...
      }
    }
  }
}
```

### Backup e Restore
```dart
class BackupService {
  Future<Map<String, dynamic>> exportUserData(String uid) async {
    final userData = await _getUserData(uid);
    final barsData = await _getUserBars(uid);
    final eventsData = await _getUserEvents(uid);
    
    return {
      'version': SchemaVersion.current,
      'exportedAt': DateTime.now().toIso8601String(),
      'user': userData,
      'bars': barsData,
      'events': eventsData,
    };
  }
}
```

---

## 📚 10. DOCUMENTAÇÃO RELACIONADA

Para implementação e regras, consulte:

- **[BUSINESS_RULES_AUTH.md](./BUSINESS_RULES_AUTH.md)**: Regras de autenticação
- **[FIRESTORE_RULES.md](./FIRESTORE_RULES.md)**: Regras de segurança
- **[STORAGE_ARCHITECTURE.md](./STORAGE_ARCHITECTURE.md)**: Arquitetura de imagens
- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto

---

**📊 Este schema é a fonte única da verdade para a estrutura de dados. Mantenha-o atualizado após mudanças no banco.**