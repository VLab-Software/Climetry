import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/activity.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<List<Activity>> getAll() async {
    try {
      if (_userId == null) {
        print('⚠️ ActivityRepository: User not authenticated');
        return [];
      }

      print('🔍 ActivityRepository: Buscando activitys para $_userId');

      final query = await _firestore
          .collection('activities')
          .where('participantIds', arrayContains: _userId)
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⏱️ ActivityRepository: Timeout na query');
              throw TimeoutException('Query timeout');
            },
          );

      print('✅ ActivityRepository: ${query.docs.length} documentos encontrados');

      final activities = query.docs.map((doc) {
        try {
          final data = doc.data();
          return Activity.fromJson(data);
        } catch (e) {
          print('⚠️ Error ao parsear activity ${doc.id}: $e');
          return null;
        }
      }).whereType<Activity>().toList();

      print('✅ ActivityRepository: ${activities.length} activitys válidas');
      return activities;
    } catch (e) {
      print('❌ ActivityRepository erro: $e');
      throw Exception('Error loading activitys: $e');
    }
  }

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
      final doc = await _firestore.collection('activities').doc(id).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Timeout ao search activity $id');
          return _firestore.collection('_timeout_').doc('_default_').get();
        },
      );
      
      if (!doc.exists) return null;
      
      return Activity.fromJson(doc.data()!);
    } catch (e) {
      print('⚠️ Error searching activity: $e');
      return null;
    }
  }

  Future<void> save(Activity activity) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final activityDate = activity.toJson();
      
      activityDate['participantIds'] = [
        activity.ownerId,
        ...activity.participants.map((p) => p.userId),
      ];

      await _firestore
          .collection('activities')
          .doc(activity.id)
          .set(activityDate);
    } catch (e) {
      throw Exception('Error ao salvar activity: $e');
    }
  }

  Future<void> update(Activity activity) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final activityDate = activity.toJson();
      
      activityDate['participantIds'] = [
        activity.ownerId,
        ...activity.participants.map((p) => p.userId),
      ];

      await _firestore
          .collection('activities')
          .doc(activity.id)
          .update(activityDate);
    } catch (e) {
      throw Exception('Error ao atualizar activity: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      await _firestore.collection('activities').doc(id).delete();
    } catch (e) {
      throw Exception('Error ao deletar activity: $e');
    }
  }

  Future<void> clear() async {
    throw UnimplementedError('Use delete() para remover activitys individuais');
  }
}
