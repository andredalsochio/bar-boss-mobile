#!/bin/bash

# Script de verificação de lints customizados para Bar Boss
# Verifica padrões específicos do projeto que não são cobertos pelo dart analyze

set -e

echo "🔍 Verificando lints customizados do Bar Boss..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
ERRORS=0
WARNINGS=0

# Função para reportar erro
report_error() {
    echo -e "${RED}❌ ERRO:${NC} $1"
    ERRORS=$((ERRORS + 1))
}

# Função para reportar warning
report_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Função para reportar sucesso
report_success() {
    echo -e "${GREEN}✅${NC} $1"
}

echo -e "${BLUE}1. Verificando uso direto de collection() sem FSKeys...${NC}"

# Verificar uso direto de collection() sem FSKeys
DIRECT_COLLECTION=$(grep -r "collection('" lib/ --include="*.dart" | grep -v "FSKeys\|FirestoreKeys" || true)

if [ -n "$DIRECT_COLLECTION" ]; then
    report_error "Encontrado uso direto de collection() sem FSKeys:"
    echo "$DIRECT_COLLECTION" | while read -r line; do
        echo "  $line"
    done
    echo "  💡 Use FSKeys.* para referenciar coleções"
    echo ""
else
    report_success "Nenhum uso direto de collection() encontrado"
fi

echo -e "${BLUE}2. Verificando uso de .add() em repositórios...${NC}"

# Verificar uso de .add() em repositórios
ADD_IN_REPOS=$(grep -r "\.add(" lib/app/data/ --include="*.dart" || true)

if [ -n "$ADD_IN_REPOS" ]; then
    report_error "Encontrado uso de .add() em repositórios:"
    echo "$ADD_IN_REPOS" | while read -r line; do
        echo "  $line"
    done
    echo "  💡 Use .doc().set() ou métodos específicos do repositório"
    echo ""
else
    report_success "Nenhum uso de .add() em repositórios encontrado"
fi

echo -e "${BLUE}3. Verificando imports de FSKeys...${NC}"

# Verificar se repositórios importam FSKeys
REPO_FILES=$(find lib/app/data/ -name "*repository*.dart" -type f)

if [ -n "$REPO_FILES" ]; then
    for file in $REPO_FILES; do
        if ! grep -q "firestore_keys" "$file"; then
            report_warning "Repositório $file não importa firestore_keys"
        fi
    done
fi

echo -e "${BLUE}4. Verificando uso de FieldValue.serverTimestamp()...${NC}"

# Verificar se timestamps estão usando serverTimestamp
MANUAL_TIMESTAMPS=$(grep -r "DateTime.now()" lib/app/data/ --include="*.dart" | grep -v "test" || true)

if [ -n "$MANUAL_TIMESTAMPS" ]; then
    report_warning "Encontrado uso de DateTime.now() em repositórios:"
    echo "$MANUAL_TIMESTAMPS" | while read -r line; do
        echo "  $line"
    done
    echo "  💡 Use FieldValue.serverTimestamp() para timestamps do Firestore"
    echo ""
fi

echo -e "${BLUE}5. Verificando uso de batch/transaction para operações críticas...${NC}"

# Verificar se operações críticas usam batch/transaction
CRITICAL_OPS=$(grep -r "cnpj_registry" lib/app/data/ --include="*.dart" | grep -v "batch\|transaction" || true)

if [ -n "$CRITICAL_OPS" ]; then
    report_warning "Operações com cnpj_registry devem usar batch/transaction:"
    echo "$CRITICAL_OPS" | while read -r line; do
        echo "  $line"
    done
    echo ""
fi

echo -e "${BLUE}6. Verificando logs sensíveis...${NC}"

# Verificar se há logs com dados sensíveis (excluindo arquivos gerados)
# Procura por logs que realmente expõem valores, não apenas menções em comentários
SENSITIVE_LOGS=$(find lib/ -name "*.dart" ! -name "*.freezed.dart" ! -name "*.g.dart" -exec grep -H "print\|log\|debugPrint" {} \; | grep -v "//" | grep -E "\$.*password|\$.*email|\$.*token|\$.*secret|\$.*key|\$.*cnpj" 2>/dev/null || true)

if [ -n "$SENSITIVE_LOGS" ]; then
    report_error "Encontrados logs com possíveis dados sensíveis:"
    echo "$SENSITIVE_LOGS" | while read -r line; do
        echo "  $line"
    done
    echo "  💡 Remova ou sanitize dados sensíveis dos logs"
    echo ""
fi

echo -e "${BLUE}7. Verificando uso correto de withConverter...${NC}"

# Verificar se repositórios usam withConverter
WITHOUT_CONVERTER=$(grep -r "collection(" lib/app/data/ --include="*.dart" | grep -v "withConverter" || true)

if [ -n "$WITHOUT_CONVERTER" ]; then
    report_warning "Encontrado uso de collection() sem withConverter:"
    echo "$WITHOUT_CONVERTER" | while read -r line; do
        echo "  $line"
    done
    echo "  💡 Use sempre withConverter para type safety"
    echo ""
fi

echo ""
echo "📊 Resumo:"
echo -e "  Erros: ${RED}$ERRORS${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Verificação falhou com $ERRORS erro(s)${NC}"
    echo "Corrija os erros antes de fazer commit."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Verificação concluída com $WARNINGS warning(s)${NC}"
    echo "Considere corrigir os warnings para melhor qualidade do código."
    exit 0
else
    echo ""
    echo -e "${GREEN}✅ Todos os lints customizados passaram!${NC}"
    exit 0
fi