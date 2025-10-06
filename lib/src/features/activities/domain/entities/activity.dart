import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../friends/domain/entities/friend.dart';

enum ActivityType {
  sport,
  outdoor,
  social,
  work,
  travel,
  other;

  String get label {
    switch (this) {
      case ActivityType.sport:
        return 'Sports';
      case ActivityType.outdoor:
        return 'Outdoor';
      case ActivityType.social:
        return 'Social';
      case ActivityType.work:
        return 'Work';
      case ActivityType.travel:
        return 'Travel';
      case ActivityType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.sport:
        return '🏃';
      case ActivityType.outdoor:
        return '🌳';
      case ActivityType.social:
        return '👥';
      case ActivityType.work:
        return '💼';
      case ActivityType.travel:
        return '✈️';
      case ActivityType.other:
        return '📌';
    }
  }
}

enum ActivityPriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case ActivityPriority.low:
        return 'Low';
      case ActivityPriority.medium:
        return 'Medium';
      case ActivityPriority.high:
        return 'High';
      case ActivityPriority.urgent:
        return 'Critical';
    }
  }

  String get icon {
    switch (this) {
      case ActivityPriority.low:
        return '🔵';
      case ActivityPriority.medium:
        return '🟢';
      case ActivityPriority.high:
        return '🟡';
      case ActivityPriority.urgent:
        return '🔴';
    }
  }
}

enum RecurrenceType {
  none,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.monthly:
        return 'Every month';
      case RecurrenceType.yearly:
        return 'Every year';
    }
  }

  String get icon {
    switch (this) {
      case RecurrenceType.none:
        return '📅';
      case RecurrenceType.weekly:
        return '🔄';
      case RecurrenceType.monthly:
        return '📆';
      case RecurrenceType.yearly:
        return '🎂';
    }
  }
}

enum WeatherCondition {
  temperature,
  rain,
  wind,
  humidity,
  uv;

  String get label {
    switch (this) {
      case WeatherCondition.temperature:
        return 'Temperature';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.wind:
        return 'Wind';
      case WeatherCondition.humidity:
        return 'Humidity';
      case WeatherCondition.uv:
        return 'Índice UV';
    }
  }

  String get icon {
    switch (this) {
      case WeatherCondition.temperature:
        return '🌡️';
      case WeatherCondition.rain:
        return '🌧️';
      case WeatherCondition.wind:
        return '💨';
      case WeatherCondition.humidity:
        return '💧';
      case WeatherCondition.uv:
        return '☀️';
    }
  }
}

class Activity {
  final String id;
  final String title;
  final String location;
  final LatLng coordinates;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final ActivityType type;
  final String? description;
  final bool notificationsEnabled;
  final DateTime createdAt;

  final ActivityPriority priority;
  final List<String> tags;
  final RecurrenceType recurrence;
  final List<WeatherCondition> monitoredConditions;

  final String ownerId; // ID do criador do ewind
  final List<EventParticipant> participants;

