#!/bin/bash
# Script para build de produção com variáveis de ambiente

# Carregar variáveis do arquivo .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "🚀 Building Climetry..."

# Build para a plataforma especificada
case "$1" in
  android)
    echo "📱 Building Android APK..."
    flutter build apk --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY --release
    ;;
  ios)
    echo "📱 Building iOS..."
    flutter build ios --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY --release
    ;;
  web)
    echo "🌐 Building Web..."
    flutter build web --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY --release
    ;;
  *)
    echo "❌ Uso: ./build_release.sh [android|ios|web]"
    exit 1
    ;;
esac

echo "✅ Build concluído!"
