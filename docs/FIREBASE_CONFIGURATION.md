# Configuração do Firebase Console

Este documento contém instruções para configurar adequadamente o Firebase Console para o projeto Bar Boss Mobile (Agenda de Boteco).

## 1. Configuração da Política de Senha

### Problema
Atualmente, a validação de senha no aplicativo exige um mínimo de 8 caracteres, mas o Firebase Auth permite senhas com apenas 6 caracteres por padrão. Isso causa inconsistência quando usuários alteram suas senhas através do link de redefinição.

### Solução
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto `bar-boss-mobile`
3. Navegue para **Authentication** > **Settings**
4. Clique na aba **Password policy**
5. Configure os seguintes parâmetros:
   - **Minimum length**: 8 caracteres
   - **Require uppercase letters**: Opcional (recomendado: desabilitado para simplicidade)
   - **Require lowercase letters**: Opcional (recomendado: desabilitado para simplicidade)
   - **Require numeric characters**: Opcional (recomendado: desabilitado para simplicidade)
   - **Require non-alphanumeric characters**: Opcional (recomendado: desabilitado para simplicidade)
6. Clique em **Save**

### Validação no Código
O validador de senha no arquivo `lib/app/core/utils/validators.dart` já está configurado corretamente:

```dart
static String? password(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField;
  }
  if (value.length < 8) {
    return AppStrings.passwordTooShort;
  }
  return null;
}
```

## 2. Configuração do Nome Público do Projeto

### Problema
Os e-mails enviados pelo Firebase Auth (redefinição de senha, verificação de e-mail) mostram o nome técnico do projeto em inglês "bar-boss-mobile" em vez de um nome amigável em português.

### Solução
1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto `bar-boss-mobile`
3. Clique no ícone de engrenagem (⚙️) no canto superior esquerdo
4. Selecione **Project settings**
5. Na seção **General**, localize o campo **Public-facing name**
6. Altere o nome para: **Agenda de Boteco**
7. Clique em **Save**

### Observações Importantes
- O **Public-facing name** é o nome que aparece nos e-mails enviados aos usuários
- Este nome substitui a variável `%APP_NAME%` nos templates de e-mail
- A alteração é aplicada automaticamente a todos os templates de e-mail
- Se o campo **Public-facing name** não estiver visível, pode ser necessário:
  1. Habilitar o **Google Sign-in** em **Authentication** > **Sign-in method**
  2. Isso criará automaticamente o campo **Public-facing name** nas configurações

## 3. Personalização dos Templates de E-mail (Opcional)

### Localização dos Templates
1. Navegue para **Authentication** > **Templates**
2. Selecione o tipo de e-mail que deseja personalizar:
   - **Password reset** (Redefinição de senha)
   - **Email address verification** (Verificação de e-mail)
   - **Email address change revocation** (Revogação de alteração de e-mail)

### Campos Personalizáveis
- **Sender name**: Nome do remetente
- **Sender address**: Endereço de e-mail do remetente
- **Reply-to address**: Endereço para respostas
- **Subject line**: Linha de assunto
- **Message**: Corpo da mensagem (apenas para redefinição de senha)

### Variáveis Disponíveis
- `%DISPLAY_NAME%`: Nome de exibição do destinatário
- `%APP_NAME%`: Nome do aplicativo (configurado no Public-facing name)
- `%LINK%`: URL para completar a ação
- `%EMAIL%`: Endereço de e-mail do destinatário
- `%NEW_EMAIL%`: Novo endereço de e-mail (apenas para alteração de e-mail)

## 4. Verificação das Configurações

### Teste da Política de Senha
1. Tente criar uma conta com senha de 6 caracteres
2. Deve ser rejeitada pelo Firebase
3. Tente com senha de 8+ caracteres
4. Deve ser aceita

### Teste do Nome do Projeto
1. Solicite redefinição de senha através do app
2. Verifique o e-mail recebido
3. O nome "Agenda de Boteco" deve aparecer no e-mail

## 5. Referências

- [Firebase Auth Password Policy](https://firebase.google.com/docs/auth/admin/manage-users#set_password_policy)
- [Customize Firebase Auth Emails](https://support.google.com/firebase/answer/7000714)
- [Firebase Project Settings](https://support.google.com/firebase/answer/9137752)