# ⚠️ ATENÇÃO! CONFIGURAÇÃO OBRIGATÓRIA ANTES DE TESTAR

## 🚨 SECURITY RULES NÃO FORAM APLICADAS!

**O app NÃO vai funcionar corretamente sem isso!**

### Por que é importante?
Sem as Security Rules:
- ❌ Firestore vai bloquear escritas
- ❌ Pedidos de amizade não vão ser criados
- ❌ Notificações não vão ser disparadas
- ❌ Functions não vão ter dados para processar

---

## ✅ SOLUÇÃO RÁPIDA (3 minutos)

### 1️⃣ Acesse o Firebase Console
https://console.firebase.google.com/project/nasa-climetry/firestore/rules

### 2️⃣ APAGUE TUDO e cole este código:

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

### 3️⃣ Clique em **PUBLICAR**

---

## ⏰ FAÇA ISSO AGORA!

**Não teste o app sem aplicar as Security Rules primeiro!**

Depois de publicar:
1. ✅ Aguarde 10 segundos para propagar
2. ✅ Reabra os apps (simulador e iPhone)
3. ✅ Agora sim, pode testar!

---

## 🔗 LINK DIRETO

https://console.firebase.google.com/project/nasa-climetry/firestore/rules

---

**⚡ Tempo: 3 minutos**
**Importância: CRÍTICO ⚠️**
