import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissão de notificações concedida');

      final token = await _messaging.getToken();
      if (token != null && _userId != null) {
        await _saveTokenToFirestore(token);
      }

      await _setupLocalNotifications();

      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } else {
      print('⚠️ Permissão de notificações negada');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('💾 Token FCM salvo: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Erro ao salvar token FCM: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Mensagem recebida em foreground: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Climetry',
        body: message.notification!.body ?? '',
        payload: message.data['eventId'] as String?,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 App aberto por notificação: ${message.notification?.title}');
    
    final eventId = message.data['eventId'] as String?;
    if (eventId != null) {
      print('📍 Navegar para evento: $eventId');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'climetry_events',
      'Eventos Climetry',
      channelDescription: 'Notificações de eventos e convites',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🖱️ Notificação tocada: ${response.payload}');
    
    if (response.payload != null) {
      print('📍 Navegar para evento: ${response.payload}');
    }
  }

  Future<void> sendEventInvitation({
    required String recipientUserId,
    required String eventId,
    required String eventTitle,
    required String inviterName,
  }) async {
    try {
      final recipientDoc = await _firestore
          .collection('users')
          .doc(recipientUserId)
          .get();

      if (!recipientDoc.exists) return;

      final fcmToken = recipientDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        print('⚠️ Usuário $recipientUserId não tem token FCM');
        return;
      }

      await _firestore.collection('notifications').add({
        'recipientId': recipientUserId,
        'senderId': _userId,
        'type': 'event_invitation',
        'eventId': eventId,
        'title': '📅 Novo convite de evento',
        'body': '$inviterName convidou você para "$eventTitle"',
        'data': {
          'eventId': eventId,
          'type': 'event_invitation',
        },
        'fcmToken': fcmToken,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notificação de convite salva no Firestore');
    } catch (e) {
      print('❌ Erro ao enviar notificação de convite: $e');
    }
  }

  Future<void> sendAdminPromotionNotification({
    required String recipientUserId,
    required String eventId,
    required String eventTitle,
    required String promoterName,
  }) async {
    try {
      final recipientDoc = await _firestore
          .collection('users')
          .doc(recipientUserId)
          .get();

      if (!recipientDoc.exists) return;

      final fcmToken = recipientDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        print('⚠️ Usuário $recipientUserId não tem token FCM');
        return;
      }

      await _firestore.collection('notifications').add({
        'recipientId': recipientUserId,
        'senderId': _userId,
        'type': 'admin_promotion',
        'eventId': eventId,
        'title': '👑 Você foi promovido a admin',
        'body': '$promoterName promoveu você a administrador em "$eventTitle"',
        'data': {
          'eventId': eventId,
          'type': 'admin_promotion',
        },
        'fcmToken': fcmToken,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notificação de promoção salva no Firestore');
    } catch (e) {
      print('❌ Erro ao enviar notificação de promoção: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
      print('🗑️ Token FCM removido');
    } catch (e) {
      print('❌ Erro ao remover token FCM: $e');
    }
  }
}
