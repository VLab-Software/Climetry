# 🚀 INSTALAÇÃO FIREBASE FUNCTIONS - Guia Rápido

## O que você precisa fazer MANUALMENTE:

### 1️⃣ Instalar Firebase CLI (apenas uma vez)

```bash
npm install -g firebase-tools
```

### 2️⃣ Login no Firebase

```bash
firebase login
```

### 3️⃣ Inicializar Firebase Functions no projeto

No terminal, na pasta raiz do projeto Climetry:

```bash
firebase init functions
```

**Respostas esperadas:**
- **Use existing project**: Selecione seu projeto Firebase
- **Language**: JavaScript
- **ESLint**: No (ou Yes, como preferir)
- **Install dependencies**: Yes

### 4️⃣ Substituir o arquivo functions/index.js

Após o `firebase init`, substitua o conteúdo de `functions/index.js` pelo código abaixo:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Enviar notificação via FCM
exports.sendFCMNotification = functions.firestore
  .document('fcmMessages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Verificar se já foi enviada
    if (data.sent) return null;
    
    const message = {
      token: data.token,
      notification: {
        title: data.notification.title,
        body: data.notification.body,
      },
      data: data.data || {},
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'climetry_channel',
        },
      },
    };
    
    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      
      // Marcar como enviada
      await snap.ref.update({ 
        sent: true, 
        sentAt: admin.firestore.FieldValue.serverTimestamp() 
      });
      
      return null;
    } catch (error) {
      console.error('Error sending message:', error);
      await snap.ref.update({ error: error.message });
      return null;
    }
  });

// Notificar quando um pedido de amizade é criado
exports.notifyFriendRequest = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    
    // Buscar token do destinatário
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(request.toUserId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;
    
    // Enviar notificação
    await admin.firestore().collection('fcmMessages').add({
      token: fcmToken,
      notification: {
        title: 'Nova solicitação de amizade',
        body: `${request.fromUserName} quer ser seu amigo`,
      },
      data: {
        type: 'friend_request',
        requestId: snap.id,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
    });
    
    return null;
  });

// Notificar quando é convidado para um evento
exports.notifyEventInvitation = functions.firestore
  .document('users/{userId}/activities/{activityId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Verificar se novos participantes foram adicionados
    const newParticipants = after.participants.filter(p => 
      !before.participants.some(bp => bp.userId === p.userId)
    );
    
    if (newParticipants.length === 0) return null;
    
    // Enviar notificação para cada novo participante
    for (const participant of newParticipants) {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(participant.userId)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) continue;
      
      await admin.firestore().collection('fcmMessages').add({
        token: fcmToken,
        notification: {
          title: 'Convite para evento',
          body: `Você foi convidado para "${after.title}"`,
        },
        data: {
          type: 'event_invitation',
          activityId: context.params.activityId,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });
    }
    
    return null;
  });
```

### 5️⃣ Fazer Deploy das Functions

```bash
firebase deploy --only functions
```

---

## 📋 O que já foi AUTOMATICAMENTE configurado:

✅ **pubspec.yaml**: Adicionado `firebase_messaging` e `flutter_local_notifications`
✅ **iOS AppDelegate.swift**: Configurado Firebase + FCM
✅ **Android Manifest**: Permissões e service de FCM adicionados
✅ **Android build.gradle**: Firebase BOM e messaging já estavam configurados
✅ **FCMService**: Criado em `lib/src/core/services/fcm_service.dart`
✅ **main.dart**: FCMService inicializado no startup

---

## 🔑 CONFIGURAÇÕES FIREBASE CONSOLE

### 1. Firestore Security Rules

No Firebase Console → Firestore → Rules, copie estas regras:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // USERS
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
      
      match /activities/{activityId} {
        allow read: if isOwner(userId) || resource.data.participants.hasAny([request.auth.uid]);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
      
      match /friends/{friendId} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // FRIEND REQUESTS
    match /friendRequests/{requestId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.fromUserId ||
        request.auth.uid == resource.data.toUserId
      );
      allow create: if isAuthenticated() && request.resource.data.fromUserId == request.auth.uid;
      allow update: if isAuthenticated() && request.auth.uid == resource.data.toUserId;
      allow delete: if isAuthenticated();
    }
    
    // NOTIFICATIONS
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // FCM MESSAGES (apenas Cloud Functions)
    match /fcmMessages/{messageId} {
      allow read, write: if false;
    }
  }
}
```

### 2. Firestore Indexes

No Firebase Console → Firestore → Indexes, crie:

1. **Collection**: `notifications`
   - `userId` (Ascending) + `createdAt` (Descending)

2. **Collection**: `friendRequests`
   - `toUserId` (Ascending) + `status` (Ascending) + `createdAt` (Descending)

---

## 🍎 CONFIGURAÇÃO iOS (XCODE)

**⚠️ VOCÊ PRECISA FAZER ISSO NO XCODE:**

1. Abra `ios/Runner.xcworkspace` (não o .xcodeproj!)
2. Selecione o target **Runner**
3. Aba **Signing & Capabilities**
4. Clique em **"+ Capability"**
5. Adicione:
   - ✅ **Push Notifications**
   - ✅ **Background Modes** → Marque "Remote notifications"

---

## ✅ CHECKLIST FINAL

### No Firebase Console:
- [ ] Firestore Security Rules aplicadas
- [ ] Índices criados
- [ ] Cloud Messaging ativado

### No Xcode (iOS):
- [ ] Push Notifications capability adicionada
- [ ] Background Modes capability adicionada

### No Projeto:
- [ ] `firebase init functions` executado
- [ ] `functions/index.js` substituído
- [ ] `firebase deploy --only functions` executado
- [ ] `flutter pub get` executado

### Testar:
- [ ] Rodar o app em device real (simulador não recebe push)
- [ ] Verificar logs do FCM token no console
- [ ] Criar pedido de amizade e ver se notificação chega

---

## 🧪 TESTANDO NOTIFICAÇÕES

Para testar se está funcionando, você pode enviar uma notificação manualmente pelo Firebase Console:

1. Firebase Console → Cloud Messaging → "Send your first message"
2. Título e corpo da mensagem
3. "Send test message"
4. Cole o FCM token que aparece nos logs do app

---

**🎉 Pronto! Tudo configurado!**
