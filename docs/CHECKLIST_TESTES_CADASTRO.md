# 📋 Checklist de Testes - Fluxos de Cadastro

**Versão:** 1.0  
**Data:** 15 de Janeiro de 2025  
**Objetivo:** Validar os dois fluxos de cadastro após refatoração

---

## 🎯 Cenários de Teste

### 📧 Fluxo A: Cadastro Completo (Email/Senha)

#### Pré-condições
- [ ] App instalado e funcionando
- [ ] Firebase configurado corretamente
- [ ] Cloud Functions deployadas
- [ ] Firestore rules atualizadas

#### Passo 1: Dados de Contato
- [ ] **Acessar:** Tela de login → "Cadastra-se?" → Passo 1
- [ ] **Email:** Inserir email válido não cadastrado
- [ ] **CNPJ:** Inserir CNPJ válido não cadastrado (formato: 00.000.000/0000-00)
- [ ] **Nome do Bar:** Inserir nome válido (mín. 2 caracteres)
- [ ] **Responsável:** Inserir nome válido (mín. 2 caracteres)
- [ ] **Telefone:** Inserir telefone válido (formato: (00) 00000-0000)
- [ ] **Validação:** Botão "Continuar" deve estar habilitado
- [ ] **Ação:** Clicar em "Continuar"

**Resultado Esperado:**
- [ ] Validação de email via `fetchSignInMethodsForEmail`
- [ ] CNPJ não validado no Step1 (fluxo clássico)
- [ ] Navegação para Passo 2

#### Passo 2: Endereço
- [ ] **CEP:** Inserir CEP válido (formato: 00000-000)
- [ ] **Auto-preenchimento:** Verificar se rua, cidade e estado são preenchidos
- [ ] **Número:** Inserir número válido
- [ ] **Complemento:** Campo opcional
- [ ] **Validação:** Botão "Continuar" deve estar habilitado
- [ ] **Ação:** Clicar em "Continuar"

**Resultado Esperado:**
- [ ] Navegação para Passo 3

#### Passo 3: Senha
- [ ] **Senha:** Inserir senha válida (mín. 8 caracteres)
- [ ] **Confirmar Senha:** Inserir mesma senha
- [ ] **Validação:** Botão "Finalizar cadastro" deve estar habilitado
- [ ] **Ação:** Clicar em "Finalizar cadastro"

**Resultado Esperado:**
- [ ] Criação de conta no Firebase Auth
- [ ] Envio automático de email de verificação
- [ ] Navegação para tela de verificação de email
- [ ] Dados salvos no Firestore com `completedFullRegistration: true`

#### Verificação de Email
- [ ] **Tela:** Exibir email cadastrado
- [ ] **Auto-verificação:** A cada 3 segundos
- [ ] **Reenvio:** Botão "Reenviar email" funcional
- [ ] **Voltar:** Link "Voltar ao login" funcional
- [ ] **Email:** Verificar email na caixa de entrada
- [ ] **Ação:** Clicar no link de verificação

**Resultado Esperado:**
- [ ] Email verificado no Firebase Auth
- [ ] Redirecionamento automático para Home
- [ ] Acesso completo ao app

---

### 🔗 Fluxo B: Login Social + Complemento

#### Pré-condições
- [ ] App instalado e funcionando
- [ ] Conta Google/Apple/Facebook disponível
- [ ] Firebase configurado para login social

#### Login Social
- [ ] **Acessar:** Tela de login
- [ ] **Ação:** Clicar em "Entrar com Google" (ou Apple/Facebook)
- [ ] **Autenticação:** Completar login social

**Resultado Esperado:**
- [ ] Login bem-sucedido
- [ ] Navegação para Home
- [ ] Banner "Complete seu cadastro (0/3)" visível
- [ ] Usuário criado com `completedFullRegistration: false`

#### Banner de Cadastro Incompleto
- [ ] **Visualização:** Banner na Home
- [ ] **Texto:** "Complete seu cadastro (0/3)"
- [ ] **CTA:** "Completar agora"
- [ ] **Ação:** Clicar em "Completar agora"

**Resultado Esperado:**
- [ ] Navegação para Passo 1 do cadastro

#### Passo 1: Dados de Contato (Social)
- [ ] **Email:** Campo travado com email do login social
- [ ] **CNPJ:** Inserir CNPJ válido não cadastrado
- [ ] **Nome do Bar:** Inserir nome válido
- [ ] **Responsável:** Inserir nome válido
- [ ] **Telefone:** Inserir telefone válido
- [ ] **Validação:** Botão "Continuar" deve estar habilitado
- [ ] **Ação:** Clicar em "Continuar"

**Resultado Esperado:**
- [ ] Email não validado (já autenticado)
- [ ] CNPJ validado via `checkCnpjExists` (usuário autenticado)
- [ ] Navegação para Passo 2

#### Passo 2: Endereço (Social)
- [ ] **Mesmo fluxo do cadastro completo**

#### Passo 3: Senha (Social)
- [ ] **Senha:** Inserir senha válida
- [ ] **Confirmar Senha:** Inserir mesma senha
- [ ] **Ação:** Clicar em "Finalizar cadastro"

