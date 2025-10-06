import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get _userId => _auth.currentUser?.uid;

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

  Future<String> getCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) return 'Localização desconhecida';

      final place = placemarks.first;

      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea;

      return city ?? 'Localização desconhecida';
    } catch (e) {
      print('Erro ao obter nome da cidade: $e');
      return 'Localização desconhecida';
    }
  }

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

  Future<void> setUseCurrentLocation(bool use) async {
    if (_userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .update({
      'preferences.useCurrentLocation': use,
    });
  }

  Future<bool> shouldUseCurrentLocation() async {
    if (_userId == null) return true;
    
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();
        
    if (!doc.exists) return true;
    
    final preferences = doc.data()?['preferences'] as Map<String, dynamic>?;
    return preferences?['useCurrentLocation'] as bool? ?? true;
  }

  Future<void> saveCustomLocation({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    if (_userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .update({
      'preferences.savedLocation': {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
      },
      'preferences.useCurrentLocation': false,
    });
  }

  Future<Map<String, dynamic>?> getSavedLocation() async {
    if (_userId == null) return null;
    
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .get();
        
    if (!doc.exists) return null;
    
    final preferences = doc.data()?['preferences'] as Map<String, dynamic>?;
    final savedLocation = preferences?['savedLocation'] as Map<String, dynamic>?;
    
    if (savedLocation == null) return null;
    
    return {
      'latitude': savedLocation['latitude'] as double,
      'longitude': savedLocation['longitude'] as double,
      'name': savedLocation['name'] as String,
    };
  }

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

    final saved = await getSavedLocation();
    if (saved != null) {
      return {
        ...saved,
        'coordinates': LatLng(saved['latitude'], saved['longitude']),
      };
    }

    return {
      'latitude': -23.5505,
      'longitude': -46.6333,
      'name': 'São Paulo',
      'coordinates': const LatLng(-23.5505, -46.6333),
    };
  }

  Future<void> clearSavedLocation() async {
    if (_userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .update({
      'preferences.savedLocation': FieldValue.delete(),
      'preferences.useCurrentLocation': true,
    });
  }

  Future<List<Location>> searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);
      return locations;
    } catch (e) {
      print('Erro ao buscar localização: $e');
      return [];
    }
  }

  Future<Placemark?> getPlacemark(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      return placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e) {
      print('Erro ao obter placemark: $e');
      return null;
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Stream<LatLng> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

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
