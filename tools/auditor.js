#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs-extra');
const path = require('path');
const { Command } = require('commander');
const chalk = require('chalk');
const ora = require('ora');

// Configuração do CLI
const program = new Command();
program
  .name('firestore-auditor')
  .description('Auditor CLI para validar consistência entre schemas e dados do Firestore')
  .version('1.0.0')
  .option('-f, --fix', 'Aplicar correções automáticas quando possível')
  .option('-r, --report-only', 'Apenas gerar relatório sem correções')
  .option('-o, --output <file>', 'Arquivo de saída para o relatório', 'audit-report.json')
  .option('-c, --config <file>', 'Arquivo de configuração do Firebase', '../firebase-config.json')
  .option('-s, --schema <file>', 'Arquivo de schema', './schema.json')
  .option('--limit <number>', 'Limitar número de documentos por coleção', '1000')
  .parse();

const options = program.opts();

// Classe principal do auditor
class FirestoreAuditor {
  constructor() {
    this.schema = null;
    this.db = null;
    this.issues = [];
    this.stats = {
      totalDocuments: 0,
      validDocuments: 0,
      invalidDocuments: 0,
      fixedDocuments: 0,
      collections: {}
    };
  }

  async initialize() {
    const spinner = ora('Inicializando auditor...').start();
    
    try {
      // Carregar schema
      const schemaPath = path.resolve(__dirname, options.schema);
      this.schema = await fs.readJson(schemaPath);
      spinner.text = 'Schema carregado';

      // Inicializar Firebase Admin
      if (!admin.apps.length) {
        const serviceAccountPath = path.resolve(__dirname, options.config);
        
        if (await fs.pathExists(serviceAccountPath)) {
          const serviceAccount = await fs.readJson(serviceAccountPath);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
          });
        } else {
          // Tentar usar credenciais padrão do ambiente
          admin.initializeApp();
        }
      }
      
