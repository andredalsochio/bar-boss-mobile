# 📋 PROJECT_RULES.md - Bar Boss Mobile

**Versão:** 3.0  
**Última Atualização:** 15 de Setembro de 2025  
**Objetivo:** Guia centralizado para desenvolvimento e IA antes de qualquer implementação

---

## 🎯 1. Visão Geral

### Resumo do Projeto
O **Bar Boss Mobile** é um aplicativo Flutter para gestão de bares e eventos, permitindo que proprietários de estabelecimentos:
- Cadastrem seus bares com informações completas
- Criem e gerenciem eventos/shows
- Controlem promoções e atrações
- Mantenham perfil atualizado

### Público-Alvo
- Donos de bares, pubs e casas noturnas
- Gestores de eventos
- Estabelecimentos que promovem shows e entretenimento

### Estado Atual
- ✅ Autenticação completa (email/senha + social)
- ✅ Cadastro de bares (3 passos)
- ✅ Gestão de eventos
- ✅ Integração Firebase completa
- ✅ Validação de email implementada
- 🔄 Em desenvolvimento: melhorias de UX e cache local

---

## 🏗️ 2. Arquitetura

### Padrão Arquitetural
**MVVM (Model-View-ViewModel) com Provider**
- **Model:** Entidades de dados (Bar, Event, User)
- **View:** Páginas e widgets da UI
- **ViewModel:** Lógica de negócio e estado
- **Provider:** Gerenciamento de estado e injeção de dependência

### Estrutura de Pastas
```
lib/
├── app/
│   ├── core/
│   │   ├── constants/        # Strings, cores, rotas
│   │   ├── utils/            # Validadores, formatadores
│   │   └── widgets/          # Componentes reutilizáveis
│   ├── data/
│   │   ├── models/           # Entidades de dados
│   │   └── repositories/     # Acesso a dados (Firebase)
│   ├── modules/
│   │   ├── auth/             # Autenticação
│   │   ├── cadastro_bar/     # Cadastro de bares
│   │   ├── eventos/          # Gestão de eventos
│   │   └── home/             # Tela principal
│   └── app_widget.dart       # Configuração do app
└── main.dart                 # Inicialização
```

### Tecnologias Principais
- **Flutter:** Framework principal
- **Firebase Auth:** Autenticação
- **Cloud Firestore:** Banco de dados
- **Firebase Storage:** Armazenamento de imagens
- **Firebase Remote Config:** Configurações remotas
- **Provider:** Gerenciamento de estado
- **GoRouter:** Navegação

---

## 📋 3. Regras de Negócio

### Fluxos de Cadastro

#### Cadastro Completo (Email/Senha)
1. **Passo 1:** Dados de contato (email, CNPJ, nome do bar, responsável, telefone)
2. **Passo 2:** Endereço (CEP com auto-preenchimento)
3. **Passo 3:** Criação de senha
4. **Tela de Verificação:** Email de verificação enviado automaticamente
5. **Resultado:** `completedFullRegistration: true` + `emailVerified: true`

**⚠️ IMPORTANTE:** O usuário NÃO pode acessar o aplicativo até verificar o email. O login é bloqueado para emails não verificados.

#### Login Social + Complemento
1. **Login:** Google/Apple/Facebook
2. **Home:** Banner "Complete seu cadastro (0/3)"
3. **Complemento:** Passo 1 + Passo 2 + Passo 3
4. **Resultado:** `completedFullRegistration: true`

### Validações Obrigatórias
- **Email:** Formato válido + verificação obrigatória
- **CNPJ:** Formato e dígitos verificadores
- **CEP:** Formato brasileiro + auto-preenchimento
- **Telefone:** DDD + 9 dígitos
- **Senha:** Mínimo 8 caracteres (para todos os fluxos)

### Regras de Acesso
- **Criação de eventos:** Permitida mesmo com perfil incompleto (apenas aviso)
- **Funcionalidades completas:** Requerem email verificado
- **Janela de tolerância:** 10 minutos para usuários recém-criados

---

## ⚙️ 4. Regras Técnicas

### Nomenclatura e Convenções
- **Classes/Métodos/Variáveis:** Inglês (camelCase)
- **Comentários:** Português brasileiro (apenas quando necessário)
- **Arquivos:** snake_case.dart
- **Constantes:** UPPER_SNAKE_CASE

### Padrões de Código
```dart
// ✅ Exemplo de ViewModel
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuthRepository _authRepository;
  
  AuthViewModel(this._authRepository);
  
  // Estado reativo
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Método com tratamento de erro
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signIn(email, password);
      // Navegação via GoRouter
      context.go('/home');
    } catch (e) {
      // Log de erro sem dados sensíveis
      debugPrint('Erro no login: ${e.toString()}');
      _showError('Erro ao fazer login');
    } finally {
      _setLoading(false);
    }
  }
}
```

### Injeção de Dependências
```dart
// app_widget.dart
MultiProvider(
  providers: [
    Provider<FirebaseAuthRepository>(
      create: (_) => FirebaseAuthRepository(),
    ),
    ChangeNotifierProvider<AuthViewModel>(
      create: (context) => AuthViewModel(
        context.read<FirebaseAuthRepository>(),
      ),
    ),
  ],
  child: MaterialApp.router(routerConfig: router),
)
```

### Performance e Otimização
- **const:** Usar sempre que possível
- **ListView.builder:** Para listas dinâmicas
- **Lazy loading:** Carregar dados sob demanda
- **Cache local:** Implementar para dados frequentes
- **Debounce:** Para validações em tempo real (500ms)

