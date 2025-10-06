import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/friend.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<List<Friend>> getFriends() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error searching amigos: $e');
    }
  }

  Future<void> addFriend(Friend friend) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .doc(friend.id)
          .set(friend.toFirestore());
    } catch (e) {
      throw Exception('Error ao adicionar amigo: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .doc(friendId)
          .delete();
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  Future<void> updateFriendName(String friendId, String newName) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('friends')
          .doc(friendId)
          .update({'name': newName});
    } catch (e) {
      throw Exception('Error updating name: $e');
    }
  }

  Future<void> sendFriendRequest({
    required String toUserId,
    String? message,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final currentUser = _auth.currentUser!;

    try {
      final request = FriendRequest(
        id: '',
        fromUserId: _userId!,
        fromUserName: currentUser.displayName ?? 'User',
        fromUserPhotoUrl: currentUser.photoURL,
        toUserId: toUserId,
        createdAt: DateTime.now(),
        status: FriendRequestStatus.pending,
        message: message,
      );

      await _firestore.collection('friendRequests').add(request.toFirestore());
    } catch (e) {
      throw Exception('Error ao enviar solicitação: $e');
    }
  }

  Future<List<FriendRequest>> getReceivedRequests() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('toUserId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error searching solicitações: $e');
    }
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final friend = Friend(
        id: request.fromUserId,
        name: request.fromUserName,
        photoUrl: request.fromUserPhotoUrl,
        addedAt: DateTime.now(),
      );

      await addFriend(friend);

      final currentUser = _auth.currentUser!;
      await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friends')
          .doc(_userId)
          .set({
            'name': currentUser.displayName ?? 'User',
            'photoUrl': currentUser.photoURL,
            'addedAt': FieldValue.serverTimestamp(),
            'isFromContacts': false,
          });

      await _firestore.collection('friendRequests').doc(request.id).update({
        'status': FriendRequestStatus.accepted.name,
      });
    } catch (e) {
      throw Exception('Error ao aceitar solicitação: $e');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': FriendRequestStatus.rejected.name,
      });
    } catch (e) {
      throw Exception('Error ao rejeitar solicitação: $e');
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return {
        'id': doc.id,
        'name': doc.data()['displayName'] as String?,
        'email': doc.data()['email'] as String?,
        'photoUrl': doc.data()['photoURL'] as String?,
      };
    } catch (e) {
      return null;
    }
  }

  Future<int> getPendingRequestsCount() async {
    if (_userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('toUserId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('toUserId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<FriendRequest>> getPendingRequestsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: _userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendRequest.fromFirestore(doc))
              .toList();
        });
  }
}
