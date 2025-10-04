import '../entities/location_suggestion.dart';

abstract class LocationRepository {
  Future<List<LocationSuggestion>> search(String query);
}
