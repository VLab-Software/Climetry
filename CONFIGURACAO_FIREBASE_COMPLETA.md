# Configurações Firebase e Notificações Push - Guia Completo

## 📱 SETUP NOTIFICAÇÕES PUSH (FCM - Firebase Cloud Messaging)

### 1. Adicionar Package ao pubspec.yaml

```yaml
dependencies:
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
```

### 2. Configurar iOS (ios/Runner/AppDelegate.swift)

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication,
                           didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### 3. Adicionar Capabilities no Xcode

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione Target "Runner"
3. Aba "Signing & Capabilities"
4. Clique em "+ Capability"
5. Adicione:
   - **Push Notifications**
   - **Background Modes** (marque "Remote notifications")

### 4. Configurar Android (android/app/build.gradle.kts)

```kotlin
android {
    defaultConfig {
        // ... código existente
        minSdk = 21  // Mínimo para FCM
    }
}

dependencies {
    // ... dependências existentes
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

### 5. Android Manifest (android/app/src/main/AndroidManifest.xml)

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application>
        <!-- Metadata do Firebase -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="climetry_channel"/>
        
        <!-- Service para mensagens em background -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.messaging.RECEIVE_EVENT"/>
            </intent-filter>
        </service>
    </application>
</manifest>
```

### 6. Criar FCM Service (lib/src/core/services/fcm_service.dart)

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handler para mensagens em background (top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializar FCM
  Future<void> initialize() async {
    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicitar permissões (iOS)
    await _requestPermissions();

    // Configurar notificações locais
    await _configureLocalNotifications();

    // Obter token FCM
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listener para refresh do token
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handlers de mensagens
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Verificar mensagem inicial (app aberto via notificação)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }
  }

  /// Solicitar permissões
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined permission');
    }
  }

  /// Configurar notificações locais
  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Criar canal de notificação (Android)
    const androidChannel = AndroidNotificationChannel(
      'climetry_channel',
      'Climetry Notifications',
      description: 'Notificações do app Climetry',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Salvar token no Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Handler para mensagens em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'climetry_channel',
            'Climetry Notifications',
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handler quando usuário toca na notificação
  void _handleMessageOpened(RemoteMessage message) {
    print('Message opened: ${message.data}');
    // Navegar para tela específica baseado em message.data
  }

  /// Enviar notificação para usuário específico
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // Criar notificação no Firestore (Cloud Function enviará)
      await FirebaseFirestore.instance.collection('fcmMessages').add({
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
```

---

## 🔥 FIRESTORE SECURITY RULES

### firestore.rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isOwnerOrAdmin(ownerId, participants) {
      return isAuthenticated() && (
        request.auth.uid == ownerId ||
        participants.hasAny([request.auth.uid]) && 
        get(/databases/$(database)/documents/activities/$(activityId)/participants/$(request.auth.uid)).data.role in ['owner', 'admin']
      );
    }

    // USERS
    match /users/{userId} {
      // Ler: qualquer autenticado
      allow read: if isAuthenticated();
      
      // Criar: apenas o próprio usuário
      allow create: if isOwner(userId);
      
      // Atualizar: apenas o próprio usuário
      allow update: if isOwner(userId) && 
        // Não pode mudar o UID
        request.resource.data.diff(resource.data).unchangedKeys().hasAll(['uid']);
      
      // Deletar: apenas o próprio usuário
      allow delete: if isOwner(userId);
      
      // ACTIVITIES (subcoleção do usuário)
      match /activities/{activityId} {
        // Ler: apenas o dono ou participantes
        allow read: if isOwner(userId) ||
          resource.data.participants.hasAny([request.auth.uid]);
        
        // Criar: apenas o dono
        allow create: if isOwner(userId) &&
          request.resource.data.ownerId == request.auth.uid;
        
        // Atualizar: dono ou admins
        allow update: if isOwner(resource.data.ownerId) ||
          (isAuthenticated() && 
           resource.data.participants.hasAny([request.auth.uid]) &&
           get(/databases/$(database)/documents/users/$(userId)/activities/$(activityId)).data.participants
             .where('userId', '==', request.auth.uid)[0].role in ['owner', 'admin']);
        
        // Deletar: apenas o dono
        allow delete: if isOwner(resource.data.ownerId);
      }
      
      // FRIENDS (subcoleção do usuário)
      match /friends/{friendId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId);
      }
    }
    
    // FRIEND REQUESTS
    match /friendRequests/{requestId} {
      // Ler: remetente ou destinatário
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.fromUserId ||
        request.auth.uid == resource.data.toUserId
      );
      
      // Criar: apenas remetente
      allow create: if isAuthenticated() &&
        request.resource.data.fromUserId == request.auth.uid &&
        request.resource.data.status == 'pending';
      
      // Atualizar: apenas destinatário (para aceitar/rejeitar)
      allow update: if isAuthenticated() &&
        request.auth.uid == resource.data.toUserId &&
        resource.data.status == 'pending' &&
        request.resource.data.status in ['accepted', 'rejected'];
      
      // Deletar: remetente ou destinatário
      allow delete: if isAuthenticated() && (
        request.auth.uid == resource.data.fromUserId ||
        request.auth.uid == resource.data.toUserId
      );
    }
    
    // NOTIFICATIONS
    match /notifications/{notificationId} {
      // Ler: apenas o destinatário
      allow read: if isOwner(resource.data.userId);
      
      // Criar: qualquer autenticado (para notificar outros)
      allow create: if isAuthenticated();
      
      // Atualizar: apenas o destinatário (marcar como lida)
      allow update: if isOwner(resource.data.userId) &&
        // Só pode mudar o campo 'read'
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      
      // Deletar: apenas o destinatário
      allow delete: if isOwner(resource.data.userId);
    }
    
    // FCM MESSAGES (para Cloud Function enviar)
    match /fcmMessages/{messageId} {
      allow read, write: if false; // Apenas Cloud Functions
    }
  }
}
```

---

## ☁️ FIREBASE CLOUD FUNCTION (Enviar Notificações Push)

### functions/index.js

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
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
      
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

### Instalar e fazer deploy:

```bash
cd functions
npm install firebase-admin firebase-functions
firebase deploy --only functions
```

---

## 🔑 ÍNDICES FIRESTORE (Necessários)

No Firebase Console → Firestore → Indexes, criar:

1. **Collection: notifications**
   - Fields: `userId` (Ascending), `createdAt` (Descending)
   - Status: Single field exemption

2. **Collection: friendRequests**
   - Fields: `toUserId` (Ascending), `status` (Ascending), `createdAt` (Descending)

3. **Collection: users/{userId}/activities**
   - Fields: `ownerId` (Ascending), `date` (Descending)

---

## 📧 CONFIGURAR EMAIL/PHONE PARA CONVITES

### 1. Firebase Dynamic Links (Deep Links)

1. No Firebase Console → Dynamic Links
2. Criar novo link curto: `climetry.page.link`
3. Configurar:
   - iOS: Bundle ID do app
   - Android: Package name
   - URL de fallback

### 2. Implementar Convite por Email

```dart
Future<void> inviteFriendByEmail(String email) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  
  // Criar convite no Firestore
  await FirebaseFirestore.instance.collection('invites').add({
    'fromUserId': currentUser.uid,
    'fromUserName': currentUser.displayName,
    'toEmail': email,
    'createdAt': FieldValue.serverTimestamp(),
    'status': 'pending',
  });
  
  // Trigger Cloud Function para enviar email (via SendGrid, etc)
}
```

---

## ✅ CHECKLIST FINAL

### Firebase Console:
- [ ] Ativar Authentication (Email/Password)
- [ ] Criar database Firestore
- [ ] Aplicar Security Rules
- [ ] Criar índices necessários
- [ ] Ativar Cloud Storage
- [ ] Config Cloud Messaging (FCM)
- [ ] Deploy Cloud Functions

### iOS:
- [ ] GoogleService-Info.plist no projeto
- [ ] Push Notifications capability
- [ ] Background Modes capability
- [ ] AppDelegate.swift configurado
- [ ] Testar notificações no device

### Android:
- [ ] google-services.json no projeto
- [ ] minSdk >= 21
- [ ] Permissões no Manifest
- [ ] Testar notificações no device

### App:
- [ ] firebase_messaging package adicionado
- [ ] FCMService inicializado no main()
- [ ] Handlers de notificações implementados
- [ ] Deep links configurados
- [ ] Testar fluxo completo

---

## 🚀 INICIALIZAÇÃO NO APP

### lib/main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar FCM
  final fcmService = FCMService();
  await fcmService.initialize();
  
  runApp(MyApp());
}
```

---

**🎉 Com essas configurações, o app terá notificações push completas funcionando em iOS e Android!**
