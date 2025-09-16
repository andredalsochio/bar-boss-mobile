# 🍺 Bar Boss Mobile

**Aplicativo mobile para gestão de eventos em bares e casas noturnas**

Um aplicativo Flutter completo que permite aos proprietários de bares gerenciar eventos, promoções e atrações de forma simples e eficiente.

## 🚀 Funcionalidades

### 🔐 Autenticação
- Login social (Google, Apple, Facebook)
- Autenticação por email/senha com **verificação obrigatória**
- Firebase Authentication completo
- Fluxo de cadastro em 3 etapas para novos bares
- **Bloqueio de acesso** até verificação de email (cadastro tradicional)

### 🏪 Gestão de Bares
- Cadastro completo com validação de CNPJ
- Busca automática de endereço por CEP
- Perfil do estabelecimento com upload de foto
- Informações de contato e responsável
- Sistema de membros e permissões
- Validação de email para usuários sociais

### 🎉 Gestão de Eventos
- Criação e edição de eventos
- Upload de imagens promocionais
- Gestão de atrações e lineup
- Promoções e ofertas especiais
- Calendário de eventos
- Sistema de permissões baseado em membership

### 📱 Experiência Mobile
- Interface responsiva para iOS e Android
- Funcionamento offline-first
- Sincronização automática em background
- Cache inteligente para performance otimizada
- Upload de imagens com seleção de galeria/câmera
- Validação robusta de formulários
- Tratamento de erros e estados de loading

## 🏗️ Arquitetura

### Padrão MVVM
- **Model**: Entidades de domínio e DTOs
- **View**: Widgets Flutter (páginas e componentes)
- **ViewModel**: Lógica de negócio e gerenciamento de estado

### Tecnologias
- **Flutter**: Framework de desenvolvimento mobile
- **Provider**: Gerenciamento de estado reativo
- **Firebase**: Backend-as-a-Service completo
  - Authentication
  - Firestore
  - Remote Config
  - Crashlytics
  - Analytics
- **Drift**: Banco de dados local (SQLite)
- **GoRouter**: Navegação declarativa
- **Image Picker**: Seleção de imagens da galeria/câmera
- **Search CEP**: Busca automática de endereços
- **Font Awesome**: Ícones vetoriais

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
   - Adicione as configurações necessárias do Firebase
   
5. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 📚 Documentação

Documentação técnica detalhada disponível nos seguintes arquivos:

- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto
- **[USER_RULES.md](./USER_RULES.md)**: Diretrizes de interação com a IA
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro
- **[FIREBASE_BACKEND_GUIDE.md](./FIREBASE_BACKEND_GUIDE.md)**: Guia de backend/infra

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

**Desenvolvido com ❤️ usando Flutter**