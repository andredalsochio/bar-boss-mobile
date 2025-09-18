# 🔐 Firebase App Check - Configuração para Desenvolvimento

**Versão:** 1.0  
**Data:** 15 de Setembro de 2025  
**Objetivo:** Resolver erro 403 "App attestation failed" durante desenvolvimento

---

## 🚨 Problema Identificado

Durante o desenvolvimento, o App Check está retornando erro 403:
```
Error returned from API. code: 403 body: App attestation failed.
```

**Causa:** O App Check está configurado para usar providers de debug, mas não há token de debug registrado no Firebase Console.

---

## ✅ Solução: Tokens de Debug Configurados

### 1. Tokens Registrados ✅

Os tokens de debug já foram capturados e registrados no Firebase Console:

**Android:** `15EDC4BE-A24D-4326-9DEF-62FA56EBCAD8`  
**iOS:** `A7B9865E-685C-4FE4-B53C-D67B9C3836C4`

📁 **Localização:** `.env.debug` (arquivo criado para referência)

### 2. Status no Firebase Console ✅

Os tokens foram registrados em:
- Firebase Console > Project Settings > App Check > Apps > Manage debug tokens
- Data: 15 de Setembro de 2025
- Status: Ativos para desenvolvimento

### 3. Como Usar

Para desenvolvimento, simplesmente execute o app em modo debug:

```bash
flutter run --debug
```

Os tokens já estão configurados e o erro 403 deve estar resolvido.

### 4. Teste de Funcionamento

Para verificar se está funcionando corretamente:

1. Execute o app: `flutter run --debug`
2. Tente fazer um cadastro no Step3 (Finalizar cadastro)
3. **Resultado esperado:** Cadastro deve funcionar sem erro 403
4. **Se ainda houver erro:** Verifique se os tokens estão ativos no Firebase Console

---

## 🔧 Configuração Atual do App Check

O App Check está configurado em `lib/main.dart`:

```dart
// Ativar App Check com providers de debug
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
```

**⚠️ IMPORTANTE:** Esta configuração é apenas para desenvolvimento. Em produção, use:
- `AndroidProvider.playIntegrity` para Android
- `AppleProvider.deviceCheck` para iOS

---

## 🔍 Troubleshooting

### Token não aparece no console
- Certifique-se de que o app está executando em modo debug
- Tente fazer uma operação que acesse o Firestore (como o cadastro)
- Verifique se não há filtros no console que estejam ocultando a mensagem

### Token registrado mas ainda dá erro 403
- Aguarde alguns minutos para propagação
- Reinicie completamente o app
- Verifique se o token foi copiado corretamente (sem espaços extras)

### App funciona no simulador mas não no dispositivo físico
- Cada dispositivo/simulador gera um token único
- Registre tokens para todos os dispositivos de desenvolvimento

---

## 📚 Referências

- [Firebase App Check - Debug Provider](https://firebase.google.com/docs/app-check/flutter/debug-provider)
- [FlutterFire App Check Documentation](https://firebase.flutter.dev/docs/app-check/debug-provider/)
- [Troubleshooting App Check Issues](https://stackoverflow.com/questions/78171576/firebase-appcheck-error-403-app-attestation-failed)

---

## 🔄 Próximos Passos

1. **Desenvolvimento:** Registrar tokens de debug para todos os dispositivos de teste
2. **Staging:** Configurar providers apropriados para ambiente de teste
3. **Produção:** Usar providers de produção (Play Integrity, Device Check)

---

**📝 Nota:** Mantenha os tokens de debug privados e revogue-os se comprometidos.