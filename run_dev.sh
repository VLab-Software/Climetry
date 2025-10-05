#!/bin/bash
# Script para executar o app em desenvolvimento com variáveis de ambiente

# Carregar variáveis do arquivo .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Executar o app com a API key
flutter run --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY "$@"
