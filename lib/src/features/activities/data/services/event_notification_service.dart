import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/activity.dart';
import '../../../friends/domain/entities/friend.dart';

class EventNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> notifyEventInvitation({
    required Activity activity,
    required List<EventParticipant> newParticipants,
  }) async {
    if (newParticipants.isEmpty) return;

    try {
      for (final participant in newParticipants) {
        await _firestore.collection('eventInvitations').add({
          'activityId': activity.id,
          'activityTitle': activity.title,
          'activityDate': activity.date.toIso8601String(),
          'activityType': activity.type.name,
          'participantUserId': participant.userId,
          'participantName': participant.name,
          'participantRole': participant.role.name,
          'invitedAt': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
    } catch (e) {
      print('Error notifying event invitation: $e');
    }
  }

  Future<void> notifyActivityUpdate({
    required Activity activity,
    required String updateMessage,
  }) async {
    if (activity.participants.isEmpty) return;

    try {
      for (final participant in activity.participants) {
        await _firestore.collection('activityUpdates').add({
          'activityId': activity.id,
          'activityTitle': activity.title,
          'updateMessage': updateMessage,
          'participantUserId': participant.userId,
          'updatedAt': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
    } catch (e) {
      print('Error notifying activity update: $e');
    }
  }
}
