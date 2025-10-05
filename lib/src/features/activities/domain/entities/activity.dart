import 'package:google_maps_flutter/google_maps_flutter.dart';

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
        return 'Esporte';
      case ActivityType.outdoor:
        return 'Ao Ar Livre';
      case ActivityType.social:
        return 'Social';
      case ActivityType.work:
        return 'Trabalho';
      case ActivityType.travel:
        return 'Viagem';
      case ActivityType.other:
        return 'Outro';
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
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      coordinates: LatLng(
        (json['coordinates']['latitude'] as num).toDouble(),
        (json['coordinates']['longitude'] as num).toDouble(),
      ),
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.other,
      ),
      description: json['description'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
