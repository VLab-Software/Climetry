# 🚀 Teste Rápido de Notificação - 2 Minutos

## Método Mais Rápido: Via Firebase Console

### Passo 1: Pegar o FCM Token do iPhone (30 segundos)

**No terminal onde o iPhone está rodando**, procure por esta linha:
```
flutter: FCM Token: [um token longo aqui]
```

Se não encontrar, você pode forçar o print:
1. No iPhone, feche e abra o app novamente
2. O token será impresso no terminal

**Copie o token completo** (é uma string grande tipo: `eXhPzJ9...`)

### Passo 2: Enviar Notificação de Teste (1 minuto)

#### Opção A: Via Firebase Console UI (MAIS FÁCIL)
1. Abra: https://console.firebase.google.com
2. Selecione o projeto **Climetry**
3. Menu lateral → **Engage** → **Cloud Messaging**
4. Clique em **"Send your first message"** (ou "Create campaign")
5. Preencha:
   - **Notification title**: `Teste Push`
   - **Notification text**: `Funcionou! 🎉`
6. Clique **Next**
7. Em **Target**, selecione **"A single device"**
8. Cole o **FCM token** que você copiou
9. Clique **Next** → **Next** → **Review**
10. Clique **Publish**

**Resultado**: Em 5-10 segundos, o iPhone receberá a notificação!

---

#### Opção B: Via Firestore (Usando suas Functions)

1. Firebase Console → **Build** → **Firestore Database**
2. Clique na coleção **`fcmMessages`**
   - Se não existir, clique **"Start collection"** e crie com ID: `fcmMessages`
3. Clique **"Add document"**
4. Deixe o ID em **"Auto-ID"**
5. Adicione os campos:

   | Campo | Tipo | Valor |
   |-------|------|-------|
   | `token` | string | [Cole o FCM token do iPhone] |
   | `title` | string | `Teste via Function` |
   | `body` | string | `Sua function está funcionando! 🚀` |
   | `createdAt` | timestamp | [Clique no relógio para timestamp atual] |

6. Clique **"Save"**

**Resultado**: A função `sendFCMNotification` será disparada automaticamente e enviará a notificação!

---

## 🔍 Verificar se Funcionou

### No iPhone:
- Coloque o app em background
- Aguarde 5-10 segundos
- A notificação deve aparecer no topo da tela

### No Firebase Console:
1. Vá em **Functions** → **sendFCMNotification** → **Logs**
2. Você verá:
   ```
   ✅ Sending notification to token: [token]...
   ✅ Notification sent successfully
   ```

### No Terminal do iPhone:
```
flutter: 🔔 Notificação recebida: Teste Push
flutter: 📱 Mostrando notificação local
```

---

## ⚠️ Se Não Funcionar

### Erro: "Token inválido"
**Solução**: 
- O token FCM expira ou muda
- Feche e abra o app novamente no iPhone
- Copie o novo token que aparecer no terminal

### Erro: "Notification not delivered"
**Solução**:
1. Verifique se o app está em background (não fechado completamente)
2. Vá em **Settings → Notifications → Climetry** → Ative tudo
3. Desative "Não Perturbe" no iPhone

### Erro: "Function failed"
**Solução**:
1. Firebase Console → Functions → Logs
2. Veja o erro específico
3. Provavelmente falta configurar o **Server Key** (mas isso já foi feito)

---

## 📱 Como Encontrar o FCM Token

### Método 1: No Terminal (Recomendado)
```bash
# No terminal onde o iPhone está rodando:
# Procure por:
flutter: FCM Token: [token aqui]
```

### Método 2: No Firestore
1. Firebase Console → Firestore Database
2. Coleção **`users`**
3. Encontre o documento do seu usuário (pelo email)
4. Campo **`fcmToken`** tem o token

### Método 3: Forçar Re-Print
**No iPhone:**
1. Vá em Configurações → Notificações
2. Desative e reative as notificações do Climetry
3. Abra o app
4. O novo token será impresso no terminal

---

## 🎯 Cenário Completo de Teste (5 minutos)

### Teste Completo: Pedido de Amizade Real

1. **No Simulador** (ou segundo iPhone se tiver):
   - Crie conta: `teste1@exemplo.com`
   - Vá em Amigos → Adicionar por Email
   - Digite o email do iPhone: `[email_do_iphone]`
   - Enviar Convite

2. **Verifique no Firebase**:
   - Firestore → `friendRequests` → Verá o novo documento
   - Functions → `notifyFriendRequest` → Logs

3. **No iPhone**:
   - Coloque em background
   - Aguarde 5-10 segundos
   - Notificação: "🤝 Novo Pedido de Amizade"

4. **Aceite o Pedido**:
   - Abra o app no iPhone
   - Amigos → Aceitar pedido
   - Agora são amigos!

5. **Teste Convite para Evento**:
   - No Simulador, crie um evento
   - Adicione o amigo (usuário do iPhone)
   - iPhone receberá: "🎉 Novo Convite"

---

## 💡 Dica Pro: Monitorar em Tempo Real

Abra **3 janelas**:

1. **Terminal 1**: iPhone rodando
   - Veja logs do app em tempo real

2. **Terminal 2**: Simulador rodando
   - Veja ações do usuário

3. **Browser**: Firebase Console
   - Functions → Logs (atualize a cada 5 segundos)
   - Firestore → Observe documentos sendo criados

Assim você vê todo o fluxo acontecendo ao vivo! 🎬

---

## ✅ Checklist Rápido

Antes de testar:
- [ ] iPhone rodando o app (modo release)
- [ ] App em background no iPhone
- [ ] Notificações permitidas no iPhone
- [ ] Firebase Console aberto
- [ ] FCM Token copiado

Durante o teste:
- [ ] Notificação apareceu no iPhone? ✅
- [ ] Som tocou? ✅
- [ ] Badge apareceu? ✅
- [ ] Ao tocar, abre o app? ✅

Após o teste:
- [ ] Logs no Firebase sem erros? ✅
- [ ] Documento criado no Firestore? ✅
- [ ] Function executou com sucesso? ✅

---

**Pronto! Em menos de 2 minutos você pode testar a primeira notificação! 🚀**
