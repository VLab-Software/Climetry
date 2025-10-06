import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../weather/domain/entities/weather_alert.dart';

class AlertPreferencesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get _userId => _auth.currentUser?.uid;

  Future<Set<WeatherAlertType>> getEnabledAlerts() async {
    try {
      if (_userId == null) return WeatherAlertType.values.toSet();
      
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();
          
      if (!doc.exists) return WeatherAlertType.values.toSet();
      
      final preferences = doc.data()?['preferences'] as Map<String, dynamic>?;
      final enabledList = preferences?['enabledAlerts'] as List?;

      if (enabledList == null || enabledList.isEmpty) {
        return WeatherAlertType.values.toSet();
      }

      return enabledList
          .map(
            (name) => WeatherAlertType.values.firstWhere(
              (type) => type.name == name,
              orElse: () => WeatherAlertType.heatWave,
            ),
          )
          .toSet();
    } catch (e) {
      return WeatherAlertType.values.toSet();
    }
  }

  Future<void> saveEnabledAlerts(Set<WeatherAlertType> alerts) async {
    try {
      if (_userId == null) return;
      
      final enabledList = alerts.map((type) => type.name).toList();
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'preferences.enabledAlerts': enabledList,
      });
    } catch (e) {
      throw Exception('Error ao salvar preferências: $e');
    }
  }

  Future<Map<String, dynamic>?> getMonitoringLocation() async {
    try {
      if (_userId == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();
          
      if (!doc.exists) return null;
      
      final preferences = doc.data()?['preferences'] as Map<String, dynamic>?;
      final monitoringLocation = preferences?['monitoringLocation'] as Map<String, dynamic>?;

      if (monitoringLocation == null) return null;

      return {
        'latitude': monitoringLocation['latitude'] as double,
        'longitude': monitoringLocation['longitude'] as double,
        'name': monitoringLocation['name'] as String? ?? 'Local Monitorado',
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> saveMonitoringLocation(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    try {
      if (_userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .update({
        'preferences.monitoringLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'name': locationName,
        },
      });
    } catch (e) {
      throw Exception('Error ao salvar location: $e');
    }
  }
}
