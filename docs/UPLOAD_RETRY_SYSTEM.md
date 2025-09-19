# 🔄 Sistema de Retry de Uploads

**Versão:** 1.0  
**Data:** 17 de Setembro de 2025  
**Objetivo:** Documentação do sistema de retry para uploads falhados

---

## 📋 Visão Geral

O sistema de retry de uploads foi implementado para melhorar a experiência do usuário quando uploads de imagens falham. O sistema oferece:

- **Retry automático:** Até 2 tentativas automáticas por item
- **Retry manual:** Botões para tentar novamente itens específicos ou todos os falhados
- **Feedback visual:** Indicadores de status em tempo real
- **Integração completa:** Funciona em todas as telas de eventos

---

## 🏗️ Arquitetura

### Componentes Principais

#### 1. UploadQueueService
**Localização:** `lib/app/core/services/upload_queue_service.dart`

**Novos métodos adicionados:**
```dart
// Getters para itens falhados
List<UploadQueueItem> get failedItems
bool get hasFailedItems

// Método para retry de todos os itens falhados
Future<void> retryAllFailed()
```

#### 2. EventsViewModel
**Localização:** `lib/app/modules/events/viewmodels/events_viewmodel.dart`

**Novo método adicionado:**
```dart
// Retry de todos os uploads falhados
Future<void> retryAllFailedUploads()
```

#### 3. UploadRetryWidget
**Localização:** `lib/app/core/widgets/upload_retry_widget.dart`

**Componentes:**
- `UploadRetryWidget`: Banner principal para retry de todos os itens falhados
- `UploadStatusIndicator`: Indicador compacto para listas

---

## 🎨 Componentes de UI

### UploadRetryWidget
Banner que aparece quando há uploads falhados para um evento específico.

**Uso:**
```dart
UploadRetryWidget(
  eventId: event.id,
  onRetryAll: () => viewModel.retryAllFailedUploads(),
)
```

**Características:**
- Mostra apenas quando há itens falhados
- Exibe contagem de itens falhados
- Botão "Tentar novamente" para retry de todos
- Design consistente com o app

### UploadStatusIndicator
Indicador compacto para uso em listas de eventos.

**Uso:**
```dart
UploadStatusIndicator(eventId: event.id)
```

**Estados:**
- **Uploading:** Ícone de upload com animação
- **Failed:** Ícone de erro em vermelho
- **Success/None:** Não exibe nada

### PromotionImageWidget
Widget de imagem com botão de retry individual.

**Características:**
- Botão de retry aparece apenas para itens falhados
- Retry individual por imagem
- Feedback visual do status de upload

---

## 📍 Integração nas Telas

### 1. EventFormPage
**Localização:** `lib/app/modules/events/views/event_form_page.dart`

**Integração:**
- `UploadRetryWidget` no topo da página
- `PromotionImageWidget` com retry individual
- Retry automático melhorado

### 2. EventDetailsPage
**Localização:** `lib/app/modules/events/views/event_details_page.dart`

**Integração:**
- `UploadRetryWidget` no topo da página
- `PromotionImageWidget` com retry individual

### 3. EventCardWidget
**Localização:** `lib/app/core/widgets/event_card_widget.dart`

**Integração:**
- `UploadStatusIndicator` na seção de indicadores
- Mostra status de upload em listas

---

## 🔧 Funcionalidades

### Retry Automático
- **Tentativas:** Até 2 tentativas automáticas por item
- **Intervalo:** Imediato após falha
- **Condições:** Falhas de rede, timeouts, erros temporários

### Retry Manual
- **Individual:** Botão em cada `PromotionImageWidget`
- **Em lote:** Botão "Tentar novamente" no `UploadRetryWidget`
- **Feedback:** Loading states e mensagens de sucesso/erro

### Estados de Upload
```dart
enum UploadStatus {
  pending,    // Aguardando upload
  uploading,  // Upload em andamento
  completed,  // Upload concluído
  failed,     // Upload falhado
}
```

---

## 🎯 Fluxo de Uso

### Cenário 1: Upload Falha
1. Usuário adiciona imagem de promoção
2. Upload falha (rede, servidor, etc.)
3. Sistema tenta automaticamente até 2x
4. Se ainda falhar, exibe botão de retry
5. Usuário pode tentar novamente manualmente

### Cenário 2: Múltiplos Uploads Falhados
1. Vários uploads falham em um evento
2. `UploadRetryWidget` aparece no topo da tela
3. Mostra contagem: "2 uploads falharam"
4. Botão "Tentar novamente" para retry de todos
5. Feedback visual durante o processo

### Cenário 3: Visualização em Lista
1. Usuário navega para lista de eventos
2. `UploadStatusIndicator` mostra status em cada card
3. Ícone de erro para eventos com uploads falhados
4. Usuário pode entrar no evento para fazer retry

---

## 🔍 Monitoramento e Debug

### Logs
O sistema gera logs detalhados para debug:
```dart
debugPrint('🔄 Retry: Tentando novamente item ${item.id}');
debugPrint('✅ Retry: Item ${item.id} enviado com sucesso');
debugPrint('❌ Retry: Falha no item ${item.id}: $error');
```

### Estados Observáveis
Todos os componentes usam `Consumer` para reagir a mudanças:
- Lista de itens falhados
- Status de upload individual
- Progresso de retry em lote

---

## 🚀 Melhorias Futuras

### Possíveis Implementações
1. **Retry inteligente:** Backoff exponencial
2. **Persistência:** Salvar fila de retry no storage local
3. **Notificações:** Push notifications para uploads concluídos
4. **Analytics:** Métricas de taxa de sucesso de uploads
5. **Compressão:** Reduzir tamanho de imagens automaticamente

### Otimizações
1. **Cache de imagens:** Evitar re-upload de imagens idênticas
2. **Upload em background:** Continuar uploads quando app está em background
3. **Priorização:** Upload de imagens mais importantes primeiro

---

## 📚 Referências

- **Firebase Storage:** [Documentação oficial](https://firebase.google.com/docs/storage)
- **Flutter Provider:** [Documentação oficial](https://pub.dev/packages/provider)
- **MVVM Pattern:** [Guia de arquitetura](https://docs.flutter.dev/development/data-and-backend/state-mgmt)

---

**✅ Sistema implementado e funcional em todas as telas de eventos.**