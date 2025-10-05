import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _keyUseCurrentLocation = 'use_current_location';
  static const String _keySavedLatitude = 'saved_latitude';
  static const String _keySavedLongitude = 'saved_longitude';
  static const String _keySavedLocationName = 'saved_location_name';

  /// Verifica se o usuário tem permissão de localização
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtém a localização atual do usuário
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  /// Converte coordenadas em nome de cidade
  Future<String> getCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) return 'Localização desconhecida';
      
      final place = placemarks.first;
      
      // Retorna apenas o nome principal da cidade (sem estado/país)
      final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      
      return city ?? 'Localização desconhecida';
    } catch (e) {
      print('Erro ao obter nome da cidade: $e');
      return 'Localização desconhecida';
    }
  }

  /// Obtém nome completo (cidade + estado) - opcional
  Future<String> getFullLocationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) return 'Localização desconhecida';
      
      final place = placemarks.first;
      
      final city = place.locality ?? place.subAdministrativeArea;
      final state = place.administrativeArea;
      
      if (city != null && state != null) {
        return '$city, $state';
      } else if (city != null) {
        return city;
      } else if (state != null) {
        return state;
      }
      
      return 'Localização desconhecida';
    } catch (e) {
      print('Erro ao obter nome completo: $e');
      return 'Localização desconhecida';
    }
  }

  /// Salva a preferência de usar localização atual
  Future<void> setUseCurrentLocation(bool use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCurrentLocation, use);
  }

  /// Verifica se deve usar localização atual
  Future<bool> shouldUseCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseCurrentLocation) ?? true; // Default: usar GPS
  }

  /// Salva uma localização personalizada
  Future<void> saveCustomLocation({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySavedLatitude, latitude);
    await prefs.setDouble(_keySavedLongitude, longitude);
    await prefs.setString(_keySavedLocationName, name);
    await setUseCurrentLocation(false);
  }

  /// Obtém a localização salva
  Future<Map<String, dynamic>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    
    final latitude = prefs.getDouble(_keySavedLatitude);
    final longitude = prefs.getDouble(_keySavedLongitude);
    final name = prefs.getString(_keySavedLocationName);
    
    if (latitude == null || longitude == null) return null;
    
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name ?? await getCityName(latitude, longitude),
    };
  }

  /// Obtém a localização ativa (atual ou salva)
  Future<Map<String, dynamic>> getActiveLocation() async {
    final useCurrentLocation = await shouldUseCurrentLocation();
    
    if (useCurrentLocation) {
      final position = await getCurrentPosition();
      
      if (position != null) {
        final name = await getCityName(position.latitude, position.longitude);
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'name': name,
          'coordinates': LatLng(position.latitude, position.longitude),
        };
      }
    }
    
    // Fallback para localização salva ou padrão
    final saved = await getSavedLocation();
    if (saved != null) {
      return {
        ...saved,
        'coordinates': LatLng(saved['latitude'], saved['longitude']),
      };
    }
    
    // Fallback final: São Paulo
    return {
      'latitude': -23.5505,
      'longitude': -46.6333,
      'name': 'São Paulo',
      'coordinates': const LatLng(-23.5505, -46.6333),
    };
  }

  /// Limpa localização salva e volta para GPS
  Future<void> clearSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedLatitude);
    await prefs.remove(_keySavedLongitude);
    await prefs.remove(_keySavedLocationName);
    await setUseCurrentLocation(true);
  }

  /// Busca sugestões de locais pelo nome
  Future<List<Location>> searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);
      return locations;
    } catch (e) {
      print('Erro ao buscar localização: $e');
      return [];
    }
  }

  /// Obtém endereço de uma coordenada
  Future<Placemark?> getPlacemark(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      return placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e) {
      print('Erro ao obter placemark: $e');
      return null;
    }
  }

  /// Calcula distância entre duas coordenadas (em metros)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Stream de atualizações de localização em tempo real
  Stream<LatLng> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Obtém a última localização conhecida
  Future<LatLng?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
