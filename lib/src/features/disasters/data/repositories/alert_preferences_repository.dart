import 'package:shared_preferences/shared_preferences.dart';
import '../../../weather/domain/entities/weather_alert.dart';

class AlertPreferencesRepository {
  static const String _enabledAlertsKey = 'enabled_weather_alerts';
  static const String _monitoringLocationKey = 'monitoring_location';
  static const String _locationNameKey = 'location_name';

  Future<Set<WeatherAlertType>> getEnabledAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledList = prefs.getStringList(_enabledAlertsKey);
      
      if (enabledList == null || enabledList.isEmpty) {
        // Por padrão, habilitar todos os alertas
        return WeatherAlertType.values.toSet();
      }
      
      return enabledList
          .map((name) => WeatherAlertType.values.firstWhere(
                (type) => type.name == name,
                orElse: () => WeatherAlertType.heatWave,
              ))
          .toSet();
    } catch (e) {
      return WeatherAlertType.values.toSet();
    }
  }

  Future<void> saveEnabledAlerts(Set<WeatherAlertType> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledList = alerts.map((type) => type.name).toList();
      await prefs.setStringList(_enabledAlertsKey, enabledList);
    } catch (e) {
      throw Exception('Erro ao salvar preferências: $e');
    }
  }

  Future<Map<String, dynamic>?> getMonitoringLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationStr = prefs.getString(_monitoringLocationKey);
      
      if (locationStr == null) return null;
      
      final parts = locationStr.split(',');
      if (parts.length != 2) return null;
      
      return {
        'latitude': double.parse(parts[0]),
        'longitude': double.parse(parts[1]),
        'name': prefs.getString(_locationNameKey) ?? 'Local Monitorado',
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _monitoringLocationKey,
        '$latitude,$longitude',
      );
      await prefs.setString(_locationNameKey, locationName);
    } catch (e) {
      throw Exception('Erro ao salvar localização: $e');
    }
  }
}
