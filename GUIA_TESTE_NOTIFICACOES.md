# 🔔 Guia Completo - Teste de Notificações Push

## 📱 Status dos Dispositivos
- ✅ **Simulador iPhone 16e**: Rodando (debug mode)
- ✅ **iPhone físico**: Rodando (release mode)

---

## 🎯 Teste 1: Notificação de Pedido de Amizade

### Passo 1: Criar Contas
**No iPhone físico:**
1. Abra o app Climetry
2. Faça logout se já estiver logado
3. Crie uma conta nova (ex: `usuario1@teste.com`)
4. Anote o email usado

**No Simulador:**
1. Abra o app Climetry
2. Faça logout se já estiver logado
3. Crie outra conta (ex: `usuario2@teste.com`)
4. Anote o email usado

### Passo 2: Enviar Pedido de Amizade
**No Simulador:**
1. Vá para a tela de **Amigos** (ícone de pessoas no bottom nav)
2. Clique no botão **"Adicionar por Email"** (FAB azul com ícone de email)
3. Digite o email da conta do iPhone: `usuario1@teste.com`
4. Clique em **"Enviar Convite"**
5. Você verá: ✅ "Pedido de amizade enviado!"

### Passo 3: Receber Notificação
**No iPhone físico:**
1. **IMPORTANTE**: Coloque o app em background (aperte o botão Home ou gesto)
2. Aguarde alguns segundos (5-10 segundos)
3. Você deverá receber uma notificação push:
   ```
   🤝 Novo Pedido de Amizade
   usuario2 quer ser seu amigo!
   ```

### Passo 4: Verificar no Firebase Console

Abra o Firebase Console para ver o log da função:
1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto Climetry
3. Vá em **Functions** no menu lateral
4. Clique em **"notifyFriendRequest"**
5. Clique na aba **"LOGS"**
6. Você verá:
   - ✅ "Sending friend request notification..."
   - ✅ "Notification sent successfully" ou erro se houver

---

## 🎯 Teste 2: Notificação de Convite para Evento

### Passo 1: Aceitar Pedido de Amizade (Pré-requisito)
**No iPhone físico:**
1. Abra o app
2. Vá para **Amigos**
3. Você verá o pedido pendente de `usuario2@teste.com`
4. Aceite o pedido
5. Agora vocês são amigos! ✅

### Passo 2: Criar Evento e Convidar Amigo
**No Simulador:**
1. Vá para a tela de **Eventos** (ícone de calendário)
2. Clique no botão **"+"** (criar evento)
3. Preencha:
   - **Título**: "Teste de Notificação"
   - **Data**: Qualquer data futura
   - **Hora**: Qualquer horário
   - **Local**: Qualquer local
4. Na seção **"Participantes"**, adicione o amigo `usuario1@teste.com`
5. Clique em **"Criar Evento"**

### Passo 3: Receber Notificação
**No iPhone físico:**
1. Coloque o app em background
2. Aguarde 5-10 segundos
3. Você receberá:
   ```
   🎉 Novo Convite
   usuario2 convidou você para "Teste de Notificação"
   ```

---

## 🎯 Teste 3: Notificação Manual via Firebase Console

Se quiser testar manualmente sem criar eventos/amigos:

### Opção A: Via Cloud Functions
1. Abra Firebase Console → **Firestore Database**
2. Vá para a coleção **`fcmMessages`**
3. Clique em **"Add document"**
4. Crie um documento com ID automático e campos:
   ```json
   {
     "userId": "UID_DO_IPHONE_AQUI",
     "token": "TOKEN_FCM_DO_IPHONE",
     "title": "Teste Manual",
     "body": "Esta é uma notificação de teste!",
     "createdAt": [timestamp atual]
   }
   ```
5. A função `sendFCMNotification` será disparada automaticamente
6. A notificação chegará no iPhone

### Opção B: Via Firebase Messaging (mais fácil)
1. Firebase Console → **Cloud Messaging**
2. Clique em **"Send your first message"**
3. Preencha:
   - **Notification title**: "Teste Push"
   - **Notification text**: "Funcionou! 🎉"
4. Clique **Next**
5. Em **Target**, selecione:
   - **Topic** ou **User segment** → iOS
6. Clique **Next** até **Review**
7. Clique **Publish**

---

## 🔍 Checklist de Troubleshooting

Se a notificação não chegar, verifique:

### ✅ No iPhone Físico
- [ ] App está em background (não fechado completamente)
- [ ] Notificações estão habilitadas (iOS Settings → Climetry → Notifications → Allow)
- [ ] Internet conectada (WiFi ou 4G/5G)
- [ ] Não está em modo "Não Perturbe"

