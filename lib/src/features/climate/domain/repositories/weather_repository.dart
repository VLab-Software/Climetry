import '../entities/weather_payload.dart';

abstract class WeatherRepository {
  Future<WeatherPayload> fetch({
    required String timeRange,
    required String variables,
    required String location,
  });
}
