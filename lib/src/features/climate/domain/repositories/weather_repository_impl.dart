import '../../domain/entities/weather_payload.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../data/datasources/meteomatics_remote_ds.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final MeteomaticsRemoteDataSource remote;
  WeatherRepositoryImpl({required this.remote});

  @override
  Future<WeatherPayload> fetch({
    required String timeRange,
    required String variables,
    required String location,
  }) => remote.fetch(timeRange: timeRange, variables: variables, location: location);
}