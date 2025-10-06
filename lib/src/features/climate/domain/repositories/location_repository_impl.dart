import '../../domain/entities/location_suggestion.dart';
import '../../domain/repositories/location_repository.dart';
import '../../data/datasources/geocoding_remote_ds.dart';

class LocationRepositoryImpl implements LocationRepository {
  final GeocodingRemoteDateSource remote;
  LocationRepositoryImpl({required this.remote});
  @override
  Future<List<LocationSuggestion>> search(String query) => remote.search(query);
}
