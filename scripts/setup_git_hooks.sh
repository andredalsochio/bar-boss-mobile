#!/bin/bash

# Script para configurar hooks do Git para o projeto Bar Boss

set -e

echo "🔧 Configurando hooks do Git para Bar Boss..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se estamos no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erro: Execute este script no diretório raiz do projeto Flutter${NC}"
    exit 1
fi

# Verificar se é um repositório Git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Erro: Este não é um repositório Git${NC}"
    exit 1
fi

echo -e "${BLUE}1. Configurando diretório de hooks...${NC}"

# Configurar o diretório de hooks do Git
if git config core.hooksPath .githooks; then
    echo -e "${GREEN}✅ Diretório de hooks configurado para .githooks${NC}"
else
    echo -e "${RED}❌ Falha ao configurar diretório de hooks${NC}"
    exit 1
fi

echo -e "${BLUE}2. Verificando hooks disponíveis...${NC}"

# Listar hooks disponíveis
if [ -d ".githooks" ]; then
    HOOKS=$(find .githooks -type f -executable | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ $HOOKS hook(s) encontrado(s):${NC}"
    find .githooks -type f -executable | while read -r hook; do
        echo "  $(basename "$hook")"
    done
else
    echo -e "${YELLOW}⚠️  Diretório .githooks não encontrado${NC}"
fi

echo -e "${BLUE}3. Testando hook de pré-commit...${NC}"

# Testar se o hook de pré-commit funciona
if [ -f ".githooks/pre-commit" ] && [ -x ".githooks/pre-commit" ]; then
    echo -e "${GREEN}✅ Hook de pré-commit está executável${NC}"
    echo "  Para testar manualmente: ./.githooks/pre-commit"
else
    echo -e "${RED}❌ Hook de pré-commit não encontrado ou não executável${NC}"
fi

echo -e "${BLUE}4. Verificando scripts auxiliares...${NC}"

# Verificar scripts auxiliares
if [ -f "scripts/check_custom_lints.sh" ] && [ -x "scripts/check_custom_lints.sh" ]; then
    echo -e "${GREEN}✅ Script de lints customizados está disponível${NC}"
else
    echo -e "${YELLOW}⚠️  Script de lints customizados não encontrado ou não executável${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Configuração de hooks concluída!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "  1. Os hooks serão executados automaticamente nos commits"
echo "  2. Para testar manualmente: ./scripts/check_custom_lints.sh"
echo "  3. Para desabilitar temporariamente: git commit --no-verify"
echo ""
echo "💡 Dicas:"
echo "  - Execute 'dart format lib/ test/' antes de fazer commit"
echo "  - Execute 'flutter analyze' para verificar problemas"
echo "  - Use 'flutter packages pub run build_runner build' após mudanças em modelos"
echo ""