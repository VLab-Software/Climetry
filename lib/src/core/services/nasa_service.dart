import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// NASA Open APIs Service - No API key required for these endpoints
/// Documentation: https://api.nasa.gov/
class NasaService {
  // Public NASA API base URL (demo key - rate limited but works without registration)
  static const String _demoKey = 'DEMO_KEY';
  
  /// Get Astronomy Picture of the Day
  /// Returns beautiful space imagery with descriptions
  Future<Map<String, dynamic>?> getAstronomyPictureOfDay() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.nasa.gov/planetary/apod?api_key=$_demoKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching NASA APOD: $e');
    }
    return null;
  }

  /// Get Natural Events from NASA EONET
  /// Returns real-time natural events (storms, fires, floods, etc)
  /// No API key required!
  Future<List<Map<String, dynamic>>> getNaturalEvents({
    int days = 7,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?days=$days&status=open'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['events'] as List;
        return events.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching NASA EONET events: $e');
    }
    return [];
  }

  /// Get natural events by category
  /// Categories: wildfires, storms, floods, volcanoes, etc
  Future<List<Map<String, dynamic>>> getEventsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/categories/$category?status=open'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['events'] != null) {
          final events = data['events'] as List;
          return events.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      print('Error fetching NASA EONET events by category: $e');
    }
    return [];
  }

  /// Get events near a location (within radius in km)
  List<Map<String, dynamic>> filterEventsByLocation(
    List<Map<String, dynamic>> events,
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return events.where((event) {
      final geometries = event['geometry'] as List?;
      if (geometries == null || geometries.isEmpty) return false;

      final firstGeometry = geometries.first;
      final coordinates = firstGeometry['coordinates'] as List?;
      if (coordinates == null || coordinates.length < 2) return false;

      final eventLon = coordinates[0] as double;
      final eventLat = coordinates[1] as double;

      // Simple distance calculation (Haversine formula)
      final distance = _calculateDistance(latitude, longitude, eventLat, eventLon);
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Get category icon for event type
  String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wildfires':
        return '🔥';
      case 'storms':
      case 'severeStorms':
        return '⛈️';
      case 'floods':
        return '🌊';
      case 'volcanoes':
        return '🌋';
      case 'drought':
        return '🏜️';
      case 'dustHaze':
        return '💨';
      case 'earthquakes':
        return '🏚️';
      case 'landslides':
        return '⛰️';
      case 'seaLakeIce':
        return '🧊';
      case 'snow':
        return '❄️';
      case 'temperatureExtremes':
        return '🌡️';
      case 'manmade':
        return '🏭';
      case 'waterColor':
        return '💧';
      default:
        return '🌍';
    }
  }

  /// Get severity level description
  String getSeverityDescription(String? severity) {
    if (severity == null) return 'Monitoring';
    switch (severity.toLowerCase()) {
      case 'warning':
        return '⚠️ Warning';
      case 'watch':
        return '👁️ Watch';
      case 'advisory':
        return 'ℹ️ Advisory';
      default:
        return 'ℹ️ Active';
    }
  }
}
