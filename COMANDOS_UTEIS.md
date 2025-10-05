# ⚡ Comandos Úteis - Testes

## 📱 Ver FCM Token do iPhone

### Método 1: Via Firestore (Mais Fácil)
1. Abra: https://console.firebase.google.com
2. Selecione projeto **Climetry**
3. **Firestore Database**
4. Coleção **`users`**
5. Procure pelo email do usuário do iPhone
6. Campo **`fcmToken`** → Copie o valor

### Método 2: Via Terminal (Se rodando debug)
```bash
# Procure por esta linha no terminal:
flutter: FCM Token: [token aqui]
```

### Método 3: Forçar Novo Token
**No iPhone:**
1. Configurações → Notificações → Climetry
2. Desative e reative
3. Abra o app
4. Novo token será gerado

---

## 🔔 Enviar Notificação de Teste

### Via Firebase Console (Recomendado)
1. Firebase Console → **Cloud Messaging**
2. **"Send your first message"**
3. Title: `Teste Push`
4. Text: `Funcionou! 🎉`
5. Next → Target: **"A single device"**
6. Cole o **FCM Token** do iPhone
7. Next → Next → Review → **Publish**

### Via Firestore (Usando sua Function)
1. Firebase Console → **Firestore Database**
2. Coleção **`fcmMessages`** → Add document
3. Auto-ID
4. Campos:
   ```
   token: [FCM token do iPhone]
   title: "Teste Function"
   body: "Sua function funcionou! 🚀"
   createdAt: [timestamp atual]
   ```
5. Save → Function dispara automaticamente

---

## 🔍 Ver Logs do iPhone

### Console do Mac
```bash
# Abrir Console
open /System/Applications/Utilities/Console.app

# Depois:
# 1. Selecione iPhone na barra lateral
# 2. Filtro: "Climetry"
```

### Ver todos os logs Flutter
```bash
# No terminal onde o app está rodando:
# Pressione 'c' para limpar
# Logs continuarão aparecendo (se debug mode)
```

---

## 🔄 Restart do App

### Hot Reload (Só Simulador Debug)
```bash
# No terminal do simulador, pressione:
r
```

### Hot Restart (Só Simulador Debug)
```bash
# No terminal do simulador, pressione:
R
```

### Restart Completo
```bash
# Pressione 'q' para fechar
# Depois rode novamente:

# Simulador (debug)
flutter run -d 8D30A3D8-B8A2-458E-998D-D0441D99122D --debug

# iPhone (release)
flutter run -d 00008120-001E749A0C01A01E --release

# iPhone (debug - com logs)
flutter run -d 00008120-001E749A0C01A01E --debug
```

---

## 📊 Monitorar Firebase Functions

### Ver Logs em Tempo Real
1. Firebase Console → **Functions**
2. Clique na function (ex: `notifyFriendRequest`)
3. Aba **"LOGS"**
4. Atualize a cada 5 segundos

### Ver Execuções
```bash
# Ou via Firebase CLI:
firebase functions:log --only sendFCMNotification

# Últimas 50 execuções:
firebase functions:log --only notifyFriendRequest --limit 50
```

---

## 🗄️ Ver Dados no Firestore

### Ver Pedidos de Amizade
1. Firestore → Coleção **`friendRequests`**
2. Filtre por:
   - `status == "pending"` → Pedidos pendentes
   - `toUserId == [userId]` → Pedidos para você

### Ver Eventos
1. Firestore → Coleção **`activities`**
2. Ordenar por `createdAt` (mais recentes primeiro)

### Ver FCM Tokens
1. Firestore → Coleção **`users`**
2. Campo `fcmToken` em cada usuário

---

## 🧪 Criar Dados de Teste

### Criar Pedido de Amizade Manual
1. Firestore → **`friendRequests`** → Add document
2. Campos:
   ```
   fromUserId: "uid_usuario_1"
   fromUserName: "Teste User"
   fromUserEmail: "teste1@exemplo.com"
   toUserId: "uid_do_iphone"
   toUserEmail: "email_do_iphone"
   status: "pending"
   createdAt: [timestamp]
   ```
3. Save → Function dispara notificação!

### Criar Evento Manual
1. Firestore → **`activities`** → Add document
2. Campos mínimos:
   ```
   title: "Evento de Teste"
   creatorId: "uid_usuario_1"
   participants: ["uid_usuario_1", "uid_do_iphone"]
   date: [timestamp futuro]
   location: "São Paulo"
   createdAt: [timestamp]
   ```
3. Save → Function dispara notificação para participantes!

---

## 🐛 Troubleshooting Rápido

### Notificação não chegou
```bash
# 1. Verificar token no Firestore
# 2. Ver logs da function no Firebase Console
# 3. Confirmar que iPhone está em background
# 4. Verificar internet do iPhone
```

### App não abre no simulador
```bash
# Reiniciar simulador:
# 1. Feche o simulador (Cmd+Q)
# 2. Abra novamente
# 3. Execute flutter run novamente
```

