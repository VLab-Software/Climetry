import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/activity.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Get all activities where user is owner or participant
  Future<List<Activity>> getAll() async {
    try {
      if (_userId == null) return [];

      // Query: activities where user is owner
      final ownerQuery = await _firestore
          .collection('activities')
          .where('ownerId', isEqualTo: _userId)
          .get();

      // Query: activities where user is in participants
      final participantQuery = await _firestore
          .collection('activities')
          .where('participantIds', arrayContains: _userId)
          .get();

      // Combine results and remove duplicates
      final allDocs = <QueryDocumentSnapshot>{
        ...ownerQuery.docs,
        ...participantQuery.docs,
      };

      return allDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Activity.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar atividades: $e');
    }
  }

  /// Get activities as a stream for real-time updates
  Stream<List<Activity>> watchAll() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('activities')
        .where('participantIds', arrayContains: _userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Activity.fromJson(data);
      }).toList();
    });
  }

  Future<Activity?> getById(String id) async {
    try {
      final doc = await _firestore.collection('activities').doc(id).get();
      
      if (!doc.exists) return null;
      
      return Activity.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> save(Activity activity) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final activityData = activity.toJson();
      
      // Add participantIds array for querying
      activityData['participantIds'] = [
        activity.ownerId,
        ...activity.participants.map((p) => p.userId),
      ];

      await _firestore
          .collection('activities')
          .doc(activity.id)
          .set(activityData);
    } catch (e) {
      throw Exception('Erro ao salvar atividade: $e');
    }
  }

  Future<void> update(Activity activity) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final activityData = activity.toJson();
      
      // Update participantIds array
      activityData['participantIds'] = [
        activity.ownerId,
        ...activity.participants.map((p) => p.userId),
      ];

      await _firestore
          .collection('activities')
          .doc(activity.id)
          .update(activityData);
    } catch (e) {
      throw Exception('Erro ao atualizar atividade: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      await _firestore.collection('activities').doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar atividade: $e');
    }
  }

  Future<void> clear() async {
    // Not implementing full clear for safety
    // Use delete individual activities instead
    throw UnimplementedError('Use delete() para remover atividades individuais');
  }
}
