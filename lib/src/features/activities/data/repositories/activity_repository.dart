import 'dart:async';
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
      if (_userId == null) {
        print('⚠️ ActivityRepository: Usuário não autenticado');
        return [];
      }

      print('🔍 ActivityRepository: Buscando atividades para $_userId');

      // Query: activities where user is owner or participant
      // Usando apenas uma query com array-contains é mais eficiente
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
          print('⚠️ Erro ao parsear atividade ${doc.id}: $e');
          return null;
        }
      }).whereType<Activity>().toList();

      print('✅ ActivityRepository: ${activities.length} atividades válidas');
      return activities;
    } catch (e) {
      print('❌ ActivityRepository erro: $e');
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
      final doc = await _firestore.collection('activities').doc(id).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Timeout ao buscar atividade $id');
          return _firestore.collection('_timeout_').doc('_default_').get();
        },
      );
      
      if (!doc.exists) return null;
      
      return Activity.fromJson(doc.data()!);
    } catch (e) {
      print('⚠️ Erro ao buscar atividade: $e');
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
