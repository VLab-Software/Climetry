# 🔧 Plano de Revisão Completa - Climetry Production

## ❌ Problemas Identificados

### 1. **Erro Crítico: LocaleDataException** ✅ EM CORREÇÃO
- **Problema:** Locale pt_BR não inicializado
- **Solução:** Já adicionado `initializeDateFormatting` no main.dart
- **Status:** Aguardando testes

### 2. **Alertas de Desastres - Remoção Necessária** 🔄 PENDENTE
- **Remover da tela:**
  - 🌊 Inundações
  - ⛈️ Tempestades Severas  
  - ❄️ Geada
  - 🔥 Incêndios Florestais
- **Manter apenas:** Os 9 alertas climáticos calculados automaticamente

### 3. **Falta Implementar Repositório Local** 🔄 PENDENTE
- Activities precisa ser persistido no SharedPreferences
- Atualmente está apenas em memória (lista vazia)

### 4. **Falta Google Maps/Apple Maps** 🔄 PENDENTE
- Substituir Flutter Map por Google Maps oficial
- Adicionar para iOS: Apple Maps nativo

### 5. **Falta Firebase** 🔄 PENDENTE
- Push Notifications não configurado
- Precisa configuração Firebase

---

## ✅ Correções Imediatas (Esta Conversa)

### 1. Corrigir Locale ✅ FEITO
```dart
// main.dart - JÁ CORRIGIDO
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const App());
}
```

### 2. Simplificar Tela de Alertas - PRÓXIMO PASSO
- Remover tipos de desastres
- Focar apenas nos 9 alertas calculados
- Tela mostrará apenas alertas ativos

### 3. Implementar Repositório de Activities - PRÓXIMO PASSO
- SharedPreferences para persistência
- CRUD completo

### 4. Adicionar Google Maps - PRÓXIMO PASSO
- Pacote: google_maps_flutter
- Configurar API Keys

---

## 📋 Checklist de Produção

### Código Base
- [x] Locale configurado
- [x] Dependências instaladas
- [ ] Dados mockados removidos
- [ ] Repositório real implementado
- [ ] Error handling robusto

### APIs
- [x] MeteomaticsService implementado
- [x] 9 alertas calculados
- [ ] Cache de dados
- [ ] Retry logic
- [ ] Timeout configurado

### Mapas
- [ ] Google Maps integrado (Android)
- [ ] Apple Maps integrado (iOS)
- [ ] Flutter Map removido (não é produção)
- [ ] API Keys configuradas

### Firebase
- [ ] Projeto Firebase criado
- [ ] FlutterFire instalado
- [ ] Push Notifications configuradas
- [ ] Analytics configurado

### Telas
- [x] Home implementada
- [x] Activities implementada  
- [ ] Activities persistidas
- [ ] Disasters simplificada
- [x] Settings implementada

### Integração
- [x] WhatsApp share
- [x] Google Calendar
- [ ] Apple Calendar (iOS)
- [ ] Notificações push

---

## 🎯 Ordem de Implementação

### Fase 1: Correções Críticas (AGORA)
1. ✅ Fix locale error
2. 🔄 Simplificar tela de alertas
3. 🔄 Implementar ActivityRepository com SharedPreferences

### Fase 2: Mapas (PRÓXIMA)
4. Adicionar Google Maps SDK
5. Configurar API Keys
6. Criar widget de seleção de localização
7. Integrar nas telas de atividades

### Fase 3: Firebase (DEPOIS)
8. Configurar projeto Firebase
9. Implementar Push Notifications
10. Testar notificações

### Fase 4: Polimento (FINAL)
11. Remover dados demo
12. Adicionar loading states
13. Error handling
14. Testes

---

## 📝 Arquivos que Serão Modificados

### Imediato:
1. `disasters_screen.dart` - Simplificar
2. `activity_repository.dart` - Criar
3. `activities_screen.dart` - Integrar repositório
4. `new_activity_screen.dart` - Integrar repositório

### Próximo:
5. `location_picker_widget.dart` - Criar com Google Maps
6. `pubspec.yaml` - Adicionar google_maps_flutter
7. `AndroidManifest.xml` - API Keys
8. `Info.plist` - API Keys

### Firebase:
9. `google-services.json` - Android config
10. `GoogleService-Info.plist` - iOS config
11. `firebase_service.dart` - Criar
12. `notification_service.dart` - Criar

---

## 🚀 Continuação nas Próximas Conversas

**Se precisar dividir:**

**Conversa 2:** Repositório + Alertas Simplificados
**Conversa 3:** Google Maps Integration  
**Conversa 4:** Firebase + Push Notifications
**Conversa 5:** Polimento Final

---

Vou começar agora pelas correções imediatas!
