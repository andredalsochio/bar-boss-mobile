#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const { Command } = require('commander');
const chalk = require('chalk');

const program = new Command();

program
  .name('rules-generator')
  .description('Gera regras do Firestore a partir do schema.json')
  .option('-s, --schema <file>', 'Arquivo de schema', 'schema.json')
  .option('-o, --output <file>', 'Arquivo de saída', '../firestore.rules')
  .option('--dry-run', 'Apenas exibe as regras sem salvar')
  .parse();

const options = program.opts();

/**
 * Gera validação de campo baseada no schema
 */
function generateFieldValidation(fieldName, fieldSchema, indent = '        ') {
  const validations = [];
  
  // Campo obrigatório
  if (fieldSchema.required) {
    validations.push(`${indent}${fieldName} is string && ${fieldName}.size() > 0`);
  }
  
  // Validação de tipo
  switch (fieldSchema.type) {
    case 'string':
      if (fieldSchema.minLength) {
        validations.push(`${indent}${fieldName} is string && ${fieldName}.size() >= ${fieldSchema.minLength}`);
      }
      if (fieldSchema.maxLength) {
        validations.push(`${indent}${fieldName} is string && ${fieldName}.size() <= ${fieldSchema.maxLength}`);
      }
      if (fieldSchema.pattern) {
        // Firestore rules não suportam regex complexo, então apenas validamos que é string
        validations.push(`${indent}${fieldName} is string`);
      }
      if (fieldSchema.enum) {
        const enumValues = fieldSchema.enum.map(v => `'${v}'`).join(', ');
        validations.push(`${indent}${fieldName} in [${enumValues}]`);
      }
      break;
      
    case 'number':
      validations.push(`${indent}${fieldName} is number`);
      if (fieldSchema.minimum !== undefined) {
        validations.push(`${indent}${fieldName} >= ${fieldSchema.minimum}`);
      }
      if (fieldSchema.maximum !== undefined) {
        validations.push(`${indent}${fieldName} <= ${fieldSchema.maximum}`);
      }
      break;
      
    case 'boolean':
      validations.push(`${indent}${fieldName} is bool`);
      break;
      
    case 'object':
      if (fieldName === 'createdAt' || fieldName === 'updatedAt') {
        validations.push(`${indent}${fieldName} is timestamp`);
      } else {
        validations.push(`${indent}${fieldName} is map`);
      }
      break;
      
    case 'array':
      validations.push(`${indent}${fieldName} is list`);
      if (fieldSchema.maxItems) {
        validations.push(`${indent}${fieldName}.size() <= ${fieldSchema.maxItems}`);
      }
      break;
  }
  
  return validations;
}

/**
 * Gera função de validação para um schema de documento
 */
function generateDocumentValidation(collectionName, schema) {
  const functionName = `validate${collectionName.charAt(0).toUpperCase() + collectionName.slice(1).replace(/s$/, '')}`;
  
  let validation = `  function ${functionName}(data) {\n`;
  validation += `    return data.keys().hasAll(['uid']) &&\n`;
  
  const validations = [];
  
  // Validações de campos obrigatórios
  const requiredFields = [];
  if (schema.required) {
    requiredFields.push(...schema.required);
  }
  
  if (requiredFields.length > 0) {
    const requiredList = requiredFields.map(f => `'${f}'`).join(', ');
    validations.push(`      data.keys().hasAll([${requiredList}])`);
  }
  
  // Validações de campos específicos
  if (schema.properties) {
    Object.entries(schema.properties).forEach(([fieldName, fieldSchema]) => {
      const fieldValidations = generateFieldValidation(fieldName, fieldSchema, '      ');
      validations.push(...fieldValidations.map(v => v.replace(`      ${fieldName}`, `      data.${fieldName}`)));
    });
  }
  
  // Validações customizadas
  if (collectionName === 'events') {
    validations.push(`      (!('endAt' in data) || data.endAt >= data.startAt)`);
    validations.push(`      data.published is bool`);
  }
  
  if (collectionName === 'bars') {
    validations.push(`      data.status in ['ACTIVE', 'INACTIVE', 'PENDING']`);
  }
  
  validation += validations.join(' &&\n');
  validation += `;\n  }\n\n`;
  
  return validation;
}

/**
 * Gera as regras do Firestore
 */
