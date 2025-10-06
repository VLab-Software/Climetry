import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/activity.dart';
import '../../../friends/domain/entities/friend.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

      print(
        '✅ ActivityRepository: ${query.docs.length} documentos encontrados',
      );

      final activities = <Activity>[];

      for (final doc in query.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] ??= doc.id;
          activities.add(Activity.fromJson(data));
        } catch (e, stack) {
          print('⚠️ Error ao parsear activity ${doc.id}: $e');
          print(stack);
        }
      }

      print('✅ ActivityRepository: ${activities.length} activitys válidas');
      return activities;
    } catch (e) {
      print('❌ ActivityRepository erro: $e');
      throw Exception('Error loading activitys: $e');
    }
  }

  Stream<List<Activity>> watchAll() {
    print('🔍 WATCH ALL called - userId: $_userId');
    if (_userId == null) {
      print('⚠️ No userId - returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection('activities')
        .where('participantIds', arrayContains: _userId)
        .snapshots()
        .map((snapshot) {
          print('📦 Firestore snapshot received:');
          print('   Documents count: ${snapshot.docs.length}');
          final activities = <Activity>[];

          for (var doc in snapshot.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] ??= doc.id;
              print('   - Doc ${doc.id}:');
              print('     participantIds: ${data['participantIds']}');
              print('     title: ${data['title']}');
              activities.add(Activity.fromJson(data));
            } catch (e, stack) {
              print('❌ Falha ao parsear activity ${doc.id}: $e');
              print(stack);
            }
          }

          return activities;
        });
  }

  Future<Activity?> getById(String id) async {
    try {
      final doc = await _firestore
          .collection('activities')
          .doc(id)
          .get()
          .timeout(
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

      print('💾 Saving activity: ${activity.title}');
      print('💾 Owner: ${activity.ownerId}');
      print('💾 Participants: ${activity.participants.length}');

      final payload = _buildActivityPayload(activity, isUpdate: false);
      final participantIds = List<String>.from(payload['participantIds']);

      final batch = _firestore.batch();

      final activityRef = _firestore.collection('activities').doc(activity.id);
      batch.set(activityRef, payload, SetOptions(merge: true));

      final userActivityRef = _firestore
          .collection('users')
          .doc(activity.ownerId)
          .collection('activities')
          .doc(activity.id);

      batch.set(
        userActivityRef,
        _buildUserActivitySummary(activity, participantIds, isUpdate: false),
        SetOptions(merge: true),
      );

      await batch.commit();

      print('✅ Activity saved successfully to Firestore');
    } catch (e) {
      print('❌ Error saving activity: $e');
      throw Exception('Error ao salvar activity: $e');
    }
  }

  Future<void> update(Activity activity) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final payload = _buildActivityPayload(activity, isUpdate: true);
      final participantIds = List<String>.from(payload['participantIds']);

      final batch = _firestore.batch();

      final activityRef = _firestore.collection('activities').doc(activity.id);
      batch.set(activityRef, payload, SetOptions(merge: true));

      final userActivityRef = _firestore
          .collection('users')
          .doc(activity.ownerId)
          .collection('activities')
          .doc(activity.id);

      batch.set(
        userActivityRef,
        _buildUserActivitySummary(activity, participantIds, isUpdate: true),
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      if (_userId == null) throw Exception('User not authenticated');

      final activityDoc = await _firestore.collection('activities').doc(id).get();

      final batch = _firestore.batch();

      batch.delete(_firestore.collection('activities').doc(id));

      if (activityDoc.exists) {
        final ownerId = activityDoc.data()?['ownerId'] as String?;
        if (ownerId != null && ownerId.isNotEmpty) {
          final userActivityRef = _firestore
              .collection('users')
              .doc(ownerId)
              .collection('activities')
              .doc(id);
          batch.delete(userActivityRef);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error ao deletar activity: $e');
    }
  }

  Future<void> clear() async {
    throw UnimplementedError('Use delete() to remove individual activities');
  }

  Map<String, dynamic> _buildActivityPayload(
    Activity activity, {
    required bool isUpdate,
  }) {
    final data = Map<String, dynamic>.from(activity.toJson());

    data['date'] = Timestamp.fromDate(activity.date);
    if (isUpdate) {
      data.remove('createdAt');
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    data['updatedAt'] = FieldValue.serverTimestamp();

    final participants = (data['participants'] as List)
        .map<Map<String, dynamic>>(
          (p) => Map<String, dynamic>.from(p as Map),
        )
        .toList();

    final ownerId = activity.ownerId;
    final ownerIndex = participants.indexWhere(
      (p) => (p['userId'] ?? p['id']) == ownerId,
    );

    if (ownerIndex == -1 && ownerId.isNotEmpty) {
      participants.insert(0, {
        'userId': ownerId,
        'name': _auth.currentUser?.displayName ?? 'Organizer',
        'photoUrl': _auth.currentUser?.photoURL,
        'role': EventRole.owner.name,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
        'status': ParticipantStatus.accepted.name,
        'customAlertSettings': null,
      });
    } else if (ownerIndex != -1) {
      participants[ownerIndex]['role'] = EventRole.owner.name;
      participants[ownerIndex]['status'] = ParticipantStatus.accepted.name;
    }

    data['participants'] = participants;

    final participantIds = <String>{
      if (ownerId.isNotEmpty) ownerId,
      if (_userId?.isNotEmpty == true) _userId!,
      ...participants
          .map((p) => (p['userId'] ?? p['id'] ?? '').toString())
          .where((id) => id.isNotEmpty),
    }..removeWhere((id) => id.isEmpty);

    data['participantIds'] = participantIds.toList();

    return data;
  }

  Map<String, dynamic> _buildUserActivitySummary(
    Activity activity,
    List<String> participantIds, {
    required bool isUpdate,
  }) {
    return {
      'activityId': activity.id,
      'title': activity.title,
      'date': Timestamp.fromDate(activity.date),
      'location': activity.location,
      'ownerId': activity.ownerId,
      'participantIds': participantIds,
      'type': activity.type.name,
      'priority': activity.priority.name,
      'tags': activity.tags,
      'notificationsEnabled': activity.notificationsEnabled,
      'startTime': activity.startTime,
      'endTime': activity.endTime,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
