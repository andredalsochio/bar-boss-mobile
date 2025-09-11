# 📚 Documentação Técnica - Bar Boss Mobile

**Versão:** 1.0  
**Última Atualização:** 10 de Setembro de 2025

> **Nota:** Para regras gerais do projeto, consulte [PROJECT_RULES.md](../PROJECT_RULES.md)

Esta pasta contém documentação específica de implementações e funcionalidades do aplicativo.

---

## 📋 Índice de Documentos

### Funcionalidades Implementadas
- **[bar-profile-feature.md](./bar-profile-feature.md)** - Sistema de perfil com upload de fotos
- **[cache-architecture.md](./cache-architecture.md)** - Arquitetura de cache local
- **[app-drawer-refactor.md](./app-drawer-refactor.md)** - Refatoração do menu lateral

### Melhorias e Correções
- **[auth-flow-improvements.md](./auth-flow-improvements.md)** - Melhorias no fluxo de autenticação
- **[firestore-permission-fix.md](./firestore-permission-fix.md)** - Correção de permissões
- **[recent-registration-improvements.md](./recent-registration-improvements.md)** - Últimas melhorias no cadastro

---

## 🚀 Setup de Desenvolvimento

### Pré-requisitos
```bash
# Flutter SDK (versão estável mais recente)
flutter --version

# Dependências do projeto
flutter pub get

# Configuração do Firebase
flutter packages pub run build_runner build
```

### Configuração do Firebase
1. Baixar `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
2. Colocar nos diretórios corretos:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### Comandos Úteis
```bash
# Executar em modo debug
flutter run

# Build para produção
flutter build apk --release
flutter build ios --release

# Testes
flutter test

# Análise de código
flutter analyze
```

---

## 🧪 Testes

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

---

## 📦 Build e Deploy

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## 🔄 Fluxo de Desenvolvimento

### Convenções de Commit
- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

### Processo
1. Criar branch a partir de `develop`
2. Implementar funcionalidade seguindo [PROJECT_RULES.md](../PROJECT_RULES.md)
3. Criar Pull Request para `develop`
4. Code review
5. Merge após aprovação

---

**📝 Nota:** Para informações completas sobre arquitetura, regras de negócio e diretrizes técnicas, consulte [PROJECT_RULES.md](../PROJECT_RULES.md)

## Suporte

Para dúvidas técnicas ou problemas:
1. Consulte esta documentação
2. Verifique issues no repositório
3. Entre em contato com a equipe de desenvolvimento

---

**Última atualização**: Janeiro 2025
**Versão da documentação**: 1.0.1