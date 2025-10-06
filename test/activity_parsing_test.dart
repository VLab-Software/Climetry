import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climetry/src/features/activities/domain/entities/activity.dart';
import 'package:climetry/src/features/friends/domain/entities/friend.dart';

void main() {
  group('Activity.fromJson', () {
    test('parses data saved with current schema', () {
      final json = {
        'id': 'activity-123',
        'title': 'Morning Run',
        'location': 'Central Park',
        'coordinates': {'latitude': -23.5, 'longitude': -46.6},
        'date': DateTime(2025, 10, 5, 8).toIso8601String(),
        'startTime': '08:00',
        'endTime': '09:00',
        'type': 'sport',
        'description': 'Training with friends',
        'notificationsEnabled': true,
        'createdAt': DateTime(2025, 10, 1).toIso8601String(),
        'priority': 'medium',
        'tags': ['training', 'outdoor'],
        'recurrence': 'none',
        'monitoredConditions': ['temperature', 'rain'],
        'ownerId': 'owner-1',
        'participants': [
          EventParticipant(
            userId: 'friend-1',
            name: 'Alice',
            role: EventRole.participant,
            joinedAt: DateTime(2025, 10, 1),
            status: ParticipantStatus.accepted,
          ).toMap(),
        ],
      };

      final activity = Activity.fromJson(json);

      expect(activity.id, 'activity-123');
      expect(activity.title, 'Morning Run');
      expect(activity.location, 'Central Park');
      expect(activity.coordinates.latitude, closeTo(-23.5, 1e-6));
      expect(activity.coordinates.longitude, closeTo(-46.6, 1e-6));
      expect(activity.date, DateTime(2025, 10, 5, 8));
      expect(activity.type, ActivityType.sport);
      expect(activity.priority, ActivityPriority.medium);
      expect(activity.participants, hasLength(1));
    });

    test('parses legacy data with GeoPoint and Timestamps', () {
      final json = {
        'activityId': 'legacy-42',
        'title': 'Legacy Picnic',
        'location': 'Riverside',
        'coordinates': const GeoPoint(40.7, -73.9),
        'date': Timestamp.fromDate(DateTime(2025, 8, 20, 12)),
        'type': 'social',
        'notificationsEnabled': false,
        'createdAt': Timestamp.fromDate(DateTime(2025, 7, 1)),
        'priority': 'high',
        'recurrence': 'monthly',
        'monitoredConditions': [
          {'name': 'wind'},
          'humidity',
        ],
        'ownerId': 'owner-99',
        'participants': [
          {
            'userId': 'friend-7',
            'name': 'Bob',
            'role': 'EventRole.admin',
            'joinedAt': Timestamp.fromDate(DateTime(2025, 7, 10)),
            'status': 'ParticipantStatus.accepted',
          },
          {
            'userId': 'friend-8',
            'name': 'Carol',
            'role': 'participant',
            'joinedAt': DateTime(2025, 7, 11).toIso8601String(),
            'status': 'maybe',
          },
        ],
      };

      final activity = Activity.fromJson(json);

      expect(activity.id, 'legacy-42');
      expect(activity.coordinates.latitude, closeTo(40.7, 1e-6));
      expect(activity.coordinates.longitude, closeTo(-73.9, 1e-6));
      expect(activity.date, DateTime(2025, 8, 20, 12));
      expect(activity.priority, ActivityPriority.high);
      expect(activity.recurrence, RecurrenceType.monthly);
      expect(activity.monitoredConditions, contains(WeatherCondition.wind));
      expect(activity.monitoredConditions, contains(WeatherCondition.humidity));
      expect(activity.participants, hasLength(2));
      expect(activity.participants.first.role, EventRole.admin);
      expect(activity.participants.last.status, ParticipantStatus.maybe);
    });
  });
}
