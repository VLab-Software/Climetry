import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  eventInvitation,
  eventUpdate,
  eventReminder,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>?
  data; // Dados extras (ex: friendRequestId, eventId)

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.data,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      title: data['title'] as String,
      message: data['message'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? read,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      data: data ?? this.data,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'data': data,
      });
    } catch (e) {
      throw Exception('Error ao criar notificação: $e');
    }
  }

  Future<List<AppNotification>> getNotifications({
    bool? onlyUnread,
    NotificationType? type,
  }) async {
    if (_userId == null) return [];

    try {
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true);

      if (onlyUnread == true) {
        query = query.where('read', isEqualTo: false);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.limit(50).get();

      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error searching notificações: $e');
    }
  }

  Stream<List<AppNotification>> getNotificationsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      throw Exception('Error ao marcar notificação como lida: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error ao marcar todas as notificações como lidas: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Error ao deletar notificação: $e');
    }
  }

  Future<int> getUnreadCount() async {
    if (_userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Stream<int> getUnreadCountStream() {
    if (_userId == null) return Stream.value(0);

    final notificationsStream = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    return notificationsStream.asyncMap((notifCount) async {
      final requestsSnapshot = await _firestore
          .collection('friendRequests')
          .where('toUserId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return notifCount + requestsSnapshot.docs.length;
    });
  }


  Future<void> notifyFriendRequest({
    required String toUserId,
    required String fromUserName,
  }) async {
    await createNotification(
      userId: toUserId,
      type: NotificationType.friendRequest,
      title: 'Nova solicitação de amizade',
      message: '$fromUserName enviou uma solicitação de amizade',
      data: {'fromUserName': fromUserName},
    );
  }

  Future<void> notifyFriendRequestAccepted({
    required String toUserId,
    required String friendName,
  }) async {
    await createNotification(
      userId: toUserId,
      type: NotificationType.friendRequestAccepted,
      title: 'Solicitação aceita',
      message: '$friendName accepted your friend request',
      data: {'friendName': friendName},
    );
  }

  Future<void> notifyEventInvitation({
    required String toUserId,
    required String eventTitle,
    required String eventId,
    required String inviterName,
  }) async {
    await createNotification(
      userId: toUserId,
      type: NotificationType.eventInvitation,
      title: 'Convite para ewind',
      message: '$inviterName invited you to "$eventTitle"',
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'inviterName': inviterName,
      },
    );
  }

  Future<void> notifyEventUpdate({
    required String toUserId,
    required String eventTitle,
    required String eventId,
    required String updateMessage,
  }) async {
    await createNotification(
      userId: toUserId,
      type: NotificationType.eventUpdate,
      title: 'Ewind atualizado',
      message: '$eventTitle: $updateMessage',
      data: {'eventId': eventId, 'eventTitle': eventTitle},
    );
  }
}
