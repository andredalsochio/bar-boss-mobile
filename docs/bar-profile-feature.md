# Funcionalidade de Perfil do Bar - Bar Boss Mobile

## Visão Geral

Este documento descreve a implementação da funcionalidade de perfil do bar, incluindo upload de fotos, validação de permissões e integração com o sistema de membros.

## Componentes Principais

### 1. ImagePickerService
**Localização**: `lib/app/core/services/image_picker_service.dart`

Serviço responsável pela seleção e processamento de imagens:

```dart
class ImagePickerService {
  Future<File?> pickImageFromGallery();
  Future<File?> pickImageFromCamera();
  Future<void> requestPermissions();
}
```

**Funcionalidades:**
- Seleção de imagem da galeria
- Captura de foto pela câmera
- Solicitação automática de permissões
- Validação de formato de arquivo
- Compressão automática de imagens

### 2. BarProfileViewModel
**Localização**: `lib/app/modules/bar_profile/viewmodels/bar_profile_viewmodel.dart`

ViewModel responsável pelo gerenciamento de estado do perfil:

```dart
class BarProfileViewModel extends ChangeNotifier {
  Bar? get bar;
  bool get isLoading;
  String? get error;
  
  Future<void> loadBarProfile();
  Future<void> uploadBarPhoto(File imageFile);
  Future<void> updateBarInfo(Map<String, dynamic> data);
}
```

**Estados Gerenciados:**
- Dados do bar atual
- Estado de carregamento
- Mensagens de erro
- Progresso de upload

### 3. BarProfilePage
**Localização**: `lib/app/modules/bar_profile/views/bar_profile_page.dart`

Interface do usuário para o perfil do bar:

**Componentes UI:**
- Avatar circular com foto do bar
- Botão para alterar foto
- Informações do estabelecimento
- Indicadores de loading
- Tratamento de estados de erro

## Fluxo de Upload de Foto

### 1. Seleção da Imagem
```dart
// Usuário toca no botão de câmera
// Sistema apresenta opções: Galeria ou Câmera
// ImagePickerService processa a seleção
File? imageFile = await _imagePickerService.pickImageFromGallery();
```

### 2. Validação e Processamento
```dart
// Validação de formato
if (!_isValidImageFormat(imageFile)) {
  throw Exception('Formato de imagem não suportado');
}

// Compressão automática
File compressedImage = await _compressImage(imageFile);
```

### 3. Upload para Firebase Storage
```dart
// Upload com progresso
String downloadUrl = await _firebaseStorage
  .ref('bars/${barId}/profile.jpg')
  .putFile(compressedImage)
  .then((snapshot) => snapshot.ref.getDownloadURL());
```

### 4. Atualização do Firestore
```dart
// Atualização do documento do bar
await _firestore.collection('bars').doc(barId).update({
  'photoUrl': downloadUrl,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

## Sistema de Permissões

### Permissões Necessárias

#### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Este app precisa acessar a câmera para tirar fotos do seu bar</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Este app precisa acessar a galeria para selecionar fotos do seu bar</string>
```

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Fluxo de Solicitação
1. Verificação de permissão atual
2. Solicitação se necessário
3. Tratamento de negação
4. Redirecionamento para configurações se bloqueado

## Validação de Acesso

### Regras de Negócio
- Apenas membros do bar podem alterar a foto
- Usuários devem ter email verificado
- Proprietários têm acesso total
- Membros precisam de permissão específica

### Implementação no ViewModel
```dart
Future<void> uploadBarPhoto(File imageFile) async {
  // Verificação de autenticação
  if (!_authService.isAuthenticated) {
    throw Exception('Usuário não autenticado');
  }
  
  // Verificação de membership
  if (!await _membershipService.isMember(barId)) {
    throw Exception('Acesso negado');
  }
  
  // Verificação de email
  if (!_authService.isEmailVerified) {
    throw Exception('Email não verificado');
  }
  
  // Prosseguir com upload...
}
```

## Estados da Interface

### Estado Inicial
- Avatar com ícone padrão
- Botão de câmera visível
- Informações básicas do bar

### Estado de Loading
- Indicador de progresso circular
- Botão de câmera desabilitado
- Overlay semi-transparente

### Estado de Sucesso
- Avatar atualizado com nova foto
- Mensagem de confirmação (toast)
- Botão de câmera reabilitado

### Estado de Erro
- Manutenção da foto anterior
- Mensagem de erro específica
- Opção de tentar novamente

## Otimizações de Performance

### Compressão de Imagem
- Redimensionamento automático para 800x800px
- Qualidade ajustada para 85%
- Conversão para JPEG quando necessário

### Cache de Imagens
- Cache local da foto do perfil
- Invalidação automática após upload
- Fallback para versão em cache

### Lazy Loading
- Carregamento sob demanda
- Placeholder durante carregamento
- Retry automático em caso de falha

## Tratamento de Erros

### Tipos de Erro
1. **Permissão Negada**: Redireciona para configurações
2. **Falha de Upload**: Retry automático com backoff
3. **Formato Inválido**: Mensagem específica
4. **Tamanho Excessivo**: Compressão automática
5. **Sem Conexão**: Enfileiramento para retry

### Mensagens de Erro
```dart
static const Map<String, String> errorMessages = {
  'permission_denied': 'Permissão de acesso negada',
  'upload_failed': 'Falha no upload. Tente novamente',
  'invalid_format': 'Formato de imagem não suportado',
  'file_too_large': 'Arquivo muito grande',
  'no_connection': 'Sem conexão. Upload será feito automaticamente',
};
```

## Testes

### Testes Unitários
- Validação de formatos de arquivo
- Lógica de compressão
- Estados do ViewModel
- Tratamento de erros

### Testes de Widget
- Renderização do avatar
- Interação com botões
- Estados de loading
- Exibição de erros

### Testes de Integração
- Fluxo completo de upload
- Integração com Firebase
- Validação de permissões
- Sincronização de dados

## Métricas e Monitoramento

### Eventos Rastreados
- `bar_photo_upload_started`
- `bar_photo_upload_completed`
- `bar_photo_upload_failed`
- `permission_requested`
- `permission_denied`

### Métricas de Performance
- Tempo de upload
- Taxa de sucesso
- Tamanho médio dos arquivos
- Uso de compressão

## Considerações de Segurança

### Validação de Arquivo
- Verificação de tipo MIME
- Limitação de tamanho (5MB)
- Sanitização de nome do arquivo
- Verificação de conteúdo

### Controle de Acesso
- Validação no cliente e servidor
- Tokens de autenticação
- Regras do Firestore
- Auditoria de alterações

## Roadmap Futuro

### Melhorias Planejadas
- Múltiplas fotos do bar
- Galeria de imagens
- Filtros e edição básica
- Reconhecimento de conteúdo
- Backup automático
- Sincronização entre dispositivos