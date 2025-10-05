#!/bin/bash
# Script para adicionar timeout em TODAS as operações Firestore

echo "🔧 Adicionando timeouts em TODAS as operações Firestore..."

# user_data_service.dart - adicionar timeouts
perl -i -pe 's/await _firestore\.collection\(([^)]+)\)\.doc\(([^)]+)\)\.set\(/await _firestore.collection($1).doc($2).set(/g' lib/src/core/services/user_data_service.dart
perl -i -pe 's/await _firestore\.collection\(([^)]+)\)\.doc\(([^)]+)\)\.update\(/await _firestore.collection($1).doc($2).update(/g' lib/src/core/services/user_data_service.dart
perl -i -pe 's/await _firestore\.collection\(([^)]+)\)\.doc\(([^)]+)\)\.get\(\)/await _firestore.collection($1).doc($2).get().timeout(const Duration(seconds: 5), onTimeout: () => throw TimeoutException("Firestore timeout"))/g' lib/src/core/services/user_data_service.dart

echo "✅ Timeouts adicionados!"
echo ""
echo "📝 Próximo passo: Fazer settings_screen carregar ASYNC (não bloquear UI)"
