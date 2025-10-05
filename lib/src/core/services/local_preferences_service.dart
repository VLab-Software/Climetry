import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Serviço de preferências LOCAL - SEM FIREBASE
/// Preferências do usuário são armazenadas localmente no dispositivo
/// Isso evita travamentos e delays causados pelo Firestore
class LocalPreferencesService {
  static const String _keyTemperatureUnit = 'temperature_unit';
  static const String _keyWindUnit = 'wind_unit';
  static const String _keyPrecipitationUnit = 'precipitation_unit';
  static const String _keyUseCurrentLocation = 'use_current_location';
  static const String _keyMonitoringLocation = 'monitoring_location';
  static const String _keyMonitoringLat = 'monitoring_lat';
  static const String _keyMonitoringLng = 'monitoring_lng';
  static const String _keyLanguage = 'language';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  /// Obter instância do SharedPreferences
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ============ UNIDADES DE MEDIDA ============

  Future<String> getTemperatureUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_keyTemperatureUnit) ?? 'celsius';
  }

  Future<void> setTemperatureUnit(String unit) async {
    final prefs = await _prefs;
    await prefs.setString(_keyTemperatureUnit, unit);
    debugPrint('📝 Temperatura unit saved: $unit');
  }

  Future<String> getWindUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_keyWindUnit) ?? 'kmh';
  }

  Future<void> setWindUnit(String unit) async {
    final prefs = await _prefs;
    await prefs.setString(_keyWindUnit, unit);
    debugPrint('📝 Wind unit saved: $unit');
  }

  Future<String> getPrecipitationUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_keyPrecipitationUnit) ?? 'mm';
  }

  Future<void> setPrecipitationUnit(String unit) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPrecipitationUnit, unit);
    debugPrint('📝 Precipitation unit saved: $unit');
  }

  // ============ LOCALIZAÇÃO ============

  Future<bool> getUseCurrentLocation() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyUseCurrentLocation) ?? true;
  }

  Future<void> setUseCurrentLocation(bool use) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyUseCurrentLocation, use);
    debugPrint('📝 Use current location saved: $use');
  }

  Future<String?> getMonitoringLocation() async {
    final prefs = await _prefs;
    return prefs.getString(_keyMonitoringLocation);
  }

  Future<void> setMonitoringLocation(String? location, double? lat, double? lng) async {
    final prefs = await _prefs;
    if (location != null) {
      await prefs.setString(_keyMonitoringLocation, location);
    } else {
      await prefs.remove(_keyMonitoringLocation);
    }
    
    if (lat != null && lng != null) {
      await prefs.setDouble(_keyMonitoringLat, lat);
      await prefs.setDouble(_keyMonitoringLng, lng);
    } else {
      await prefs.remove(_keyMonitoringLat);
      await prefs.remove(_keyMonitoringLng);
    }
    
    debugPrint('📝 Monitoring location saved: $location');
  }

  Future<Map<String, double>?> getMonitoringCoordinates() async {
    final prefs = await _prefs;
    final lat = prefs.getDouble(_keyMonitoringLat);
    final lng = prefs.getDouble(_keyMonitoringLng);
    
    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  // ============ IDIOMA ============

  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLanguage) ?? 'pt_BR';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLanguage, language);
    debugPrint('📝 Language saved: $language');
  }

  // ============ NOTIFICAÇÕES ============

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    debugPrint('📝 Notifications enabled saved: $enabled');
  }

  // ============ OBTER TODAS AS PREFERÊNCIAS ============

  Future<Map<String, dynamic>> getAllPreferences() async {
    return {
      'temperatureUnit': await getTemperatureUnit(),
      'windUnit': await getWindUnit(),
      'precipitationUnit': await getPrecipitationUnit(),
      'useCurrentLocation': await getUseCurrentLocation(),
      'monitoringLocation': await getMonitoringLocation(),
      'monitoringCoordinates': await getMonitoringCoordinates(),
      'language': await getLanguage(),
      'notificationsEnabled': await getNotificationsEnabled(),
    };
  }

  // ============ LIMPAR TODAS AS PREFERÊNCIAS ============

  Future<void> clearAllPreferences() async {
    final prefs = await _prefs;
    await prefs.clear();
    debugPrint('🗑️ All preferences cleared');
  }

  // ============ RESETAR PARA PADRÃO ============

  Future<void> resetToDefaults() async {
    await setTemperatureUnit('celsius');
    await setWindUnit('kmh');
    await setPrecipitationUnit('mm');
    await setUseCurrentLocation(true);
    await setMonitoringLocation(null, null, null);
    await setLanguage('pt_BR');
    await setNotificationsEnabled(true);
    debugPrint('🔄 Preferences reset to defaults');
  }
}
