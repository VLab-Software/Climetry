#!/bin/bash

# Script para remover código de tema dinâmico e fixar em light mode

echo "🎨 Removendo sistema de temas dinâmico..."

# Substituir Provider.of<ThemeProvider> por const isDark = false
find lib/src/features -name "*.dart" -type f -exec sed -i '' \
  -e 's/final themeProvider = Provider\.of<ThemeProvider>(context);/const isDark = false; \/\/ TEMA FIXO LIGHT/' \
  -e 's/final isDark = Theme\.of(context)\.brightness == Brightness\.dark;/const isDark = false; \/\/ TEMA FIXO LIGHT/' \
  -e 's/final isDark =/const isDark = false; \/\/ TEMA FIXO LIGHT \/\//' \
  {} \;

# Remover linhas que usam themeProvider.themeMode
find lib/src/features -name "*.dart" -type f -exec sed -i '' \
  -e '/themeProvider\.themeMode/d' \
  {} \;

echo "✅ Temas fixados em light mode!"
echo ""
echo "📝 Arquivos modificados:"
find lib/src/features -name "*.dart" -type f -exec grep -l "const isDark = false" {} \;