---

## 🔐 5. Segurança

### Autenticação
- **Verificação de email:** Obrigatória para funcionalidades completas
- **Senhas:** Hash automático pelo Firebase Auth
- **Tokens:** Renovação automática
- **Logout:** Limpeza completa de dados locais

### Firestore Security Rules
```javascript
// Função para verificar usuários recém-criados (10 min)
function isRecentlyCreated() {
  return request.auth.token.auth_time * 1000 > request.time.toMillis() - 600000;
}

// Função para verificar permissão de criação
function canCreateBar() {
  return isEmailVerifiedOrSocial() || isRecentlyCreated();
}
```

### Boas Práticas
- **Logs:** Nunca expor dados sensíveis (senhas, tokens)
- **Validação:** Sempre no cliente E servidor
- **Permissões:** Princípio do menor privilégio
- **Dados pessoais:** Conformidade com LGPD

---

## 🎨 6. UX/UI

### Diretrizes de Interface
- **Responsividade:** Funcional em iOS e Android
- **Cores:** Seguir paleta definida no projeto
- **Tipografia:** Consistente em todo o app
- **Feedback:** Loading states e mensagens claras

### Fluxos Específicos

#### Banner de Cadastro Incompleto
```dart
// Exibir na Home após login social
if (!user.completedFullRegistration) {
  return IncompleteBanner(
    message: "Complete seu cadastro (0/3)",
    action: "Completar agora",
    onTap: () => context.go('/cadastro/passo1'),
  );
}
```

#### Tela de Verificação de Email
- **Quando:** Após cadastro completo via email/senha
- **Funcionalidades:**
  - Auto-verificação a cada 3 segundos
  - Botão "Reenviar email"
  - Link "Voltar ao login"
  - Exibição do email cadastrado

### Estados de Loading
- **Botões:** Spinner + texto "Carregando..."
- **Listas:** Skeleton loading
- **Formulários:** Desabilitar campos durante envio

---

## 🤖 7. Diretrizes para IA

### Antes de Implementar
1. **Ler contexto:** Sempre consultar `.trae/context` e `docs/`
2. **Documentação oficial:** Firebase, Flutter, Dart
3. **Estrutura atual:** Respeitar arquitetura MVVM + Provider
4. **Testes:** Verificar impacto em funcionalidades existentes

### Comandos Proibidos
- **NUNCA** executar `flutter run` sem solicitação explícita
- **NUNCA** modificar `pubspec.yaml` sem aprovação
- **NUNCA** alterar regras do Firestore sem validação

### Fluxo de Desenvolvimento
1. **Análise:** Entender requisito e impacto
2. **Planejamento:** Definir arquivos a modificar
3. **Implementação:** Seguir padrões estabelecidos
4. **Documentação:** Atualizar arquivos `.md` relevantes
5. **Validação:** Testar fluxos críticos
6. **Verificação Final:** Ao final de cada tarefa, verificar se correções de bugs, novas funcionalidades ou melhorias devem ser documentadas nos arquivos `.md` relevantes, atualizando versão e data apenas quando houver modificações reais

### Padrões de Resposta
- **Idioma:** Português brasileiro
- **Código:** Comentários em pt-BR apenas quando necessário
- **Explicações:** Claras e objetivas
- **Exemplos:** Sempre que possível

---

## 📊 8. Schema do Firestore

### Coleção: `users`
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

### Coleção: `bars`
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



---

## 🔄 9. Atualizações e Manutenção

### Versionamento
- **Semantic Versioning:** MAJOR.MINOR.PATCH
- **Changelog:** Manter histórico de mudanças
- **Tags:** Marcar releases importantes

### Documentação
- **Atualizar:** Sempre após implementações
- **Consistência:** Manter informações sincronizadas
- **Limpeza:** Remover informações obsoletas

### Monitoramento
- **Firebase Analytics:** Acompanhar uso do app
- **Crashlytics:** Monitorar erros em produção
- **Performance:** Métricas de carregamento

---

## ⚠️ 10. Problemas Conhecidos e Soluções

### Permissões do Firestore
- **Problema:** Erro de permissão para usuários recém-criados
- **Solução:** Função `isRecentlyCreated()` com conversão correta de unidades
- **Status:** ✅ Resolvido

### Validação de Email
- **Problema:** Fluxo inconsistente entre cadastro e login social
- **Solução:** Tela dedicada de verificação + banner na Home
- **Status:** ✅ Implementado

### Duplo-Clique em Validações
- **Problema:** Botão permite múltiplos cliques durante validação
- **Solução:** Implementar estado de loading + debounce
- **Status:** 🔄 Em implementação

### Cache Local
- **Problema:** Dados recarregados a cada abertura
- **Solução:** Implementar Drift para persistência local
- **Status:** 🔄 Planejado

---

## 📚 11. Documentação Relacionada

Para informações mais detalhadas, consulte:

- **[README.md](./README.md)**: Visão geral do projeto
- **[USER_RULES.md](./USER_RULES.md)**: Diretrizes de interação com a IA
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro
- **[FIREBASE_BACKEND_GUIDE.md](./FIREBASE_BACKEND_GUIDE.md)**: Guia de backend/infra

---

**📝 Nota:** Este documento deve ser consultado antes de qualquer implementação. Mantenha-o atualizado após mudanças significativas no projeto.