**Resultado Esperado:**
- [ ] Dados salvos no Firestore
- [ ] `completedFullRegistration: true`
- [ ] Navegação para Home
- [ ] Banner removido
- [ ] Acesso completo ao app

---

## 🚨 Testes de Validação e Erro

### Validações de Email
- [ ] **Email inválido:** Formato incorreto deve mostrar erro
- [ ] **Email existente:** "E-mail já cadastrado, faça login"
- [ ] **Email vazio:** Campo obrigatório

### Validações de CNPJ
- [ ] **CNPJ inválido:** Formato incorreto deve mostrar erro
- [ ] **CNPJ existente:** "Este CNPJ já está cadastrado por outro usuário" (ambos os fluxos)
- [ ] **CNPJ vazio:** Campo obrigatório

### Validações de Campos
- [ ] **Nome do bar vazio:** Campo obrigatório
- [ ] **Responsável vazio:** Campo obrigatório
- [ ] **Telefone inválido:** Formato incorreto
- [ ] **CEP inválido:** Formato incorreto ou não encontrado
- [ ] **Senha fraca:** Menos de 8 caracteres
- [ ] **Senhas diferentes:** Confirmação não confere

### Estados de Loading
- [ ] **Botão desabilitado:** Durante validações
- [ ] **Spinner visível:** Durante processamento
- [ ] **Duplo-clique:** Prevenido durante validação

---

## 🔄 Testes de Fluxo Completo

### Cenário 1: Cadastro Completo → Login
1. [ ] Completar cadastro via email/senha
2. [ ] Verificar email
3. [ ] Fazer logout
4. [ ] Fazer login com mesmas credenciais
5. [ ] Verificar acesso direto à Home (sem banner)

### Cenário 2: Login Social → Complemento → Logout → Login
1. [ ] Login social
2. [ ] Completar cadastro
3. [ ] Fazer logout
4. [ ] Fazer login social novamente
5. [ ] Verificar acesso direto à Home (sem banner)

### Cenário 3: Tentativa de Cadastro com Dados Existentes
1. [ ] Tentar cadastro com email já usado
2. [ ] Verificar mensagem de erro apropriada
3. [ ] Tentar login social + CNPJ já usado
4. [ ] Verificar mensagem de erro apropriada

### Cenário 4: Operação Atômica (Step3 Social)
1. [ ] Login social + completar Passo 1 e 2
2. [ ] No Passo 3, verificar que operação é atômica
3. [ ] Interromper conexão durante finalização (teste de falha)
4. [ ] Verificar que nenhum dado parcial foi salvo
5. [ ] Tentar novamente com conexão estável
6. [ ] Verificar que todos os dados são criados juntos:
   - [ ] CNPJ Registry criado
   - [ ] Bar Document criado
   - [ ] Membership OWNER criado
   - [ ] User Profile atualizado
7. [ ] Tentar executar novamente (teste de idempotência)
8. [ ] Verificar que operação não duplica dados

---

## 📱 Testes de Plataforma

### iOS
- [ ] Todos os fluxos funcionam corretamente
- [ ] Login com Apple funcional
- [ ] Navegação suave
- [ ] Validações em tempo real

### Android
- [ ] Todos os fluxos funcionam corretamente
- [ ] Login com Google funcional
- [ ] Navegação suave
- [ ] Validações em tempo real

---

## 🐛 Problemas Conhecidos para Verificar

### Resolvidos
- [ ] **Permissões Firestore:** Usuários recém-criados conseguem salvar dados
- [ ] **Validação de Email:** `fetchSignInMethodsForEmail` funcionando
- [ ] **Fluxos Separados:** Validações corretas por tipo de fluxo

### Para Monitorar
- [ ] **Performance:** Validações não demoram mais que 3 segundos
- [ ] **Debounce:** Múltiplos cliques não causam problemas
- [ ] **Conectividade:** Comportamento offline/online

---

## ✅ Critérios de Aceitação

### Funcionalidade
- [ ] Ambos os fluxos completam sem erros
- [ ] Validações funcionam corretamente
- [ ] Dados são salvos no Firestore
- [ ] Navegação é intuitiva

### Performance
- [ ] Validações respondem em até 3 segundos
- [ ] App não trava durante processamento
- [ ] Transições são suaves

### UX
- [ ] Mensagens de erro são claras
- [ ] Estados de loading são visíveis
- [ ] Banner aparece/desaparece corretamente

### Segurança
- [ ] Firestore rules impedem acesso não autorizado
- [ ] Validações server-side funcionam
- [ ] Dados sensíveis não são expostos

---

## 📝 Relatório de Testes

**Data do Teste:** ___________  
**Testador:** ___________  
**Versão do App:** ___________  
**Plataforma:** [ ] iOS [ ] Android

### Resumo
- **Testes Executados:** _____ / _____
- **Testes Aprovados:** _____ / _____
- **Bugs Encontrados:** _____

### Observações
_Espaço para anotações sobre problemas encontrados ou melhorias sugeridas_

---

**📋 Este checklist deve ser executado sempre após mudanças nos fluxos de cadastro ou autenticação.**