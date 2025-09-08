# 🍺 Bar Boss Mobile

**Aplicativo mobile para gestão de eventos em bares e casas noturnas**

Um aplicativo Flutter completo que permite aos proprietários de bares gerenciar eventos, promoções e atrações de forma simples e eficiente.

## 🚀 Funcionalidades

### 🔐 Autenticação
- Login social (Google, Apple, Facebook)
- Autenticação por email/senha com verificação
- Integração Clerk + Firebase Authentication
- Fluxo de cadastro em 3 etapas para novos bares

### 🏪 Gestão de Bares
- Cadastro completo com validação de CNPJ
- Busca automática de endereço por CEP
- Perfil do estabelecimento
- Informações de contato e responsável

### 🎉 Gestão de Eventos
- Criação e edição de eventos
- Upload de imagens promocionais
- Gestão de atrações e lineup
- Promoções e ofertas especiais
- Calendário de eventos

### 📱 Experiência Mobile
- Interface responsiva para iOS e Android
- Funcionamento offline-first
- Sincronização automática em background
- Cache inteligente para performance otimizada

## 🏗️ Arquitetura

### Padrão MVVM
- **Model**: Entidades de domínio e DTOs
- **View**: Widgets Flutter (páginas e componentes)
- **ViewModel**: Lógica de negócio e gerenciamento de estado

### Tecnologias
- **Flutter**: Framework de desenvolvimento mobile
- **Provider**: Gerenciamento de estado reativo
- **Firebase**: Backend-as-a-Service completo
- **Clerk**: Autenticação avançada
- **Drift**: Banco de dados local (SQLite)
- **GoRouter**: Navegação declarativa

### Sistema de Cache Avançado
- **Offline-First**: Funciona sem conexão
- **Stale-While-Revalidate**: Resposta imediata + atualização em background
- **Write-Behind**: Fila de operações com retry automático
- **TTL Dinâmico**: Configuração via Remote Config
- **LRU**: Gerenciamento inteligente de memória
- **Métricas**: Observabilidade completa de performance

## 📁 Estrutura do Projeto

```
lib/
├── app/
│   ├── core/                 # Utilitários e widgets reutilizáveis
│   │   ├── constants/        # Constantes da aplicação
│   │   ├── utils/            # Validadores e formatadores
│   │   └── widgets/          # Componentes UI reutilizáveis
│   ├── data/                 # Camada de dados
│   │   ├── cache/           # Sistema de cache (Drift + serviços)
│   │   ├── repositories/    # Implementações de repositórios
│   │   └── services/        # Serviços externos (Firebase, APIs)
│   ├── domain/              # Camada de domínio
│   │   ├── entities/        # Entidades de negócio
│   │   ├── repositories/    # Interfaces de repositórios
│   │   └── cache/          # Interfaces de cache
│   ├── modules/             # Módulos da aplicação
│   │   ├── auth/           # Autenticação
│   │   ├── cadastro_bar/   # Cadastro de bares
│   │   ├── eventos/        # Gestão de eventos
│   │   └── home/           # Tela inicial
│   └── app_widget.dart     # Widget raiz com providers
└── main.dart               # Ponto de entrada
```

## 🛠️ Setup do Ambiente

### Pré-requisitos
- Flutter SDK (versão estável mais recente)
- Dart SDK
- Xcode (para desenvolvimento iOS)
- Android Studio (para desenvolvimento Android)
- Firebase CLI
- Git

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/bar-boss-mobile.git
   cd bar-boss-mobile
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase**
   ```bash
   # Instale o Firebase CLI
   npm install -g firebase-tools
   
   # Faça login no Firebase
   firebase login
   
   # Configure o projeto
   flutterfire configure
   ```

4. **Configure as variáveis de ambiente**
   - Crie arquivo `.env` na raiz do projeto
   - Adicione as chaves do Clerk e outras configurações
   
5. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 🧪 Testes

### Executar todos os testes
```bash
flutter test
```

### Testes por categoria
```bash
# Testes unitários
flutter test test/unit/

# Testes de widgets
flutter test test/widget/

# Testes de integração
flutter test test/integration/
```

### Cobertura de testes
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Build e Deploy

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## 📊 Monitoramento

### Firebase Analytics
- Eventos customizados de uso
- Funis de conversão
- Métricas de engajamento
- Segmentação de usuários

### Firebase Crashlytics
- Relatórios automáticos de crashes
- Logs customizados para debugging
- Alertas em tempo real
- Stack traces detalhados

### Cache Metrics
- Hit/miss rates do cache
- Latência de operações
- Uso de memória e disco
- Performance de sincronização

## 🔒 Segurança

### Práticas Implementadas
- Validação rigorosa de entrada
- Sanitização de dados
- Criptografia de dados sensíveis
- Logs sem informações pessoais
- Verificação de integridade
- Compliance com LGPD

## 📚 Documentação

Documentação técnica detalhada disponível em [`/docs`](./docs/):

- **[Arquitetura de Cache](./docs/cache-architecture.md)**: Sistema completo de cache offline-first
- **[README Geral](./docs/README.md)**: Visão geral da arquitetura e convenções

## 🤝 Contribuição

### Fluxo de Desenvolvimento
1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'feat: adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

### Convenções de Commit
- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação de código
- `refactor:` Refatoração
- `test:` Adição de testes
- `chore:` Tarefas de manutenção

### Code Review
- Todos os PRs devem passar por code review
- Testes obrigatórios para novas funcionalidades
- Documentação atualizada quando necessário
- Seguir convenções de código estabelecidas

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## 👥 Equipe

- **Desenvolvimento**: [Seu Nome]
- **Design**: [Designer]
- **Product Owner**: [PO]

## 📞 Suporte

Para dúvidas, problemas ou sugestões:
- 📧 Email: suporte@barboss.com
- 🐛 Issues: [GitHub Issues](https://github.com/seu-usuario/bar-boss-mobile/issues)
- 📖 Documentação: [Wiki do Projeto](https://github.com/seu-usuario/bar-boss-mobile/wiki)

---

**Desenvolvido com ❤️ usando Flutter**