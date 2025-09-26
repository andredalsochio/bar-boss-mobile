# 🌐 Guia de Conectividade - Bar Boss Mobile

**Versão:** 1.0  
**Data:** 17 de Janeiro de 2025  
**Objetivo:** Documentar o uso do ConnectivityMixin para verificação de internet

---

## 📋 Visão Geral

O `ConnectivityMixin` é um componente reutilizável que permite verificar a conectividade com a internet antes de executar operações que requerem rede. Ele exibe automaticamente um dialog amigável quando não há conexão disponível.

---

## 🔧 Implementação

### 1. Dependência

O mixin utiliza o pacote `connectivity_plus` que já está incluído no `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^6.0.5
```

### 2. Estrutura dos Arquivos

```
lib/app/core/services/
└── connectivity_service.dart    # ConnectivityMixin + NoInternetDialog
```

---

## 🚀 Como Usar

### 1. Implementar o Mixin no ViewModel

```dart
import 'package:bar_boss_mobile/app/core/services/connectivity_service.dart';

class MeuViewModel extends ChangeNotifier with ConnectivityMixin {
  // Seus métodos aqui
}
```

### 2. Verificar Conectividade em Métodos

```dart
Future<void> criarAlgo({BuildContext? context}) async {
  // Verifica conectividade antes de prosseguir
  if (context != null) {
    final hasConnection = await checkConnectivity(context, 'criar item');
    if (!hasConnection) {
      debugPrint('❌ Sem conexão - cancelando operação');
      return;
    }
  }
  
  // Sua lógica aqui...
}
```

### 3. Chamar o Método na View

```dart
// Na sua view/página
onPressed: () async {
  await viewModel.criarAlgo(context: context);
}
```

---

## 📱 Dialog de Conectividade

### Características

- **Design:** Segue o padrão visual do app
- **Título:** "Sem conexão com a internet"
- **Mensagem:** Personalizada baseada na ação (ex: "Para criar evento, você precisa estar conectado à internet")
- **Botão:** "Entendi" para fechar o dialog
- **Ícone:** Ícone de WiFi off em vermelho

### Personalização da Mensagem

O dialog adapta automaticamente a mensagem baseada na ação:

```dart
// Exemplo de uso
await checkConnectivity(context, 'salvar evento');
// Resultado: "Para salvar evento, você precisa estar conectado à internet."

await checkConnectivity(context, 'excluir item');
// Resultado: "Para excluir item, você precisa estar conectado à internet."
```

---

## 🔍 Métodos Disponíveis

### `hasInternetConnection()`

Verifica se há conectividade sem exibir dialog.

```dart
final bool isConnected = await hasInternetConnection();
if (isConnected) {
  // Executar operação
}
```

### `checkConnectivity(BuildContext context, String action)`

Verifica conectividade e exibe dialog se necessário.

```dart
final bool canProceed = await checkConnectivity(context, 'criar evento');
if (canProceed) {
  // Executar operação
}
```

---

## ✅ Implementações Existentes

### EventsViewModel

Já implementado nos métodos:
- `saveEvent(context: context)` - Criar/atualizar eventos
- `deleteEvent(context: context)` - Excluir eventos

### Como Usar

```dart
// Criar/editar evento
await viewModel.saveEvent(context: context);

// Excluir evento
await viewModel.deleteEvent(context: context);
```

---

## 🎯 Boas Práticas

### 1. Sempre Passar o Contexto

```dart
// ✅ Correto
await viewModel.saveEvent(context: context);

// ❌ Evitar (não mostra dialog)
await viewModel.saveEvent();
```

### 2. Verificar Conectividade em Operações de Rede

Implemente a verificação em:
- Criação de dados
- Atualização de dados
- Exclusão de dados
- Upload de arquivos
- Sincronização

### 3. Não Verificar em Operações Locais

Não é necessário verificar para:
- Navegação entre telas
- Validação de formulários
- Operações de cache local
- Leitura de dados já carregados

### 4. Mensagens Descritivas

Use descrições claras da ação:

```dart
// ✅ Bom
await checkConnectivity(context, 'salvar evento');
await checkConnectivity(context, 'fazer upload da imagem');

// ❌ Evitar
await checkConnectivity(context, 'fazer isso');
await checkConnectivity(context, 'operação');
```

---

## 🔄 Exemplo Completo

```dart
// meu_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/services/connectivity_service.dart';

class MeuViewModel extends ChangeNotifier with ConnectivityMixin {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> criarItem({BuildContext? context}) async {
    // Verifica conectividade
    if (context != null) {
      final hasConnection = await checkConnectivity(context, 'criar item');
      if (!hasConnection) return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Sua lógica de criação aqui
      await _repository.create(item);
    } catch (e) {
      debugPrint('Erro ao criar item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// minha_page.dart
class MinhaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MeuViewModel>(
      builder: (context, viewModel, child) {
        return ElevatedButton(
          onPressed: viewModel.isLoading ? null : () async {
            await viewModel.criarItem(context: context);
          },
          child: Text('Criar Item'),
        );
      },
    );
  }
}
```

---

## 🐛 Troubleshooting

### Problema: Dialog não aparece

**Solução:** Certifique-se de passar o `context`:
```dart
await viewModel.metodo(context: context);
```

### Problema: Erro de compilação

**Solução:** Verifique se importou o mixin:
```dart
import 'package:bar_boss_mobile/app/core/services/connectivity_service.dart';
```

### Problema: Método não encontrado

**Solução:** Certifique-se de implementar o mixin:
```dart
class MeuViewModel extends ChangeNotifier with ConnectivityMixin {
  // ...
}
```

---

## 📚 Referências

- [connectivity_plus - pub.dev](https://pub.dev/packages/connectivity_plus)
- [Flutter Connectivity Guide](https://docs.flutter.dev/cookbook/networking/connectivity)
- [PROJECT_RULES.md](./PROJECT_RULES.md) - Regras do projeto

---

**📝 Nota:** Este componente faz parte da arquitetura MVVM do Bar Boss Mobile e deve ser usado sempre que uma operação requerer conectividade com a internet.