import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id; // userId do amigo
  final String name; // Nome customizado (pode ser editado)
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime addedAt;
  final bool isFromContacts; // Se foi importado dos contatos

  const Friend({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.addedAt,
    this.isFromContacts = false,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      isFromContacts: data['isFromContacts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'addedAt': Timestamp.fromDate(addedAt),
      'isFromContacts': isFromContacts,
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    DateTime? addedAt,
    bool? isFromContacts,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
      isFromContacts: isFromContacts ?? this.isFromContacts,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhotoUrl;
  final String toUserId;
  final DateTime createdAt;
  final FriendRequestStatus status;
  final String? message;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.toUserId,
    required this.createdAt,
    required this.status,
    this.message,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      fromUserPhotoUrl: data['fromUserPhotoUrl'] as String?,
      toUserId: data['toUserId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      message: data['message'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserId': toUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'message': message,
    };
  }
}

enum FriendRequestStatus { pending, accepted, rejected }

class EventParticipant {
  final String userId;
  final String name;
  final String? photoUrl;
  final EventRole role;
  final DateTime joinedAt;
  final ParticipantStatus status;
  final Map<String, dynamic>? customAlertSettings; // Alertas personalizados do participante

  const EventParticipant({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    required this.status,
    this.customAlertSettings,
  });

  factory EventParticipant.fromMap(Map<String, dynamic> data) {
    return EventParticipant(
      userId: data['userId'] as String,
      name: data['name'] as String,
      photoUrl: data['photoUrl'] as String?,
      role: EventRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => EventRole.participant,
      ),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      status: ParticipantStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ParticipantStatus.pending,
      ),
      customAlertSettings: data['customAlertSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status.name,
      'customAlertSettings': customAlertSettings,
    };
  }
  
  EventParticipant copyWith({
    String? userId,
    String? name,
    String? photoUrl,
    EventRole? role,
    DateTime? joinedAt,
    ParticipantStatus? status,
    Map<String, dynamic>? customAlertSettings,
  }) {
    return EventParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      customAlertSettings: customAlertSettings ?? this.customAlertSettings,
    );
  }
}

enum EventRole {
  owner, // Criador do evento
  admin, // Pode editar e convidar
  moderator, // Pode convidar mas não editar
  participant, // Apenas participa
}

extension EventRoleExtension on EventRole {
  String get label {
    switch (this) {
      case EventRole.owner:
        return 'Dono';
      case EventRole.admin:
        return 'Administrador';
      case EventRole.moderator:
        return 'Moderador';
      case EventRole.participant:
        return 'Participante';
    }
  }

  bool get canEdit => this == EventRole.owner || this == EventRole.admin;
  bool get canInvite => this != EventRole.participant;
  bool get canDelete => this == EventRole.owner;
}

enum ParticipantStatus {
  pending, // Convite pendente
  accepted, // Aceitou o convite
  rejected, // Rejeitou o convite
  maybe, // Talvez
}

extension ParticipantStatusExtension on ParticipantStatus {
  String get label {
    switch (this) {
      case ParticipantStatus.pending:
        return 'Pendente';
      case ParticipantStatus.accepted:
        return 'Confirmado';
      case ParticipantStatus.rejected:
        return 'Recusou';
      case ParticipantStatus.maybe:
        return 'Talvez';
    }
  }

  String get emoji {
    switch (this) {
      case ParticipantStatus.pending:
        return '⏳';
      case ParticipantStatus.accepted:
        return '✅';
      case ParticipantStatus.rejected:
        return '❌';
      case ParticipantStatus.maybe:
        return '🤔';
    }
  }
}
