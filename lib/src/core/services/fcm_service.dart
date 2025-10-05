import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
      print('🔑 FCM Token obtido: ${token.substring(0, 20)}...');
      await _saveTokenToFirestore(token);
      print('✅ Token salvo no Firestore');
    } else {
      print('⚠️ FCM Token is null');
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

    print('📱 FCM Permission Status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission');
    } else {
      print('❌ User declined permission');
    }
    
    // Tentar obter APNS token no iOS
    try {
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        print('🍎 APNS Token: $apnsToken');
      } else {
        print('⚠️ APNS token not available yet (normal for simulator or first launch)');
      }
    } catch (e) {
      print('⚠️ Could not get APNS token: $e');
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
    if (userId == null) {
      print('⚠️ Cannot save token: user not authenticated');
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('💾 Token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
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