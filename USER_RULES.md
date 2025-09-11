# 👤 USER RULES - Bar Boss Mobile

**Versão:** 2.0  
**Última Atualização:** 10 de Setembro de 2025  
**Objetivo:** Diretrizes para interação com desenvolvedores e IA

---

Estas diretrizes devem ser seguidas em todas as interações com o desenvolvedor. Garantem que comunicação, código e decisões técnicas estejam alinhadas às preferências do projeto e ao ambiente.

---

## 🗣️ 1. Comunicação

### Idioma
- **Sempre responda em português do Brasil (pt-BR)**
- Documentação técnica em português
- Comentários de código em pt-BR quando necessário

### Tom
- **Linguagem clara e objetiva**
- Evitar jargões desnecessários
- Explicações diretas e práticas
- Foco na solução, não no problema

---

## 🏗️ 2. Arquitetura e Padrões

### Arquitetura Obrigatória
- **MVVM com Provider** (nativo do Flutter)
- **NÃO utilizar:** Redux, BLoC, Riverpod ou similares
- Manter consistência com padrão estabelecido

### Nomenclatura
- **Classes, métodos e variáveis:** Inglês (camelCase/PascalCase)
- **Arquivos:** snake_case.dart
- **Constantes:** UPPER_SNAKE_CASE

### Comentários
- **Incluir somente onde for crucial** para entendimento/manutenção
- **Idioma:** Português brasileiro
- Explicar lógicas complexas e decisões arquiteturais

---

## 📁 3. Estrutura e Organização

### Estrutura de Pastas
- **Respeitar a estrutura atual**
- Criar pastas adicionais apenas quando fizer sentido arquitetural
- Seguir padrão MVVM estabelecido

### Convenções
- **Seguir convenções oficiais** de Dart e Flutter
- Usar `const` sempre que possível
- Implementar lazy-loading quando apropriado
- Builders eficientes para listas

---

## 🔐 4. Segurança

### Autenticação
- **E-mail/senha:** Exigir verificação de e-mail
- **Login social:** Permitir acesso imediato com banner de completude
- **Nunca expor dados sensíveis** em logs

### Boas Práticas
- Validação no cliente E servidor
- Princípio do menor privilégio
- Conformidade com LGPD
- Tratamento seguro de dados pessoais

---

## ⚡ 5. Performance

### Otimizações Obrigatórias
- **const:** Usar sempre que possível
- **Builders eficientes:** ListView.builder, etc.
- **Lazy-load:** Carregar dados sob demanda
- **Cache local:** Implementar para dados frequentes

### Qualidade de Código
- **Código limpo e legível**
- Seguir princípios SOLID quando aplicável
- Tratamento apropriado de erros
- Logging sem dados sensíveis

---

## 🎨 6. UX/UI Específicas

### Banner de Cadastro Incompleto
**Regra crítica:** Após login social (Google/Apple/Facebook):
- Exibir banner na Home: "Complete seu cadastro (0/2)"
- CTA: "Completar agora" → navegar para `/cadastro/passo1`
- **NÃO exibir** após cadastro completo via "Não tem um bar?"

### Fluxo de Cadastro
- **Cadastro completo:** Passo 1 + Passo 2 + Passo 3 (criar senha)
- **Login social + complemento:** Passo 1 + Passo 2 (sem senha)
- Flags de completude devem estar corretas

### Criação de Eventos
- **Não bloquear** criação por perfil incompleto
- **Apenas avisar** quando necessário
- Manter funcionalidade acessível

---

## 💻 7. Ambiente e Plataforma

### Sistema do Usuário
- **macOS:** Comandos e scripts devem ser compatíveis
- Usar paths corretos para macOS
- Considerar diferenças de ambiente

### Plataformas de Destino
- **Flutter para iOS e Android**
- App responsivo e funcional em ambos
- Testes em ambas as plataformas

---

## 🤖 8. Diretrizes para IA

### Comandos Proibidos
- **NUNCA executar `flutter run`** sem solicitação explícita
- **NUNCA modificar `pubspec.yaml`** sem aprovação
- **NUNCA alterar regras do Firestore** sem validação

### Fluxo Obrigatório
1. **Sempre consultar primeiro** o contexto atual (`.trae/context`, `PROJECT_RULES.md`)
2. **Documentação oficial:** Firebase, Flutter, Dart
3. **Respeitar arquitetura** MVVM + Provider
4. **Atualizar documentação** após implementações

### Manutenibilidade
- **Lógicas complexas:** Adicionar comentários em pt-BR
- Explicar decisões arquiteturais
- Documentar padrões utilizados
- Manter consistência com código existente

---

## 📋 9. Checklist de Implementação

Antes de qualquer implementação, verificar:

- [ ] Consultou `PROJECT_RULES.md`?
- [ ] Respeitou arquitetura MVVM + Provider?
- [ ] Nomenclatura em inglês para código?
- [ ] Comentários em pt-BR apenas quando necessário?
- [ ] Seguiu convenções do Flutter/Dart?
- [ ] Implementou tratamento de erros?
- [ ] Considerou performance (const, lazy-load)?
- [ ] Testou em iOS e Android?
- [ ] Atualizou documentação relevante?

---

## 🔄 10. Atualizações

### Manutenção do Documento
- Atualizar após mudanças significativas no projeto
- Manter sincronizado com `PROJECT_RULES.md`
- Versionar mudanças importantes

### Feedback
- Documento vivo, sujeito a melhorias
- Ajustes baseados na experiência de desenvolvimento
- Manter foco na produtividade e qualidade

---

**🔁 Consulte este documento sempre que necessário para manter consistência e atender expectativas do projeto.**

**📝 Nota:** Para regras técnicas detalhadas, consulte [PROJECT_RULES.md](./PROJECT_RULES.md)