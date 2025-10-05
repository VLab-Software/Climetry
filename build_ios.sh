#!/bin/bash

# 🚀 Script de Build iOS - Climetry
# Autor: VLab Software
# Versão: 1.0.0

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print colorido
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║           📱 Climetry iOS Build Script                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml não encontrado. Execute este script na raiz do projeto."
    exit 1
fi

# Menu de opções
echo "Escolha o tipo de build:"
echo ""
echo "  1) 🧪 Debug Build (para desenvolvimento)"
echo "  2) 📦 Release Build (sem codesign)"
echo "  3) 🚀 Release Build (com codesign)"
echo "  4) 🏃 Run no device conectado"
echo "  5) 🧹 Limpar e reconstruir tudo"
echo "  6) 📂 Abrir Xcode"
echo ""
read -p "Digite sua escolha (1-6): " choice

case $choice in
    1)
        print_step "Iniciando Debug Build..."
        flutter build ios --debug --no-codesign
        print_success "Debug build completo!"
        ;;
    
    2)
        print_step "Iniciando Release Build (sem codesign)..."
        flutter build ios --release --no-codesign
        print_success "Release build completo (sem codesign)!"
        print_warning "Para instalar no device, você precisará fazer codesign manual no Xcode."
        ;;
    
    3)
        print_step "Iniciando Release Build (com codesign)..."
        flutter build ios --release
        print_success "Release build completo (com codesign)!"
        print_success "Agora você pode fazer Archive no Xcode."
        ;;
    
    4)
        print_step "Verificando devices conectados..."
        flutter devices
        echo ""
        read -p "Digite o ID do device (ou pressione Enter para usar o primeiro): " device_id
        
        if [ -z "$device_id" ]; then
            print_step "Rodando no primeiro device disponível..."
            flutter run --release
        else
            print_step "Rodando no device $device_id..."
            flutter run --release -d "$device_id"
        fi
        ;;
    
    5)
        print_step "Limpando projeto..."
        flutter clean
        
        print_step "Removendo Pods..."
        cd ios
        rm -rf Pods Podfile.lock
        cd ..
        
        print_step "Baixando dependências..."
        flutter pub get
        
        print_step "Instalando Pods..."
        cd ios
        pod install
        cd ..
        
        print_success "Limpeza completa!"
        echo ""
        read -p "Deseja fazer build agora? (s/n): " do_build
        
        if [ "$do_build" = "s" ] || [ "$do_build" = "S" ]; then
            print_step "Iniciando Release Build..."
            flutter build ios --release --no-codesign
            print_success "Build completo!"
        fi
        ;;
    
    6)
        print_step "Abrindo Xcode..."
        open ios/Runner.xcworkspace
        print_success "Xcode aberto!"
        echo ""
        echo "📝 Próximos passos no Xcode:"
        echo "  1. Selecione 'Any iOS Device (arm64)' no topo"
        echo "  2. Product → Archive"
        echo "  3. Distribute App → App Store Connect"
        echo "  4. Upload"
        ;;
    
    *)
        print_error "Opção inválida!"
        exit 1
        ;;
esac

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║                      ✅ Concluído!                         ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Informações adicionais
echo "📱 Informações do App:"
echo "   Bundle ID: com.vlabsoftware.climetry"
echo "   Versão: $(grep 'version:' pubspec.yaml | sed 's/version: //')"
echo "   Firebase: nasa-climetry"
echo ""
echo "📖 Guias disponíveis:"
echo "   - IOS_BUILD_DISTRIBUTION_GUIDE.md"
echo "   - FIREBASE_HOSTING_SUCCESS.md"
echo ""
