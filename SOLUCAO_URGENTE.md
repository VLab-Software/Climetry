# 🚨 SOLUÇÃO URGENTE - TRAVAMENTOS

## PROBLEMA RAIZ IDENTIFICADO:

O app trava porque **TODA vez que entra em uma tela**, ela tenta carregar dados do Firestore **SEM TIMEOUT** e de forma **BLOQUEANTE**.

### Culpados principais:

1. **settings_screen.dart** linha 48:
   ```dart
   final prefs = await _userDataService.getPreferences();
   ```
   - Roda no `initState/_loadData()`
   - **SEM TIMEOUT**
   - **BLOQUEIA** se Firestore estiver lento

2. **user_data_service.dart** - TODAS as operações:
   ```dart
   await _firestore.collection('users').doc(_userId).get()
   ```
   - **SEM TIMEOUT**
   - **SEM tratamento de erro**
   - Trava infinitamente se rede/cache tiver problema

3. **home_screen.dart** ainda tem problemas de carregamento

## 🔥 SOLUÇÃO IMEDIATA:

### Opção 1: DESABILITAR CARREGAMENTO DE PREFERÊNCIAS (MAIS RÁPIDA)

```dart
// Em settings_screen.dart - linha 42-60
Future<void> _loadData() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    _currentUser = _authService.currentUser;
    
    // ❌ REMOVIDO - NÃO CARREGAR DO FIRESTORE
    // if (_currentUser != null) {
    //   final prefs = await _userDataService.getPreferences();
    //   ...
    // }
    
    // ✅ USAR VALORES PADRÃO LOCAL
    _temperatureUnit = 'celsius';
    _windUnit = 'kmh';
    _precipitationUnit = 'mm';
    _useCurrentLocation = true;
    
  } catch (e) {
    debugPrint('Erro: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Opção 2: ADICIONAR TIMEOUT EM TUDO (MAIS SEGURA)

```dart
// Em user_data_service.dart - TODAS as operações
final doc = await _firestore.collection('users').doc(_userId).get().timeout(
  const Duration(seconds: 3),
  onTimeout: () {
    debugPrint('⏱️ Timeout - usando dados padrão');
    return _firestore.collection('users').doc('_default_').get();
  },
);
```

## 🎯 IMPLEMENTAÇÃO AGORA:

Vou aplicar **Opção 1** primeiro (mais rápida) e depois **Opção 2** (backup).

