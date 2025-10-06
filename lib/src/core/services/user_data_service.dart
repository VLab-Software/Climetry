import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/activities/domain/entities/activity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> createUserProfile(User user) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'email': user.email,
        'displayName': user.displayName ?? 'Usuário',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'theme': 'system',
          'language': 'pt_BR',
          'temperatureUnit': 'celsius',
          'enabledAlerts': [],
          'notificationsEnabled': true,
        },
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirestoreException('⏱️ Timeout ao criar perfil');
        },
      );
    } catch (e) {
      throw FirestoreException('Erro ao criar perfil: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_userId == null) throw FirestoreException('Usuário não autenticado');

    try {
      await _firestore.collection('users').doc(_userId).update(data).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirestoreException('⏱️ Timeout ao atualizar perfil');
        },
      );
    } catch (e) {
      throw FirestoreException('Erro ao atualizar perfil: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirestoreException('⏱️ Timeout ao obter perfil');
        },
      );
      return doc.data();
    } catch (e) {
      throw FirestoreException('Erro ao obter perfil: $e');
    }
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (_userId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    if (_userId == null) throw FirestoreException('Usuário não autenticado');

    try {
      await _firestore.collection('users').doc(_userId).update({
        'preferences': preferences,
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirestoreException('⏱️ Timeout ao salvar preferências');
        },
      );
    } catch (e) {
      throw FirestoreException('Erro ao salvar preferências: $e');
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    if (_userId == null) {
      return _defaultPreferences();
    }

    try {
      final doc = await _firestore.collection('users').doc(_userId).get().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏱️ Timeout ao obter preferências - usando padrão');
          return _firestore.collection('_timeout_').doc('_default_').get();
        },
      );
      final data = doc.data();
      return data?['preferences'] ?? _defaultPreferences();
    } catch (e) {
      print('⚠️ Erro ao obter preferências: $e - usando padrão');
      return _defaultPreferences();
    }
  }

  Stream<Map<String, dynamic>> getPreferencesStream() {
    if (_userId == null) return Stream.value(_defaultPreferences());

    return _firestore.collection('users').doc(_userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return data?['preferences'] ?? _defaultPreferences();
    });
  }

  Map<String, dynamic> _defaultPreferences() {
    return {
      'theme': 'system',
      'language': 'pt_BR',
      'temperatureUnit': 'celsius',
      'enabledAlerts': <String>[],
      'notificationsEnabled': true,
      'monitoringLocation': null,
    };
  }

  Future<void> saveActivity(Activity activity) async {
    if (_userId == null) throw FirestoreException('Usuário não autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .doc(activity.id)
          .set({
            'id': activity.id,
            'title': activity.title,
            'description': activity.description,
            'location': activity.location,
            'coordinates': GeoPoint(
              activity.coordinates.latitude,
              activity.coordinates.longitude,
            ),
            'date': Timestamp.fromDate(activity.date),
            'startTime': activity.startTime,
            'endTime': activity.endTime,
            'type': activity.type.name,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw FirestoreException('Erro ao salvar atividade: $e');
    }
  }

  Future<void> updateActivity(Activity activity) async {
    if (_userId == null) throw FirestoreException('Usuário não autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .doc(activity.id)
          .update({
            'title': activity.title,
            'description': activity.description,
            'location': activity.location,
            'coordinates': GeoPoint(
              activity.coordinates.latitude,
              activity.coordinates.longitude,
            ),
            'date': Timestamp.fromDate(activity.date),
            'startTime': activity.startTime,
            'endTime': activity.endTime,
            'type': activity.type.name,
            'priority': activity.priority.name,
            'tags': activity.tags,
            'recurrence': activity.recurrence.name,
            'monitoredConditions': activity.monitoredConditions
                .map((c) => c.name)
                .toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw FirestoreException('Erro ao atualizar atividade: $e');
    }
  }

  Future<List<Activity>> getActivities() async {
    if (_userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final geoPoint = data['coordinates'] as GeoPoint;
        final timestamp = data['date'] as Timestamp;

        return Activity(
          id: data['id'],
          ownerId: data['ownerId'] as String? ?? _userId ?? '',
          title: data['title'],
          location: data['location'],
          coordinates: LatLng(geoPoint.latitude, geoPoint.longitude),
          date: timestamp.toDate(),
          startTime: data['startTime'],
          endTime: data['endTime'],
          type: ActivityType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => ActivityType.other,
          ),
          description: data['description'],
        );
      }).toList();
    } catch (e) {
      throw FirestoreException('Erro ao obter atividades: $e');
    }
  }

  Stream<List<Activity>> getActivitiesStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('activities')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final geoPoint = data['coordinates'] as GeoPoint;
            final timestamp = data['date'] as Timestamp;

            return Activity(
              id: data['id'],
              ownerId: data['ownerId'] as String? ?? _userId ?? '',
              title: data['title'],
              location: data['location'],
              coordinates: LatLng(geoPoint.latitude, geoPoint.longitude),
              date: timestamp.toDate(),
              startTime: data['startTime'],
              endTime: data['endTime'],
              type: ActivityType.values.firstWhere(
                (e) => e.name == data['type'],
                orElse: () => ActivityType.other,
              ),
              description: data['description'],
            );
          }).toList();
        });
  }

  Future<void> deleteActivity(String activityId) async {
    if (_userId == null) throw FirestoreException('Usuário não autenticado');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .doc(activityId)
          .delete();
    } catch (e) {
      throw FirestoreException('Erro ao deletar atividade: $e');
    }
  }

  Future<void> deleteAllUserData() async {
    if (_userId == null) return;

    try {
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('activities')
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw FirestoreException('⏱️ Timeout ao buscar atividades para deletar');
            },
          );

      for (var doc in activitiesSnapshot.docs) {
        await doc.reference.delete().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⏱️ Timeout ao deletar atividade ${doc.id}');
          },
        );
      }

      await _firestore.collection('users').doc(_userId).delete().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirestoreException('⏱️ Timeout ao deletar perfil');
        },
      );
    } catch (e) {
      throw FirestoreException('Erro ao deletar dados: $e');
    }
  }
}

class FirestoreException implements Exception {
  final String message;

  FirestoreException(this.message);

  @override
  String toString() => message;
}
