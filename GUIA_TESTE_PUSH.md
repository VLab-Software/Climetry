# 📱 GUIA DE TESTE - Notificações Push

## ✅ STATUS DO BUILD

### Simulador iOS
- ✅ Build concluído (debug mode)
- ✅ App instalado no simulador
- ✅ App em execução

### iPhone (Device Real)
- ✅ Build concluído (release mode)
- 🔄 Instalando no device...

---

## 🧪 COMO TESTAR NOTIFICAÇÕES PUSH

### ⚠️ IMPORTANTE
**Notificações push NÃO funcionam no simulador!**
- O simulador não tem acesso ao APNs (Apple Push Notification service)
- **Use APENAS o device real para testar push**

### 📱 PASSOS PARA TESTE

#### 1️⃣ No Simulador - Criar Conta de Teste
1. Abra o app no simulador
2. Crie uma nova conta (ex: teste@climetry.com)
3. Complete o cadastro
4. Vá para amigos/adicionar amigos

#### 2️⃣ No iPhone - Sua Conta Principal
1. Abra o app no iPhone
2. Faça login com sua conta
3. **IMPORTANTE**: Quando solicitar permissão de notificações, clique em **Permitir**
4. Vá para o console e procure: `📱 FCM Token: ...`
5. Anote/copie esse token (importante para debug)

#### 3️⃣ Enviar Pedido de Amizade
**Opção A: Do simulador para o iPhone**
1. No simulador, procure seu usuário (do iPhone)
2. Envie pedido de amizade
3. **Resultado esperado**: iPhone deve receber notificação push

**Opção B: Do iPhone para o simulador**
1. No iPhone, procure o usuário teste do simulador
2. Envie pedido de amizade
3. Simulador NÃO vai receber push (esperado)
4. Mas você verá no console do simulador que a notificação foi criada

---

## 🔍 VERIFICAR SE ESTÁ FUNCIONANDO

### No iPhone (Quem recebe):
1. ✅ Notificação push aparece no topo
2. ✅ Som de notificação
3. ✅ Badge no ícone do app (se configurado)

### No Firebase Console:
1. Acesse: https://console.firebase.google.com/project/nasa-climetry/functions
2. Clique em `notifyFriendRequest`
3. Aba "Logs"
4. Deve mostrar: `Successfully sent message: ...`

### No Terminal (Logs em tempo real):
```bash
firebase functions:log --only notifyFriendRequest
```

---

## 🐛 SE NÃO RECEBER NOTIFICAÇÃO

### Checklist:
- [ ] Permissão de notificações concedida no iPhone?
- [ ] iPhone está conectado à internet?
- [ ] App está em background ou fechado? (foreground também funciona)
- [ ] Firebase Functions deployadas? (você já fez isso ✅)
- [ ] Token FCM aparece no console do app?

### Teste Manual:
1. Copie o FCM Token do console
2. Acesse: https://console.firebase.google.com/project/nasa-climetry/notification
3. Clique "Send your first message"
4. Clique "Send test message"
5. Cole o token
6. Clique "Test"

Se receber notificação = FCM funcionando ✅
Se não receber = Problema na configuração do device

---

## 📊 MONITORAR

### Ver todos os logs das Functions:
```bash
firebase functions:log
```

### Ver logs específicos:
```bash
# Pedidos de amizade
firebase functions:log --only notifyFriendRequest

# Envio de notificações
firebase functions:log --only sendFCMNotification

# Convites para eventos
firebase functions:log --only notifyEventInvitation
```

---

## 🎯 FLUXO COMPLETO DE TESTE

```
1. Simulador → Cria conta teste
2. iPhone → Login com sua conta
3. iPhone → Permitir notificações
4. iPhone → Copiar FCM Token (opcional, para debug)
5. Simulador → Procurar seu usuário
6. Simulador → Enviar pedido de amizade
7. Firebase → Function notifyFriendRequest dispara
8. Firebase → Function sendFCMNotification envia push
9. iPhone → 🔔 RECEBE NOTIFICAÇÃO!
```

---

## ✅ TESTE ADICIONAL: Convite para Evento

1. No simulador, crie um evento
2. Adicione seu usuário (do iPhone) como participante
3. iPhone deve receber: "Convite para evento: [nome do evento]"

---

## 🆘 TROUBLESHOOTING

### "Permissão de notificações negada"
- Vá em: Ajustes → Climetry → Notificações → Ativar

### "Token não aparece no console"
- Verifique se FCMService foi inicializado
- Procure por erros no console
- Tente reinstalar o app

### "Function não dispara"
- Verifique logs: `firebase functions:log`
- Confirme que Security Rules foram aplicadas
- Verifique se o documento foi criado no Firestore

### "Push não chega mas logs mostram sucesso"
- Confirme que device tem internet
- Verifique se não está em modo "Não Perturbe"
- Tente fechar completamente o app e reabrir

---

## 📱 COMANDOS ÚTEIS

```bash
# Ver devices conectados
flutter devices

# Rodar no iPhone
flutter run -d 00008120-001E749A0C01A01E

# Ver logs do iPhone em tempo real
flutter logs -d 00008120-001E749A0C01A01E

# Ver logs do simulador
flutter logs -d 8D30A3D8-B8A2-458E-998D-D0441D99122D

# Reinstalar no iPhone
flutter install -d 00008120-001E749A0C01A01E --release
```

---

**🎉 Boa sorte com os testes!**

Se funcionar, você terá um sistema completo de notificações push! 🚀
