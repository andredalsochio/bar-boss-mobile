# 🍺 Agenda de Boteco

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

- **[FIRESTORE_AUTH_FLOW.md](./FIRESTORE_AUTH_FLOW.md)**: Fluxo consolidado de autenticação e cadastro
- **[PROJECT_RULES.md](./PROJECT_RULES.md)**: Regras globais do projeto
- **[USER_RULES.md](./USER_RULES.md)**: Diretrizes de interação com a IA
- **[CADASTRO_RULES.md](./CADASTRO_RULES.md)**: Regras específicas de cadastro
- **[BUSINESS_RULES_AUTH.md](./BUSINESS_RULES_AUTH.md)**: Regras de negócio de autenticação
- **[FIRESTORE_SCHEMA.md](./FIRESTORE_SCHEMA.md)**: Estrutura de dados do Firestore
- **[FIRESTORE_RULES.md](./FIRESTORE_RULES.md)**: Regras de segurança do Firestore
- **[STORAGE_ARCHITECTURE.md](./STORAGE_ARCHITECTURE.md)**: Arquitetura de armazenamento
- **[FIREBASE_BACKEND_GUIDE.md](./FIREBASE_BACKEND_GUIDE.md)**: Guia de backend/infra

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

**Desenvolvido com ❤️ usando Flutter**
# Bar Boss Mobile
## Geração de Ícones e Splash (Android/iOS)

Este projeto já está preparado para gerar todos os ícones e telas de splash nativas conforme especificações oficiais da Apple e Google usando `flutter_launcher_icons` e `flutter_native_splash`.

### Passo a passo

1. Coloque o arquivo do logo em `assets/branding/boteco-logo.jpeg` (PNG transparente ou SVG também são aceitos).
2. Instale dependências (já feito):
   - `flutter pub get`
   - `npm install` dentro de `tools/`
3. Gere os arquivos‑fonte normalizados (centralização, padding e tamanhos corretos):
   - `npm run --prefix tools generate:brand`
   - Isto cria:
     - `assets/app_icons/app_icon.png` (1024x1024)
     - `assets/app_icons/app_icon_foreground.png` (1024x1024)
     - `assets/splash/splash_logo.png` (512x512)
     - `assets/splash/splash_logo_dark.png` (512x512)
     - `assets/splash/splash_logo_android12.png` (960x960)
     - `assets/splash/splash_logo_android12_dark.png` (960x960)
4. Gere os ícones:
   - `dart run flutter_launcher_icons`
5. Gere as telas de splash:
   - `dart run flutter_native_splash:create`

### Especificações atendidas

- **Android (ícones)**: mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi (48/72/96/144/192 px), adaptive icon (foreground transparente + background sólido).
- **Android 12 (splash)**: usa cor de janela e ícone animado, imagens 960x960 com máscara em círculo (~640 px).
- **iOS (ícones)**: todos os tamanhos do AppIcon.appiconset (20/29/40/60 pt em @1x/@2x/@3x, iPad 76/83.5 pt, App Store 1024x1024).
- **iOS (splash)**: LaunchScreen.storyboard com logo centralizado e fundo sólido.

### Cores

- Claro: `#FFFFFF`
- Escuro: `#121212`

Para alterar, edite `flutter_native_splash` e `adaptive_icon_background` no `pubspec.yaml` e regenere.