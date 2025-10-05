# 🚨 CONFIGURAR APNs - URGENTE

## Problema Identificado
```
Error: "Auth error from APNS or Web Push Service"
```

**Causa:** Firebase não tem o certificado APNs para enviar notificações push para iOS.

---

## ✅ Solução: Configurar APNs no Firebase

### Passo 1: Obter a Chave APNs do Apple Developer

1. Acesse: https://developer.apple.com/account/resources/authkeys/list
2. Clique em **[+]** para criar nova chave
3. **Nome:** `Climetry Push Notifications`
4. **Marque:** ✅ Apple Push Notifications service (APNs)
5. Clique em **Continue** → **Register**
6. **Baixe o arquivo `.p8`** (você só pode baixar UMA VEZ!)
7. **Anote o Key ID** (exemplo: `ABC123XYZ4`)

### Passo 2: Encontrar Team ID

1. No Apple Developer, vá para **Membership**
2. Copie o **Team ID** (exemplo: `C277ZT2F26`)

### Passo 3: Configurar no Firebase Console

1. Acesse: https://console.firebase.google.com/project/nasa-climetry/settings/cloudmessaging
2. Vá para **Cloud Messaging** → **Apple app configuration**
3. Em **APNs authentication key**, clique em **Upload**:
   - **APNs auth key:** Selecione o arquivo `.p8` baixado
   - **Key ID:** Cole o Key ID anotado
   - **Team ID:** Cole seu Team ID (`C277ZT2F26`)
4. Clique em **Upload**

### Passo 4: Verificar Bundle ID

Certifique-se que o Bundle ID no Firebase corresponde ao do Xcode:
- **Firebase:** `com.vlabsoftware.climetry` (ou similar)
- **Xcode:** Runner → General → Bundle Identifier

---

## 🔄 Após Configurar

### 1. Reiniciar os Apps
```bash
# Parar os apps em execução
# No simulador: Cmd + Q no app
# No iPhone: Fechar app

# Reinstalar com hot restart
flutter run -d 8D30A3D8-B8A2-458E-998D-D0441D99122D --debug  # Simulador
flutter run -d 00008120-001E749A0C01A01E --release           # iPhone
```

### 2. Verificar Logs
Os logs devem mostrar:
```
✅ FCM Token obtido: fEcIVBX1kkFBsgSt0CBnc4...
✅ Token salvo no Firestore
🍎 APNS Token: <token_aqui>
```

### 3. Testar Push Notification

1. **No Simulador:**
   - Login com `camilamalaman11@gmail.com`
   - Ir em **Amigos** → **+**
   - Enviar solicitação para `roosoars@icloud.com`

2. **No iPhone (bloqueado):**
   - Login com `roosoars@icloud.com`
   - **Bloquear o iPhone**
   - Aguardar notificação aparecer na tela de bloqueio

### 4. Verificar Firestore

Após enviar solicitação, verificar em `fcmMessages`:
- ✅ `sent: true` (foi enviado)
- ✅ `sentAt: <timestamp>` (horário de envio)
- ❌ Se ainda aparecer `error: "Auth error..."`, revisar configuração APNs

---

## ⚠️ Problemas Comuns

### "Key ID não encontrado"
- Verifique se copiou o Key ID correto da chave `.p8`

### "Invalid Team ID"
- Verifique se o Team ID é o mesmo do Apple Developer Account
- Team ID deve ter 10 caracteres (exemplo: `C277ZT2F26`)

### "Bundle ID mismatch"
- Certifique-se que o Bundle ID no Firebase é EXATAMENTE igual ao do Xcode

### Notificação não chega no iPhone
- Verifique se o iPhone tem notificações habilitadas:
  - Ajustes → Climetry → Notificações → Permitir Notificações = **Ativado**
- Verifique se o iPhone está conectado à internet
- Tente deletar e reinstalar o app

---

## 📝 Checklist Final

- [ ] Chave APNs `.p8` baixada do Apple Developer
- [ ] Key ID e Team ID anotados
- [ ] Chave `.p8` uploaded no Firebase Console
- [ ] Apps reiniciados (simulador + iPhone)
- [ ] Token FCM aparece nos logs
- [ ] Solicitação de amizade enviada
- [ ] Notificação push recebida no iPhone bloqueado
- [ ] Badge "1" aparece no ícone do app
- [ ] Nome correto aparece ("Rodrigo" em vez de "Usuário")
- [ ] Botões Aceitar/Recusar estão proporcionais (ambos preenchidos)

---

## 🔗 Links Úteis

- Apple Developer Keys: https://developer.apple.com/account/resources/authkeys/list
- Firebase Console: https://console.firebase.google.com/project/nasa-climetry/settings/cloudmessaging
- Documentação APNs: https://firebase.google.com/docs/cloud-messaging/ios/certs

---

**IMPORTANTE:** Depois de configurar o APNs, as notificações push devem funcionar normalmente no iPhone físico. O simulador NÃO recebe notificações push reais (é limitação do iOS Simulator).
