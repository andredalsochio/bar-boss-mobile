# Firestore Auditor CLI

Ferramenta de auditoria para validar a consistência entre schemas definidos e dados reais no Firestore.

## Instalação

```bash
cd tools
npm install
```

## Configuração

### 1. Credenciais do Firebase

Crie um arquivo `firebase-config.json` com as credenciais da conta de serviço:

```json
{
  "type": "service_account",
  "project_id": "seu-projeto-id",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

Ou configure as variáveis de ambiente:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

### 2. Schema

O arquivo `schema.json` já está configurado com a estrutura do Bar Boss. Você pode modificá-lo conforme necessário.

## Uso

### Auditoria básica (apenas relatório)

```bash
npm run audit:firestore
```

### Auditoria com correções automáticas

```bash
npm run audit:firestore:fix
```

### Apenas gerar relatório

```bash
npm run audit:firestore:report
```

### Opções avançadas

```bash
# Limitar número de documentos por coleção
node auditor.js --limit 100

# Especificar arquivo de saída
node auditor.js --output meu-relatorio.json

# Usar schema customizado
node auditor.js --schema meu-schema.json

# Usar configuração customizada do Firebase
node auditor.js --config minha-config.json
```

## Funcionalidades

### ✅ Validações Implementadas

- **Campos obrigatórios**: Verifica se todos os campos required estão presentes
- **Tipos de dados**: Valida se os tipos correspondem ao schema
- **Campos desconhecidos**: Identifica campos não definidos no schema
- **Validações de string**: minLength, maxLength, pattern, enum
- **Objetos aninhados**: Valida estruturas complexas como address e profile
- **Validações customizadas**: Regras específicas como endAt >= startAt
- **Timestamps**: Verifica se são objetos Timestamp válidos do Firestore

### 🔧 Correções Automáticas

Quando executado com `--fix`, o auditor pode:

- Aplicar valores padrão para campos obrigatórios ausentes
- Corrigir tipos básicos quando possível
- Adicionar campos de profile com valores padrão

### 📊 Relatórios

O auditor gera relatórios detalhados em JSON contendo:

- Estatísticas gerais (total, válidos, inválidos, corrigidos)
- Lista de issues por documento
- Breakdown por coleção
- Resumo de erros vs avisos

## Estrutura do Relatório

```json
{
  "timestamp": "2025-01-15T10:30:00.000Z",
  "schema": {
    "version": "1.0.1",
    "title": "Bar Boss Firestore Schema"
  },
  "statistics": {
    "totalDocuments": 150,
    "validDocuments": 140,
    "invalidDocuments": 10,
    "fixedDocuments": 5,
    "collections": {
      "users": { "total": 50, "valid": 48, "invalid": 2, "fixed": 1 },
      "bars": { "total": 20, "valid": 18, "invalid": 2, "fixed": 1 }
    }
  },
  "issues": [
    {
      "document": "users/abc123",
      "collection": "users",
      "issues": [
        {
          "type": "missing_required_field",
          "field": "createdAt",
          "severity": "error"
        }
      ]
    }
  ],
  "summary": {
    "totalIssues": 15,
    "errorCount": 10,
    "warningCount": 5
  }
}
```

## Tipos de Issues

### Erros (severity: "error")
- `missing_required_field`: Campo obrigatório ausente
- `invalid_type`: Tipo de dado incorreto
- `min_length_violation`: String muito curta
- `max_length_violation`: String muito longa
- `pattern_violation`: String não atende ao padrão regex
- `enum_violation`: Valor não está na lista de valores permitidos
- `custom_validation_failed`: Falha em validação customizada

### Avisos (severity: "warning")
- `unknown_field`: Campo não definido no schema

## Integração com CI/CD

Adicione ao seu pipeline:

```yaml
# GitHub Actions
- name: Audit Firestore
  run: |
    cd tools
    npm install
    npm run audit:firestore
```

```yaml
# GitLab CI
audit_firestore:
  script:
    - cd tools
    - npm install
    - npm run audit:firestore
  artifacts:
    reports:
      junit: tools/audit-report.json
```

## Exit Codes

- `0`: Auditoria concluída sem erros
- `1`: Erros encontrados ou falha na execução

## Troubleshooting

### Erro de autenticação
```
Error: Could not load the default credentials
```
**Solução**: Configure as credenciais do Firebase corretamente.

### Limite de rate do Firestore
```
Error: 10 ABORTED: Too much contention on these documents
```
**Solução**: Use `--limit` para reduzir o número de documentos processados por vez.

### Schema inválido
```
Error: Schema validation failed
```
**Solução**: Verifique se o arquivo `schema.json` está bem formado.

## Desenvolvimento

Para contribuir com o auditor:

1. Modifique `auditor.js` conforme necessário
2. Atualize `schema.json` para refletir mudanças no modelo de dados
3. Teste com dados reais usando `--limit 10`
4. Documente novas validações neste README

## Roadmap

- [ ] Suporte a índices compostos
- [ ] Validação de referências entre documentos
- [ ] Métricas de performance
- [ ] Integração com Firebase Emulator
- [ ] Suporte a múltiplos projetos
- [ ] Dashboard web para visualização de relatórios