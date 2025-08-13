#!/bin/bash

# 🚀 Script de Configuração Inicial - Bar Boss Mobile
# Este script automatiza algumas etapas do setup inicial

set -e  # Parar execução se houver erro

echo "🔧 Iniciando configuração do Bar Boss Mobile..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se estamos no diretório correto
if [ ! -f "bar_boss_mobile/pubspec.yaml" ]; then
    print_error "Este script deve ser executado na raiz do projeto bar-boss-mobile"
    exit 1
fi

print_step "Verificando dependências..."

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    print_error "Flutter não encontrado. Instale o Flutter primeiro: https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter encontrado: $(flutter --version | head -n 1)"

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    print_warning "Firebase CLI não encontrado. Instalando..."
    npm install -g firebase-tools
else
    print_success "Firebase CLI encontrado"
fi

# Navegar para o diretório do Flutter
cd bar_boss_mobile

print_step "Instalando dependências do Flutter..."
flutter pub get

print_step "Verificando configuração do Flutter..."
flutter doctor

print_step "Configurando Firebase..."

# Verificar se o usuário está logado no Firebase
if ! firebase projects:list &> /dev/null; then
    print_warning "Você precisa fazer login no Firebase"
    firebase login
fi

# Configurar Firebase para Flutter
print_step "Configurando Firebase para Flutter..."
if command -v flutterfire &> /dev/null; then
    print_success "FlutterFire CLI encontrado"
else
    print_warning "Instalando FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

print_step "Criando arquivo .env..."
if [ ! -f "../.env" ]; then
    cp "../.env.example" "../.env"
    print_success "Arquivo .env criado a partir do .env.example"
    print_warning "IMPORTANTE: Edite o arquivo .env com suas chaves reais!"
else
    print_warning "Arquivo .env já existe"
fi

print_step "Verificando estrutura de pastas..."

# Criar estrutura de pastas se não existir
mkdir -p lib/app/core/{constants,utils,widgets}
mkdir -p lib/app/modules/{auth,register_bar,events}/{viewmodels,views}
mkdir -p lib/app/data/{models,repositories,datasources}
mkdir -p lib/app/services

print_success "Estrutura de pastas criada"

cd ..

echo ""
print_success "Configuração inicial concluída!"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "1. 🔐 Configure Firebase seguindo o SETUP_GUIDE.md"
echo "2. ✏️  Edite o arquivo .env com suas chaves reais"
echo "3. 🔧 Execute: cd bar_boss_mobile && flutterfire configure"
echo "4. 📱 Teste: flutter run"
echo ""
echo -e "${BLUE}📖 Documentação:${NC}"
echo "- SETUP_GUIDE.md - Guia completo de configuração"
echo "- README.md - Informações do projeto"
echo "- .env.example - Exemplo de variáveis de ambiente"
echo ""
print_success "Bom desenvolvimento! 🚀"