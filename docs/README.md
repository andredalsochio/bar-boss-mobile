# Documentação - Bar Boss Mobile

Esta pasta contém a documentação técnica do aplicativo Bar Boss Mobile.

## Estrutura da Documentação

### [cache-architecture.md](./cache-architecture.md)
Documentação completa da arquitetura de cache implementada no aplicativo, incluindo:
- Componentes principais
- Estratégias de cache (Stale-While-Revalidate, Write-Behind, TTL, LRU)
- Configuração via Remote Config
- Métricas e observabilidade
- Fluxo de dados e integração

## Arquitetura Geral

O Bar Boss Mobile segue uma arquitetura MVVM (Model-View-ViewModel) com as seguintes camadas:

```
lib/
├── app/
│   ├── core/                 # Utilitários, constantes e widgets reutilizáveis
│   │   ├── services/        # Serviços compartilhados (ImagePicker, etc.)
│   │   ├── utils/           # Validadores e formatadores
│   │   └── widgets/         # Componentes UI reutilizáveis
│   ├── data/                 # Camada de dados
│   │   ├── cache/           # Sistema de cache (Drift + serviços)
│   │   ├── repositories/    # Implementações de repositórios
│   │   └── services/        # Serviços de dados (Firebase, APIs)
│   ├── domain/              # Camada de domínio
│   │   ├── entities/        # Entidades de negócio
│   │   ├── repositories/    # Interfaces de repositórios
│   │   └── cache/          # Interfaces de cache
│   ├── modules/             # Módulos da aplicação
│   │   ├── auth/           # Autenticação
│   │   ├── cadastro_bar/   # Cadastro de bares
│   │   ├── bar_profile/    # Perfil do bar com upload de foto
│   │   ├── eventos/        # Gestão de eventos
│   │   └── home/           # Tela inicial
│   └── app_widget.dart     # Widget raiz da aplicação
└── main.dart               # Ponto de entrada
```

## Tecnologias Principais

- **Flutter**: Framework de desenvolvimento mobile
- **Provider**: Gerenciamento de estado
- **Firebase**: Backend-as-a-Service
  - Authentication
  - Firestore
  - Storage (upload de imagens)
  - Remote Config
  - Crashlytics
  - Analytics
- **Clerk**: Autenticação avançada
- **Image Picker**: Seleção de imagens da galeria/câmera
- **Search CEP**: Busca automática de endereços

## Funcionalidades Implementadas

### Perfil do Bar
- **Upload de Foto**: Seleção de imagem da galeria ou câmera
- **Validação de Permissões**: Solicitação automática de acesso à galeria/câmera
- **Compressão de Imagem**: Otimização automática para upload
- **Avatar Circular**: Exibição da foto do bar em formato circular
- **Fallback**: Ícone padrão quando não há foto
- **Estados de Loading**: Indicadores visuais durante upload
- **Tratamento de Erros**: Mensagens amigáveis para falhas

### Sistema de Membros
- **Controle de Acesso**: Baseado em membership do usuário
- **Validação de Email**: Obrigatória para usuários não-sociais
- **Permissões Granulares**: Diferentes níveis de acesso por membro
- **Drift**: Banco de dados local (SQLite)
- **GoRouter**: Navegação

## Padrões e Convenções

### Nomenclatura
- Classes, métodos e variáveis em inglês
- Comentários em português brasileiro
- Arquivos em snake_case
- Classes em PascalCase

### Estrutura de Arquivos
- Cada módulo possui suas próprias pastas `views/` e `viewmodels/`
- Providers organizados por funcionalidade
- Interfaces separadas das implementações

### Gerenciamento de Estado
- ViewModels estendem `ChangeNotifier`
- Injeção de dependência via `Provider`
- Estado reativo com `Consumer` e `Selector`

## Funcionalidades Principais

### Autenticação
- Login social (Google, Apple, Facebook)
- Autenticação por email/senha
- Verificação de email obrigatória
- Integração Clerk + Firebase

### Cadastro de Bares
- Processo em 3 etapas
- Validação de CNPJ
- Busca automática de CEP
- Criação de conta integrada

### Gestão de Eventos
- Criação e edição de eventos
- Upload de imagens promocionais
- Listagem com cache inteligente
- Sincronização offline-first

### Sistema de Cache
- Cache local com Drift (SQLite)
- Estratégias avançadas (SWR, Write-Behind)
- Configuração dinâmica via Remote Config
- Métricas de performance

## Configuração do Ambiente

### Pré-requisitos
- Flutter SDK (versão estável mais recente)
- Dart SDK
- Xcode (para iOS)
- Android Studio (para Android)
- Firebase CLI

### Setup
1. Clone o repositório
2. Execute `flutter pub get`
3. Configure Firebase (seguir documentação oficial)
4. Configure Clerk (chaves de API)
5. Execute `flutter run`

## Testes

### Estrutura de Testes
```
test/
├── unit/                    # Testes unitários
├── widget/                  # Testes de widgets
└── integration/             # Testes de integração
```

### Executar Testes
```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/unit/
flutter test test/widget/
```

## Build e Deploy

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contribuição

### Fluxo de Desenvolvimento
1. Criar branch a partir de `develop`
2. Implementar funcionalidade
3. Escrever testes
4. Criar Pull Request para `develop`
5. Code review
6. Merge após aprovação

### Convenções de Commit
- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

## Monitoramento

### Firebase Analytics
- Eventos customizados
- Funis de conversão
- Métricas de engajamento

### Firebase Crashlytics
- Relatórios de crash automáticos
- Logs customizados
- Alertas em tempo real

### Cache Metrics
- Hit/miss rates
- Latência de operações
- Uso de memória/disco
- Dashboards de performance

## Segurança

### Boas Práticas
- Validação de entrada em todas as camadas
- Sanitização de dados
- Criptografia de dados sensíveis
- Logs sem informações sensíveis
- Verificação de integridade

### Compliance
- LGPD (Lei Geral de Proteção de Dados)
- Termos de uso e política de privacidade
- Consentimento explícito para coleta de dados

## Suporte

Para dúvidas técnicas ou problemas:
1. Consulte esta documentação
2. Verifique issues no repositório
3. Entre em contato com a equipe de desenvolvimento

---

**Última atualização**: Janeiro 2025
**Versão da documentação**: 1.0.1