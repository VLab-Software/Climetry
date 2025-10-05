# ✅ CHECKLIST COMPLETO - Implementação FCM

## 🤖 JÁ FEITO AUTOMATICAMENTE

- ✅ `firebase_messaging` adicionado ao pubspec.yaml
- ✅ `flutter_local_notifications` adicionado ao pubspec.yaml
- ✅ `ios/Runner/AppDelegate.swift` configurado com Firebase + FCM
- ✅ `android/app/src/main/AndroidManifest.xml` com permissões FCM
- ✅ `lib/src/core/services/fcm_service.dart` criado
- ✅ `lib/main.dart` inicializa FCM no startup
- ✅ Packages instalados com `flutter pub get`
- ✅ Android já tem Firebase BOM + messaging no build.gradle
- ✅ Documentação criada (3 guias completos)

---

## 👤 VOCÊ PRECISA FAZER

### Terminal (5 minutos)
- [ ] `npm install -g firebase-tools`
- [ ] `firebase login`
- [ ] `firebase init functions` (escolher JavaScript)
- [ ] Copiar código para `functions/index.js`
- [ ] `firebase deploy --only functions`

### Firebase Console (3 minutos)
- [ ] Firestore → Rules → Colar regras → Publicar
- [ ] Firestore → Indexes → Criar índice `notifications`
- [ ] Firestore → Indexes → Criar índice `friendRequests`

### Xcode - iOS (2 minutos)
- [ ] Abrir `ios/Runner.xcworkspace`
- [ ] Target "Runner" → Signing & Capabilities
- [ ] Adicionar "Push Notifications"
- [ ] Adicionar "Background Modes" → marcar "Remote notifications"

### Teste (1 minuto)
- [ ] `flutter run` em device real
- [ ] Copiar token do console
- [ ] Firebase Console → Cloud Messaging → Enviar teste

---

## 📂 ARQUIVOS DE REFERÊNCIA

Todos os códigos e instruções estão em:

1. **ACOES_MANUAIS_NECESSARIAS.md** ← COMECE AQUI (guia simplificado)
2. **INSTRUCOES_FIREBASE_FUNCTIONS.md** (detalhado com Security Rules)
3. **CONFIGURACAO_FIREBASE_COMPLETA.md** (documentação técnica)
4. **RESUMO_IMPLEMENTACAO_FCM.md** (resumo geral)

---

## ⏱️ TEMPO ESTIMADO TOTAL

- **Terminal**: 5 minutos
- **Firebase Console**: 3 minutos  
- **Xcode**: 2 minutos
- **Teste**: 1 minuto

**TOTAL: ~11 minutos** ⚡

---

## 🆘 TROUBLESHOOTING

### "command not found: firebase"
```bash
npm install -g firebase-tools
```

### "No project available"
```bash
firebase use --add
```

### Xcode não encontra workspace
```bash
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
```

### Push não chega
- ✅ Está em device REAL? (simulador não recebe push)
- ✅ Deu permissão de notificações?
- ✅ Functions foram deployadas?
- ✅ Token aparece no console?

---

## 🎯 PRÓXIMOS PASSOS

Após concluir tudo acima:

1. Testar pedido de amizade → deve enviar push
2. Testar convite para evento → deve enviar push
3. Verificar logs das Functions no Firebase Console
4. Implementar navegação ao tocar na notificação

---

**Status Geral: 90% COMPLETO ✅**
**Falta apenas: Suas ações manuais (11 minutos)**
