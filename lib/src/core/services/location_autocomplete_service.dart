import 'dart:convert';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../network/api_client.dart';

class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final LatLng coordinates;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  }) : coordinates = LatLng(lat, lon);

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}

class LocationAutocompleteService {
  final ApiClient _client;
  Timer? _debounceTimer;

  LocationAutocompleteService({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=10'
        '&addressdetails=1',
      );

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Climetry-App',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationSuggestion.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Erro ao buscar localizações: $e');
      return [];
    }
  }

  Future<List<LocationSuggestion>> searchWithDebounce(
    String query,
    Duration delay,
  ) async {
    final completer = Completer<List<LocationSuggestion>>();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      try {
        final results = await searchLocations(query);
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
