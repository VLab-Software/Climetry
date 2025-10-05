import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/location_suggestion.dart';

class GeocodingRemoteDataSource {
  final ApiClient client;
  GeocodingRemoteDataSource({required this.client});

  Future<List<LocationSuggestion>> search(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
    );
    final res = await client.get(uri, headers: {'User-Agent': 'climetry'});
    final list = json.decode(res.body) as List;
    return list
        .map(
          (r) => LocationSuggestion(
            r['display_name'],
            double.parse(r['lat']),
            double.parse(r['lon']),
          ),
        )
        .toList();
  }
}