  Activity({
    required this.id,
    required this.title,
    required this.location,
    required this.coordinates,
    required this.date,
    this.startTime,
    this.endTime,
    required this.type,
    this.description,
    this.notificationsEnabled = true,
    DateTime? createdAt,
    this.priority = ActivityPriority.low,
    this.tags = const [],
    this.recurrence = RecurrenceType.none,
    this.monitoredConditions = const [
      WeatherCondition.temperature,
      WeatherCondition.rain,
    ],
    required this.ownerId,
    this.participants = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Activity copyWith({
    String? id,
    String? title,
    String? location,
    LatLng? coordinates,
    DateTime? date,
    String? startTime,
    String? endTime,
    ActivityType? type,
    String? description,
    bool? notificationsEnabled,
    DateTime? createdAt,
    ActivityPriority? priority,
    List<String>? tags,
    RecurrenceType? recurrence,
    List<WeatherCondition>? monitoredConditions,
    String? ownerId,
    List<EventParticipant>? participants,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      description: description ?? this.description,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      monitoredConditions: monitoredConditions ?? this.monitoredConditions,
      ownerId: ownerId ?? this.ownerId,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'type': type.name,
      'description': description,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority.name,
      'tags': tags,
      'recurrence': recurrence.name,
      'monitoredConditions': monitoredConditions.map((c) => c.name).toList(),
      'ownerId': ownerId,
      'participants': participants.map((p) => p.toMap()).toList(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['createdAt']);
    final date = _parseDate(json['date']) ?? createdAt;

    return Activity(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : (json['activityId'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled event',
      location: (json['location'] as String?) ?? 'Unknown location',
      coordinates: _parseCoordinates(json['coordinates']),
      date: date ?? createdAt ?? DateTime.now(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.other,
      ),
      description: json['description'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: createdAt ?? DateTime.now(),
      priority: ActivityPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ActivityPriority.low,
      ),
      tags: _parseTags(json['tags']),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      monitoredConditions: _parseMonitoredConditions(
        json['monitoredConditions'],
      ),
      ownerId: (json['ownerId'] as String?)?.trim() ?? '',
      participants: _parseParticipants(json['participants']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static LatLng _parseCoordinates(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }
    if (value is LatLng) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final latitude = value['latitude'] ?? value['lat'] ?? value['Latitude'];
      final longitude =
          value['longitude'] ?? value['lng'] ?? value['Longitude'];

      if (latitude is num && longitude is num) {
        return LatLng(latitude.toDouble(), longitude.toDouble());
      }
      if (latitude is String && longitude is String) {
        final lat = double.tryParse(latitude);
        final lng = double.tryParse(longitude);
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    }
    if (value is List && value.length >= 2) {
      final lat = value[0];
      final lng = value[1];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    return const LatLng(0, 0);
  }

  static List<String> _parseTags(dynamic value) {
    if (value is List) {
      return value.map((tag) => tag?.toString()).whereType<String>().toList();
    }
    return [];
  }

  static List<WeatherCondition> _parseMonitoredConditions(dynamic value) {
    if (value is List) {
      return value.map((condition) {
        final name = condition is Map<String, dynamic>
            ? condition['name']?.toString()
            : condition.toString();
        return WeatherCondition.values.firstWhere(
          (e) => e.name == name,
          orElse: () => WeatherCondition.temperature,
        );
      }).toList();
    }
    return [WeatherCondition.temperature, WeatherCondition.rain];
  }

  static List<EventParticipant> _parseParticipants(dynamic value) {
    if (value is List) {
      return value
          .map((participant) {
            try {
              if (participant is Map<String, dynamic>) {
                return EventParticipant.fromMap(participant);
              }
              if (participant is Map) {
                return EventParticipant.fromMap(
                  participant.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                );
              }
            } catch (e) {
              debugPrint('⚠️ Failed to parse participant: $e');
            }
            return null;
          })
          .whereType<EventParticipant>()
          .toList();
    }
    return [];
  }

  bool isOwner(String userId) => ownerId == userId;

  bool canEdit(String userId) {
    if (isOwner(userId)) return true;
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => EventParticipant(
        userId: '',
        name: '',
        role: EventRole.participant,
        joinedAt: DateTime.now(),
        status: ParticipantStatus.pending,
      ),
    );
    return participant.role.canEdit;
  }

  bool canInvite(String userId) {
    if (isOwner(userId)) return true;
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => EventParticipant(
        userId: '',
        name: '',
        role: EventRole.participant,
        joinedAt: DateTime.now(),
        status: ParticipantStatus.pending,
      ),
    );
    return participant.role.canInvite;
  }

  Activity addParticipant(EventParticipant participant) {
    final updatedParticipants = List<EventParticipant>.from(participants);
    updatedParticipants.add(participant);
    return copyWith(participants: updatedParticipants);
  }

  Activity removeParticipant(String userId) {
    final updatedParticipants = participants
        .where((p) => p.userId != userId)
        .toList();
    return copyWith(participants: updatedParticipants);
  }

  Activity updateParticipantStatus(String userId, ParticipantStatus status) {
    final updatedParticipants = participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(status: status);
      }
      return p;
    }).toList();
    return copyWith(participants: updatedParticipants);
  }

  Activity updateParticipantRole(String userId, EventRole role) {
    final updatedParticipants = participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(role: role);
      }
      return p;
    }).toList();
    return copyWith(participants: updatedParticipants);
  }

  Activity updateParticipantAlertSettings(
    String userId,
    Map<String, dynamic> settings,
  ) {
    final updatedParticipants = participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(customAlertSettings: settings);
      }
      return p;
    }).toList();
    return copyWith(participants: updatedParticipants);
  }

  int get confirmedParticipantsCount {
    return participants
            .where((p) => p.status == ParticipantStatus.accepted)
            .length +
        1; // +1 pelo dono
  }
}