function generateFirestoreRules(schema) {
  let rules = `rules_version = '2';\n\n`;
  rules += `service cloud.firestore {\n`;
  rules += `  match /databases/{database}/documents {\n\n`;
  
  // Funções de validação
  rules += `  // Funções de validação\n`;
  
  // Função para verificar se o usuário é membro do bar
  rules += `  function isBarMember(barId, uid) {\n`;
  rules += `    return exists(/databases/$(database)/documents/bars/$(barId)/members/$(uid));\n`;
  rules += `  }\n\n`;
  
  // Função para verificar se o usuário é owner do bar
  rules += `  function isBarOwner(barId, uid) {\n`;
  rules += `    return exists(/databases/$(database)/documents/bars/$(barId)/members/$(uid)) &&\n`;
  rules += `           get(/databases/$(database)/documents/bars/$(barId)/members/$(uid)).data.role == 'OWNER';\n`;
  rules += `  }\n\n`;
  
  // Função para verificar autenticação
  rules += `  function isAuthenticated() {\n`;
  rules += `    return request.auth != null;\n`;
  rules += `  }\n\n`;
  
  // Função para verificar se é o próprio usuário
  rules += `  function isOwner(uid) {\n`;
  rules += `    return request.auth.uid == uid;\n`;
  rules += `  }\n\n`;
  
  // Gerar funções de validação para cada coleção
  Object.entries(schema.collections).forEach(([collectionName, collectionSchema]) => {
    rules += generateDocumentValidation(collectionName, collectionSchema);
  });
  
  // Regras para coleção users
  rules += `  // Coleção users\n`;
  rules += `  match /users/{uid} {\n`;
  rules += `    allow read, write: if isAuthenticated() && isOwner(uid) && validateUser(request.resource.data);\n`;
  rules += `  }\n\n`;
  
  // Regras para coleção bars
  rules += `  // Coleção bars\n`;
  rules += `  match /bars/{barId} {\n`;
  rules += `    allow read: if isAuthenticated() && isBarMember(barId, request.auth.uid);\n`;
  rules += `    allow create: if isAuthenticated() && validateBar(request.resource.data);\n`;
  rules += `    allow update: if isAuthenticated() && isBarMember(barId, request.auth.uid) && validateBar(request.resource.data);\n`;
  rules += `    allow delete: if isAuthenticated() && isBarOwner(barId, request.auth.uid);\n\n`;
  
  // Subcoleção members
  rules += `    // Subcoleção members\n`;
  rules += `    match /members/{memberId} {\n`;
  rules += `      allow read: if isAuthenticated() && isBarMember(barId, request.auth.uid);\n`;
  rules += `      allow create: if isAuthenticated() && isBarOwner(barId, request.auth.uid) && validateMember(request.resource.data);\n`;
  rules += `      allow update: if isAuthenticated() && isBarOwner(barId, request.auth.uid) && validateMember(request.resource.data);\n`;
  rules += `      allow delete: if isAuthenticated() && isBarOwner(barId, request.auth.uid);\n`;
  rules += `    }\n\n`;
  
  // Subcoleção events
  rules += `    // Subcoleção events\n`;
  rules += `    match /events/{eventId} {\n`;
  rules += `      allow read: if isAuthenticated() && isBarMember(barId, request.auth.uid);\n`;
  rules += `      allow create: if isAuthenticated() && isBarMember(barId, request.auth.uid) && validateEvent(request.resource.data);\n`;
  rules += `      allow update: if isAuthenticated() && isBarMember(barId, request.auth.uid) && validateEvent(request.resource.data);\n`;
  rules += `      allow delete: if isAuthenticated() && isBarMember(barId, request.auth.uid);\n`;
  rules += `    }\n`;
  
  rules += `  }\n\n`;
  

  
  rules += `  }\n`;
  rules += `}\n`;
  
  return rules;
}

/**
 * Função principal
 */
async function main() {
  try {
    console.log(chalk.blue('🔧 Gerador de Regras do Firestore'));
    console.log();
    
    // Carregar schema
    const schemaPath = path.resolve(options.schema);
    if (!await fs.pathExists(schemaPath)) {
      console.error(chalk.red(`❌ Arquivo de schema não encontrado: ${schemaPath}`));
      process.exit(1);
    }
    
    console.log(chalk.gray(`📖 Carregando schema: ${schemaPath}`));
    const schema = await fs.readJson(schemaPath);
    
    // Gerar regras
    console.log(chalk.gray('⚙️  Gerando regras...'));
    const rules = generateFirestoreRules(schema);
    
    if (options.dryRun) {
      console.log(chalk.yellow('🔍 Modo dry-run - Regras geradas:'));
      console.log();
      console.log(rules);
      return;
    }
    
    // Salvar arquivo
    const outputPath = path.resolve(options.output);
    await fs.writeFile(outputPath, rules, 'utf8');
    
    console.log(chalk.green(`✅ Regras geradas com sucesso: ${outputPath}`));
    console.log();
    console.log(chalk.gray('📝 Próximos passos:'));
    console.log(chalk.gray('   1. Revisar as regras geradas'));
    console.log(chalk.gray('   2. Testar com Firebase Emulator'));
    console.log(chalk.gray('   3. Deploy: firebase deploy --only firestore:rules'));
    
  } catch (error) {
    console.error(chalk.red('❌ Erro ao gerar regras:'));
    console.error(error.message);
    if (error.stack) {
      console.error(chalk.gray(error.stack));
    }
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  generateFirestoreRules,
  generateDocumentValidation,
  generateFieldValidation
};