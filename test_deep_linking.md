# 🧪 Teste de Deep Linking - Bar Boss Mobile

**Data:** 17 de Janeiro de 2025  
**Objetivo:** Validar funcionamento do deep linking de verificação de email

---

## 📋 Checklist de Testes

### ✅ Pré-requisitos
- [ ] App instalado no dispositivo físico (iOS/Android)
- [ ] Firebase Dynamic Links configurado no console
- [ ] Domínio `barboss.page.link` ativo
- [ ] Email de teste válido

---

## 🔧 Cenários de Teste

### 1. Cold Start (App Fechado)
**Objetivo:** Verificar se o app abre e navega corretamente quando está fechado

**Passos:**
1. Feche completamente o app (force quit)
2. Cadastre um novo usuário com email válido
3. Acesse o email de verificação
4. Toque no link de verificação
5. Aguarde o app abrir

**Resultado Esperado:**
- [ ] App abre automaticamente
- [ ] Navega para `/login`
- [ ] Exibe mensagem "E-mail verificado com sucesso!"
- [ ] Usuário pode fazer login normalmente

**Status:** ⏳ Pendente

---

### 2. Background (App em Background)
**Objetivo:** Verificar comportamento quando app está em background

**Passos:**
1. Abra o app
2. Minimize (home button/gesture)
3. Acesse email de verificação
4. Toque no link
5. Observe comportamento

**Resultado Esperado:**
- [ ] App volta para foreground
- [ ] Navega para `/login`
- [ ] Exibe mensagem de sucesso
- [ ] Estado anterior é preservado

**Status:** ⏳ Pendente

---

### 3. Foreground (App Aberto)
**Objetivo:** Verificar comportamento quando app está ativo

**Passos:**
1. Mantenha app aberto
2. Em outro dispositivo/browser, acesse email
3. Toque no link de verificação
4. Observe comportamento no app

**Resultado Esperado:**
- [ ] App detecta o deep link
- [ ] Navega para `/login`
- [ ] Exibe mensagem de sucesso
- [ ] Não há conflitos de navegação

**Status:** ⏳ Pendente

---

## 📱 Teste por Plataforma

### iOS 18
**Dispositivo:** iPhone (físico recomendado)

#### Cold Start
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

#### Background
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

#### Foreground
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

---

### Android 14
**Dispositivo:** Android (físico recomendado)

#### Cold Start
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

#### Background
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

#### Foreground
- [ ] ✅ Sucesso
- [ ] ❌ Falha
- [ ] ⚠️ Parcial

**Observações:**
```
[Anotar comportamento observado]
```

---

## 🔍 Debug e Logs

### Comandos Úteis
```bash
# iOS - Visualizar logs do dispositivo
xcrun simctl spawn booted log stream --predicate 'subsystem contains "com.barboss.mobile"'

# Android - Visualizar logs
adb logcat | grep -i "barboss\|dynamic\|deeplink"

# Flutter - Logs do app
flutter logs
```

### Logs Esperados
```
🔗 [DynamicLinksService] Inicializando listeners...
🔗 [DynamicLinksService] Link recebido: https://barboss.page.link/emailVerification?oobCode=...
📧 [DynamicLinksService] Processando link de verificação de email
📧 [DynamicLinksService] OobCode encontrado: ABC123...
✅ [DynamicLinksService] Navegando para /login
✅ [DynamicLinksService] Exibindo feedback de sucesso
```

---

## 🚨 Problemas Conhecidos

### Link abre no navegador
**Causa:** Configuração incorreta de App Links/Universal Links
**Solução:** Verificar AndroidManifest.xml e Info.plist

### App abre mas não navega
**Causa:** DynamicLinksService não inicializado ou erro no parsing
**Solução:** Verificar logs e inicialização no app_widget.dart

### Mensagem não aparece
**Causa:** Contexto não disponível para SnackBar
**Solução:** Verificar se há Navigator ativo

---

## 📊 Relatório de Resultados

### Resumo Geral
- **iOS Cold Start:** ⏳ Pendente
- **iOS Background:** ⏳ Pendente  
- **iOS Foreground:** ⏳ Pendente
- **Android Cold Start:** ⏳ Pendente
- **Android Background:** ⏳ Pendente
- **Android Foreground:** ⏳ Pendente

### Taxa de Sucesso
- **iOS:** 0/3 (0%)
- **Android:** 0/3 (0%)
- **Geral:** 0/6 (0%)

### Próximos Passos
1. [ ] Executar testes em dispositivos físicos
2. [ ] Corrigir problemas identificados
3. [ ] Re-testar cenários que falharam
4. [ ] Documentar soluções aplicadas

---

## 🔄 Histórico de Testes

### 17/01/2025 - Implementação Inicial
- ✅ Configuração básica implementada
- ✅ DynamicLinksService criado
- ✅ Android App Links configurado
- ✅ iOS Universal Links configurado
- ⏳ Testes pendentes

---

**📝 Nota:** Atualizar este documento após cada rodada de testes com os resultados observados.