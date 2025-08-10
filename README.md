# 🍺 Bar Boss Mobile

**Aplicativo Flutter para gerenciamento de agenda de bares e eventos**

Um aplicativo móvel completo desenvolvido em Flutter que permite aos proprietários de bares gerenciar seus eventos, atrações e promoções de forma eficiente.

## 📱 Funcionalidades

- **Autenticação completa** com Clerk (Google, Apple, Facebook, Email)
- **Cadastro de estabelecimentos** com validação de CNPJ e CEP
- **Gerenciamento de eventos** com datas, atrações e promoções
- **Interface responsiva** para iOS e Android
- **Sincronização offline** com Drift + Firebase
- **Validação em tempo real** de formulários

## 🏗️ Arquitetura

O projeto segue o padrão **MVVM (Model-View-ViewModel)** com as seguintes camadas:

```
lib/
├── app/
│   ├── core/                 # Componentes compartilhados
│   │   ├── constants/        # Strings, cores, rotas
│   │   ├── utils/            # Validadores, formatadores
│   │   └── widgets/          # Componentes UI reutilizáveis
│   ├── modules/              # Módulos da aplicação
│   │   ├── auth/             # Autenticação
│   │   ├── register_bar/     # Cadastro de estabelecimento
│   │   ├── events/           # Gerenciamento de eventos
│   │   └── home/             # Tela inicial
│   └── app_widget.dart       # Configuração da aplicação
└── main.dart                 # Ponto de entrada
```

## 🛠️ Tecnologias

- **Flutter** 3.16+ / **Dart** 3.7+
- **Firebase** (Firestore, Analytics, Crashlytics)
- **Clerk** para autenticação
- **Provider** para gerenciamento de estado
- **GoRouter** para navegação
- **Drift** para persistência local
- **Form validation** em tempo real

## 🚀 Setup do Projeto

### Pré-requisitos

- Flutter SDK 3.16+
- Dart SDK 3.7+
- Xcode (para iOS)
- Android Studio (para Android)
- Conta Firebase
- Conta Clerk

### Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/seu-usuario/bar-boss-mobile.git
cd bar-boss-mobile
```

2. **Instale as dependências**
```bash
cd bar_boss_mobile
flutter pub get
```

3. **Configure o Firebase**
   - Crie um projeto no [Firebase Console](https://console.firebase.google.com)
   - Adicione os apps iOS e Android
   - Baixe os arquivos de configuração:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`
   - Execute: `flutterfire configure`

4. **Configure o Clerk**
   - Crie uma conta em [Clerk.dev](https://clerk.dev)
   - Configure os provedores de autenticação
   - Adicione as chaves no arquivo de configuração

5. **Execute o projeto**
```bash
flutter run
```

## 📋 Estratégia de Branches

- **`main`** - Código de produção
- **`develop`** - Branch de integração
- **`feature/*`** - Features específicas:
  - `feature/auth` - Autenticação
  - `feature/register-bar` - Cadastro de estabelecimento
  - `feature/events` - Gerenciamento de eventos

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Executar testes com coverage
flutter test --coverage
```

## 📱 Plataformas Suportadas

- **iOS** 12.0+
- **Android** API 21+ (Android 5.0+)

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'feat: adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido com ❤️ usando Flutter**