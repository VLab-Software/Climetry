import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/activity.dart';
import '../../../friends/domain/entities/friend.dart';

/// Service to send event invitation notifications via Cloud Functions
class EventNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Notify new participants about event invitation
  /// This creates a document that triggers a Cloud Function
  Future<void> notifyEventInvitation({
    required Activity activity,
    required List<EventParticipant> newParticipants,
  }) async {
    if (newParticipants.isEmpty) return;

    try {
      // Create a notification trigger document for Cloud Function
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
      // Don't throw - notification is not critical
    }
  }

  /// Notify when activity is updated (e.g., date/time changes)
  Future<void> notifyActivityUpdate({
    required Activity activity,
    required String updateMessage,
  }) async {
    if (activity.participants.isEmpty) return;

    try {
      // Notify all participants (except owner)
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
