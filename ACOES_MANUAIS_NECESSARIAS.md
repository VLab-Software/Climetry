# 🎯 AÇÕES MANUAIS NECESSÁRIAS - Guia Simplificado

## ⚡ PRIORIDADE ALTA - FAÇA PRIMEIRO

### 1. Instalar Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Fazer Login no Firebase
```bash
firebase login
```

### 3. Inicializar Functions
```bash
cd /Users/roosoars/Desktop/Climetry
firebase init functions
```
**Respostas:**
- Projeto: Selecione o seu
- Linguagem: JavaScript
- ESLint: No
- Instalar deps: Yes

---

## 📝 COPIAR E COLAR

### 4. Código das Functions

Abra: `functions/index.js`

Cole este código (SUBSTITUA TUDO):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Enviar notificação via FCM
exports.sendFCMNotification = functions.firestore
  .document('fcmMessages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.sent) return null;
    
    const message = {
      token: data.token,
      notification: {
        title: data.notification.title,
        body: data.notification.body,
      },
      data: data.data || {},
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
      android: {
        priority: 'high',
        notification: { sound: 'default', channelId: 'climetry_channel' },
      },
    };
    
    try {
      const response = await admin.messaging().send(message);
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    } catch (error) {
      await snap.ref.update({ error: error.message });
      return null;
    }
  });

// Notificar pedido de amizade
exports.notifyFriendRequest = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const userDoc = await admin.firestore().collection('users').doc(request.toUserId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;
    
    await admin.firestore().collection('fcmMessages').add({
      token: fcmToken,
      notification: {
        title: 'Nova solicitação de amizade',
        body: `${request.fromUserName} quer ser seu amigo`,
      },
      data: { type: 'friend_request', requestId: snap.id },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
    });
    return null;
  });

// Notificar convite para evento
exports.notifyEventInvitation = functions.firestore
  .document('users/{userId}/activities/{activityId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const newParticipants = after.participants.filter(p => 
      !before.participants.some(bp => bp.userId === p.userId)
    );
    if (newParticipants.length === 0) return null;
    
    for (const participant of newParticipants) {
      const userDoc = await admin.firestore().collection('users').doc(participant.userId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) continue;
      
      await admin.firestore().collection('fcmMessages').add({
        token: fcmToken,
        notification: {
          title: 'Convite para evento',
          body: `Você foi convidado para "${after.title}"`,
        },
        data: { type: 'event_invitation', activityId: context.params.activityId },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });
    }
    return null;
  });
```

### 5. Deploy das Functions
```bash
firebase deploy --only functions
```

---

## 🔥 FIREBASE CONSOLE

### 6. Security Rules

**Firebase Console → Firestore → Rules**

Cole estas regras:

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

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isOwner(userId);
      
      match /activities/{activityId} {
        allow read: if isOwner(userId) || resource.data.participants.hasAny([request.auth.uid]);
        allow write: if isOwner(userId);
      }
      match /friends/{friendId} {
        allow read, write: if isOwner(userId);
      }
    }
    
    match /friendRequests/{requestId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.fromUserId ||
        request.auth.uid == resource.data.toUserId
      );
      allow create: if isAuthenticated() && request.resource.data.fromUserId == request.auth.uid;
      allow update: if isAuthenticated() && request.auth.uid == resource.data.toUserId;
      allow delete: if isAuthenticated();
    }
    
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    match /fcmMessages/{messageId} {
      allow read, write: if false;
    }
  }
}
```

Clique em **Publicar**

---

### 7. Criar Índices

**Firebase Console → Firestore → Indexes → Criar Índice**

**Índice 1:**
- Collection ID: `notifications`
- Campo 1: `userId` (Ascending)
- Campo 2: `createdAt` (Descending)

**Índice 2:**
- Collection ID: `friendRequests`
- Campo 1: `toUserId` (Ascending)
- Campo 2: `status` (Ascending)
- Campo 3: `createdAt` (Descending)

---

## 🍎 XCODE (apenas iOS)

### 8. Adicionar Capabilities

1. Abra `ios/Runner.xcworkspace` (não o .xcodeproj!)
2. Selecione target **Runner**
3. Aba **Signing & Capabilities**
4. Clique em **+ Capability**
5. Adicione: **Push Notifications**
6. Adicione: **Background Modes** → marque **Remote notifications**

---

## ✅ TESTAR

```bash
flutter pub get
flutter run
```

No console, procure: `📱 FCM Token: ...`

**Testar Push:**
1. Firebase Console → Cloud Messaging → "Send test message"
2. Cole o token do console
3. Envie!

---

## 📞 SE DER ERRO

- **"command not found: firebase"** → Instale: `npm install -g firebase-tools`
- **"No project"** → Execute: `firebase use --add`
- **Xcode não abre** → Primeiro: `cd ios && pod install`
- **Push não chega** → Teste em device REAL (simulador não funciona)

---

**🎉 É só isso! Qualquer dúvida, me chame!**