### App não instala no iPhone
```bash
# 1. Verificar se iPhone está desbloqueado
# 2. Verificar conexão wireless:
flutter devices

# 3. Tentar via cabo:
# Conecte cabo → Confie no computador → Tente novamente
```

### Firebase Function não executa
```bash
# 1. Ver logs de erro:
# Firebase Console → Functions → [function] → Logs

# 2. Verificar se está ativa:
# Firebase Console → Functions → Status: "Active"

# 3. Redeployar:
cd functions
firebase deploy --only functions
```

---

## 📸 Capturar Tela/Vídeo do iPhone

### Captura de Tela
```bash
# No Mac, com iPhone conectado:
# 1. Abra QuickTime Player
# 2. Arquivo → Nova Gravação de Tela
# 3. Clique na seta → Selecione iPhone
# 4. Clique botão vermelho para gravar
```

### Captura via Simulador
```bash
# No simulador:
# Cmd+S → Salva screenshot
# Ou:
xcrun simctl io booted screenshot ~/Desktop/screenshot.png
```

---

## 🧹 Limpar e Rebuild

### Limpar Build Cache
```bash
flutter clean
flutter pub get
```

### Rebuild Completo iOS
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run -d [device-id]
```

### Limpar Dados do App (Logout Forçado)
```bash
# No simulador:
# Pressione e segure o ícone do app → Remover App

# No iPhone:
# Configurações → Geral → Armazenamento → Climetry → Excluir App
# Depois reinstale via flutter run
```

---

## 📦 Comandos Firebase CLI

### Verificar Status das Functions
```bash
firebase functions:list
```

### Ver Config do Projeto
```bash
firebase projects:list
firebase use --add  # Mudar de projeto
```

### Deploy Seletivo
```bash
# Deploy apenas uma function:
firebase deploy --only functions:sendFCMNotification

# Deploy todas as functions:
firebase deploy --only functions
```

### Ver Logs Específicos
```bash
# Erros apenas:
firebase functions:log --only sendFCMNotification --severity ERROR

# Últimos 100 logs:
firebase functions:log --limit 100
```

---

## 🎨 Verificar Mudanças de UI

### Listar Arquivos Modificados
```bash
# Ver arquivos alterados recentemente:
git status

# Ver diferenças:
git diff lib/src/features/friends/presentation/screens/friends_management_screen.dart
git diff lib/src/features/activities/presentation/screens/activities_screen.dart
git diff lib/src/features/settings/presentation/screens/settings_screen.dart
```

### Reverter Mudanças (se necessário)
```bash
# Reverter um arquivo específico:
git checkout -- [caminho/do/arquivo]

# Reverter todas as mudanças:
git reset --hard HEAD
```

---

## 🔐 Aplicar Security Rules (Urgente!)

```bash
# 1. Abrir arquivo de rules:
# Firebase Console → Firestore → Rules

# 2. Copiar rules do arquivo:
cat ATENCAO_SECURITY_RULES.md  # Ver as regras

# 3. Colar no Firebase Console
# 4. Publicar
```

---

## 📱 Listar Dispositivos Conectados

```bash
# Ver todos os dispositivos:
flutter devices

# Ver apenas iOS:
flutter devices | grep ios

# Ver dispositivos wireless:
flutter devices | grep wireless
```

---

## 🔄 Hot Reload vs Hot Restart

### Hot Reload (r)
- ⚡ Rápido (~1 segundo)
- Mantém estado do app
- Atualiza UI e código
- **Não funciona** em release mode

### Hot Restart (R)
- 🔄 Médio (~5 segundos)
- Reseta estado do app
- Rebuild completo
- **Não funciona** em release mode

### Flutter Run (completo)
- 🐢 Lento (~30 segundos no iPhone)
- Build completo
- Funciona em qualquer mode
- Necessário para mudanças em:
  - pubspec.yaml
  - assets
  - configurações nativas

---

## 🆘 Comandos de Emergência

### App Travou
```bash
# No terminal, pressione:
q  # Fecha o app

# Se não funcionar:
Ctrl+C  # Força fechamento

# Depois:
flutter run -d [device-id]  # Reabre
```

### Terminal Bugado
```bash
# Limpar terminal:
c  # No terminal Flutter
# Ou:
clear  # Limpa zsh
```

### Múltiplos Terminais Rodando
```bash
# Ver processos Flutter:
ps aux | grep flutter

# Matar processo específico:
kill [PID]

# Matar todos os processos Flutter:
killall -9 flutter
```

---

## ✅ Comandos Mais Usados (Cola)

```bash
# Rodar no simulador
flutter run -d 8D30A3D8-B8A2-458E-998D-D0441D99122D --debug

# Rodar no iPhone
flutter run -d 00008120-001E749A0C01A01E --release

# Ver dispositivos
flutter devices

# Ver logs Firebase
firebase functions:log --only sendFCMNotification

# Limpar build
flutter clean && flutter pub get

# Ver FCM token no Firestore
# Firebase Console → Firestore → users → [user] → fcmToken
```

---

**Salve este arquivo e use como referência rápida! ⚡**