### ✅ No Firebase Console
- [ ] Função `notifyFriendRequest` está ativa (Functions → Status: Active)
- [ ] Logs da função não mostram erros
- [ ] Firestore está criando documentos em `friendRequests`
- [ ] Collection `users` tem campo `fcmToken` preenchido

### ✅ No Código
- [ ] FCMService está inicializado (`main.dart`)
- [ ] Permissões foram solicitadas e aceitas
- [ ] Token FCM foi salvo no Firestore
- [ ] AppDelegate.swift está configurado (iOS)

---

## 📊 Como Ver os Logs em Tempo Real

### No Terminal (Simulador):
O terminal onde o simulador está rodando mostrará:
```
flutter: ✅ Firebase inicializado com sucesso
flutter: User granted permission
flutter: FCM Token: [token aqui]
flutter: 🔔 Notificação recebida: [título]
```

### No iPhone (via Console do Mac):
1. Abra o **Console.app** no Mac
2. Conecte o iPhone via cabo
3. Selecione o iPhone na barra lateral
4. Filtre por **"Climetry"**
5. Você verá todos os logs do app em tempo real

### No Firebase Console:
1. Functions → Clique na função → Logs
2. Firestore → Cada coleção mostra documentos criados
3. Cloud Messaging → Clique em "Analytics" para estatísticas

---

## 🎓 Entendendo o Fluxo

### Fluxo de Pedido de Amizade:
```
1. Usuário A clica "Adicionar por Email"
   ↓
2. App cria documento em `friendRequests` com status: pending
   ↓
3. Firebase Function `notifyFriendRequest` é disparada (trigger onCreate)
   ↓
4. Function busca FCM token do Usuário B no Firestore
   ↓
5. Function envia notificação push para Usuário B via FCM
   ↓
6. iPhone do Usuário B recebe e exibe a notificação
```

### Fluxo de Convite para Evento:
```
1. Usuário A cria evento e adiciona Usuário B como participante
   ↓
2. App cria documento em `activities` com participants: [A, B]
   ↓
3. Firebase Function `notifyEventInvitation` é disparada (trigger onCreate)
   ↓
4. Function busca FCM tokens de todos os participantes (exceto criador)
   ↓
5. Function envia notificações para todos os participantes
   ↓
6. Participantes recebem notificação no dispositivo
```

---

## 📝 Notas Importantes

### Limitações do Simulador
⚠️ **O simulador iOS NÃO suporta notificações push reais!**
- A mensagem `APNS token has not been set yet` é esperada
- Notificações só funcionam em dispositivo físico
- Por isso temos os dois dispositivos rodando

### Delay nas Notificações
- Notificações podem levar de 3 a 30 segundos para chegar
- Isso depende da conexão com servidores do Firebase/Apple
- Em produção, geralmente são instantâneas

### Mode Debug vs Release
- **Debug**: Logs mais verbosos, hot reload disponível
- **Release**: Performance otimizada, logs reduzidos
- Notificações funcionam em ambos os modos

---

## 🚀 Próximos Passos Após Testes

Após confirmar que as notificações funcionam:

1. **Aplicar Security Rules** (URGENTE):
   - Ver arquivo `ATENCAO_SECURITY_RULES.md`
   - Proteger dados sensíveis
   - Validar permissões de escrita

2. **Criar Indexes do Firestore**:
   - Ver arquivo `STATUS_FINAL_IMPLEMENTACAO.md`
   - Melhorar performance de queries
   - Evitar erros em produção

3. **Testar Cenários Adicionais**:
   - Múltiplos pedidos de amizade
   - Eventos com vários participantes
   - App fechado completamente (kill)
   - Notificações em foreground

4. **Ajustar UI das Notificações**:
   - Customizar ícone da notificação
   - Adicionar sons personalizados
   - Implementar ações nas notificações (aceitar/rejeitar)

---

## 🆘 Precisa de Ajuda?

Se algo não funcionar:
1. Copie os logs do terminal/console
2. Tire screenshot da tela de erro
3. Verifique os logs no Firebase Console
4. Consulte os arquivos de documentação criados

**Arquivos de Referência:**
- `FIREBASE_IMPLEMENTATION_SUMMARY.md` - Resumo da implementação
- `GUIA_TESTE_PUSH.md` - Guia anterior de testes
- `STATUS_FINAL_IMPLEMENTACAO.md` - Status completo do projeto
- `ALTERACOES_INTERFACE.md` - Mudanças recentes na UI

---

## ✅ Sucesso Esperado

Ao final dos testes, você deve ter visto:
- ✅ Notificação de pedido de amizade no iPhone
- ✅ Notificação de convite para evento no iPhone
- ✅ Logs no Firebase confirmando envio
- ✅ UI atualizada refletindo as ações

**Pronto para começar os testes! 🎉**