      this.db = admin.firestore();
      spinner.succeed('Auditor inicializado com sucesso');
      
    } catch (error) {
      spinner.fail(`Erro ao inicializar: ${error.message}`);
      throw error;
    }
  }

  async auditCollection(collectionName, collectionSchema) {
    const spinner = ora(`Auditando coleção ${collectionName}...`).start();
    
    try {
      const limit = parseInt(options.limit);
      let query = this.db.collection(collectionName);
      
      if (limit > 0) {
        query = query.limit(limit);
      }
      
      const snapshot = await query.get();
      const docs = snapshot.docs;
      
      this.stats.collections[collectionName] = {
        total: docs.length,
        valid: 0,
        invalid: 0,
        fixed: 0
      };
      
      spinner.text = `Processando ${docs.length} documentos de ${collectionName}`;
      
      for (const doc of docs) {
        await this.auditDocument(collectionName, doc, collectionSchema);
      }
      
      const stats = this.stats.collections[collectionName];
      spinner.succeed(
        `${collectionName}: ${stats.valid} válidos, ${stats.invalid} inválidos` +
        (options.fix ? `, ${stats.fixed} corrigidos` : '')
      );
      
    } catch (error) {
      spinner.fail(`Erro ao auditar ${collectionName}: ${error.message}`);
      throw error;
    }
  }

  async auditSubcollection(parentPath, subcollectionName, subcollectionSchema) {
    const spinner = ora(`Auditando subcoleção ${parentPath}/${subcollectionName}...`).start();
    
    try {
      // Para subcoleções, precisamos iterar pelos documentos pai
      const parentCollection = parentPath.split('/')[0];
      const parentSnapshot = await this.db.collection(parentCollection).get();
      
      let totalDocs = 0;
      
      for (const parentDoc of parentSnapshot.docs) {
        const subcollectionRef = parentDoc.ref.collection(subcollectionName);
        const subcollectionSnapshot = await subcollectionRef.get();
        
        for (const doc of subcollectionSnapshot.docs) {
          await this.auditDocument(
            `${parentPath}/${subcollectionName}`,
            doc,
            subcollectionSchema,
            { parentId: parentDoc.id }
          );
          totalDocs++;
        }
      }
      
      spinner.succeed(`${parentPath}/${subcollectionName}: ${totalDocs} documentos processados`);
      
    } catch (error) {
      spinner.fail(`Erro ao auditar ${parentPath}/${subcollectionName}: ${error.message}`);
      throw error;
    }
  }

  async auditDocument(collectionPath, doc, schema, context = {}) {
    const data = doc.data();
    const docPath = `${collectionPath}/${doc.id}`;
    const issues = [];
    
    this.stats.totalDocuments++;
    
    // Verificar campos obrigatórios
    for (const requiredField of schema.required || []) {
      if (!(requiredField in data)) {
        issues.push({
          type: 'missing_required_field',
          field: requiredField,
          severity: 'error'
        });
      }
    }
    
    // Verificar tipos e validações
    for (const [fieldName, fieldSchema] of Object.entries(schema.properties || {})) {
      if (fieldName in data) {
        const fieldIssues = this.validateField(fieldName, data[fieldName], fieldSchema);
        issues.push(...fieldIssues);
      }
    }
    
    // Verificar campos desconhecidos
    const knownFields = Object.keys(schema.properties || {});
    for (const fieldName of Object.keys(data)) {
      if (!knownFields.includes(fieldName)) {
        issues.push({
          type: 'unknown_field',
          field: fieldName,
          severity: 'warning'
        });
      }
    }
    
    // Validações customizadas
    if (schema.customValidations) {
      for (const [validationName, validation] of Object.entries(schema.customValidations)) {
        const customIssues = this.validateCustomRule(data, validation, validationName);
        issues.push(...customIssues);
      }
    }
    
    // Registrar issues
    if (issues.length > 0) {
      this.issues.push({
        document: docPath,
        documentId: doc.id,
        collection: collectionPath,
        issues,
        data: this.sanitizeData(data),
        context
      });
      
      this.stats.invalidDocuments++;
      if (this.stats.collections[collectionPath.split('/')[0]]) {
        this.stats.collections[collectionPath.split('/')[0]].invalid++;
      }
      
      // Aplicar correções se solicitado
      if (options.fix && !options.reportOnly) {
        await this.fixDocument(doc, issues, schema);
      }
    } else {
      this.stats.validDocuments++;
      if (this.stats.collections[collectionPath.split('/')[0]]) {
        this.stats.collections[collectionPath.split('/')[0]].valid++;
      }
    }
  }

  validateField(fieldName, value, fieldSchema) {
    const issues = [];
    
    // Validação de tipo
    if (fieldSchema.type) {
      if (!this.isValidType(value, fieldSchema.type)) {
        issues.push({
          type: 'invalid_type',
          field: fieldName,
          expected: fieldSchema.type,
          actual: typeof value,
          severity: 'error'
        });
      }
    }
    
    // Validações específicas por tipo
    if (fieldSchema.type === 'string') {
      if (fieldSchema.minLength && value.length < fieldSchema.minLength) {
        issues.push({
          type: 'min_length_violation',
          field: fieldName,
          minLength: fieldSchema.minLength,
          actualLength: value.length,
          severity: 'error'
        });
      }
      
      if (fieldSchema.maxLength && value.length > fieldSchema.maxLength) {
        issues.push({
          type: 'max_length_violation',
          field: fieldName,
          maxLength: fieldSchema.maxLength,
          actualLength: value.length,
          severity: 'error'
        });
      }
      
      if (fieldSchema.pattern && !new RegExp(fieldSchema.pattern).test(value)) {
        issues.push({
          type: 'pattern_violation',
          field: fieldName,
          pattern: fieldSchema.pattern,
          value: value,
          severity: 'error'
        });
      }
      
      if (fieldSchema.enum && !fieldSchema.enum.includes(value)) {
        issues.push({
          type: 'enum_violation',
          field: fieldName,
          allowedValues: fieldSchema.enum,
          actualValue: value,
          severity: 'error'
        });
      }
    }
    
    // Validação de objetos aninhados
    if (fieldSchema.type === 'object' && fieldSchema.properties) {
      for (const [nestedField, nestedSchema] of Object.entries(fieldSchema.properties)) {
        if (nestedField in value) {
          const nestedIssues = this.validateField(
            `${fieldName}.${nestedField}`,
            value[nestedField],
            nestedSchema
          );
          issues.push(...nestedIssues);
        } else if (fieldSchema.required && fieldSchema.required.includes(nestedField)) {
          issues.push({
            type: 'missing_required_field',
            field: `${fieldName}.${nestedField}`,
            severity: 'error'
          });
        }
      }
    }
    
    return issues;
  }

  validateCustomRule(data, validation, ruleName) {
    const issues = [];
    
    // Validação específica para endAt >= startAt
    if (ruleName === 'endAtAfterStartAt') {
      if (data.endAt && data.startAt) {
        const startAt = data.startAt.toDate ? data.startAt.toDate() : new Date(data.startAt);
        const endAt = data.endAt.toDate ? data.endAt.toDate() : new Date(data.endAt);
        
        if (endAt < startAt) {
          issues.push({
            type: 'custom_validation_failed',
            rule: ruleName,
            description: validation.description,
            severity: 'error'
          });
        }
      }
    }
    
    return issues;
  }

  isValidType(value, expectedType) {
    switch (expectedType) {
      case 'string':
        return typeof value === 'string';
      case 'number':
        return typeof value === 'number';
      case 'boolean':
        return typeof value === 'boolean';
      case 'array':
        return Array.isArray(value);
      case 'object':
        return typeof value === 'object' && value !== null && !Array.isArray(value);
      case 'timestamp':
        return value && typeof value.toDate === 'function'; // Firestore Timestamp
      default:
        return true;
    }
  }

  async fixDocument(doc, issues, schema) {
    const fixes = {};
    let hasChanges = false;
    
    for (const issue of issues) {
      if (issue.type === 'missing_required_field') {
        const fieldSchema = schema.properties[issue.field];
        if (fieldSchema && fieldSchema.default !== undefined) {
          fixes[issue.field] = fieldSchema.default;
          hasChanges = true;
        }
      }
    }
    
    if (hasChanges) {
      try {
        await doc.ref.update(fixes);
        this.stats.fixedDocuments++;
        
        const collectionName = doc.ref.parent.id;
        if (this.stats.collections[collectionName]) {
          this.stats.collections[collectionName].fixed++;
        }
        
        console.log(chalk.green(`✓ Corrigido ${doc.ref.path}`));
      } catch (error) {
        console.log(chalk.red(`✗ Erro ao corrigir ${doc.ref.path}: ${error.message}`));
      }
    }
  }

  sanitizeData(data) {
    // Remove dados sensíveis do relatório
    const sanitized = { ...data };
    const sensitiveFields = ['password', 'token', 'secret', 'key'];
    
    for (const field of sensitiveFields) {
      if (field in sanitized) {
        sanitized[field] = '[REDACTED]';
      }
    }
    
    return sanitized;
  }

  async generateReport() {
    const report = {
      timestamp: new Date().toISOString(),
      schema: {
        version: this.schema.version,
        title: this.schema.title
      },
      options: {
        fix: options.fix,
        reportOnly: options.reportOnly,
        limit: options.limit
      },
      statistics: this.stats,
      issues: this.issues,
      summary: {
        totalIssues: this.issues.length,
        errorCount: this.issues.reduce((count, issue) => 
          count + issue.issues.filter(i => i.severity === 'error').length, 0),
        warningCount: this.issues.reduce((count, issue) => 
          count + issue.issues.filter(i => i.severity === 'warning').length, 0)
      }
    };
    
    const outputPath = path.resolve(__dirname, options.output);
    await fs.writeJson(outputPath, report, { spaces: 2 });
    
    console.log(chalk.blue(`\n📊 Relatório salvo em: ${outputPath}`));
    return report;
  }

  printSummary(report) {
    console.log(chalk.bold('\n🔍 RESUMO DA AUDITORIA'));
    console.log('═'.repeat(50));
    
    console.log(`📄 Documentos analisados: ${chalk.cyan(this.stats.totalDocuments)}`);
    console.log(`✅ Documentos válidos: ${chalk.green(this.stats.validDocuments)}`);
    console.log(`❌ Documentos inválidos: ${chalk.red(this.stats.invalidDocuments)}`);
    
    if (options.fix) {
      console.log(`🔧 Documentos corrigidos: ${chalk.yellow(this.stats.fixedDocuments)}`);
    }
    
    console.log(`\n🚨 Total de issues: ${chalk.red(report.summary.totalIssues)}`);
    console.log(`   Erros: ${chalk.red(report.summary.errorCount)}`);
    console.log(`   Avisos: ${chalk.yellow(report.summary.warningCount)}`);
    
    console.log('\n📊 Por coleção:');
    for (const [collection, stats] of Object.entries(this.stats.collections)) {
      console.log(`   ${collection}: ${stats.valid}✅ ${stats.invalid}❌` + 
        (options.fix ? ` ${stats.fixed}🔧` : ''));
    }
    
    if (report.summary.totalIssues > 0) {
      console.log(chalk.yellow(`\n💡 Execute com --fix para aplicar correções automáticas`));
    } else {
      console.log(chalk.green('\n🎉 Nenhum problema encontrado!'));
    }
  }

  async run() {
    try {
      await this.initialize();
      
      console.log(chalk.bold('\n🔍 INICIANDO AUDITORIA DO FIRESTORE'));
      console.log('═'.repeat(50));
      
      // Auditar coleções principais
      for (const [collectionName, collectionSchema] of Object.entries(this.schema.collections)) {
        if (collectionSchema.path.includes('{')) {
          // É uma subcoleção
          const pathParts = collectionSchema.path.split('/');
          if (pathParts.length === 4) { // bars/{barId}/events/{eventId}
            await this.auditSubcollection(
              pathParts.slice(0, 2).join('/'),
              pathParts[2],
              collectionSchema
            );
          }
        } else {
          // É uma coleção principal
          await this.auditCollection(collectionName, collectionSchema);
        }
      }
      
      const report = await this.generateReport();
      this.printSummary(report);
      
      // Exit code baseado nos resultados
      process.exit(report.summary.errorCount > 0 ? 1 : 0);
      
    } catch (error) {
      console.error(chalk.red(`\n💥 Erro fatal: ${error.message}`));
      console.error(error.stack);
      process.exit(1);
    }
  }
}

// Executar o auditor
if (require.main === module) {
  const auditor = new FirestoreAuditor();
  auditor.run();
}

module.exports = FirestoreAuditor;