import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurrentWeather {
  final double temperature;
  final double temperatureFahrenheit;
  final double feelsLike;
  final double minTemp;
  final double maxTemp;
  final double uvIndex;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double windGust;
  final String? sunrise;
  final String? sunset;
  final double precipitation;
  final double precipitationProbability;
  final LatLng location;
  final DateTime timestamp;

  CurrentWeather({
    required this.temperature,
    required this.temperatureFahrenheit,
    required this.feelsLike,
    required this.minTemp,
    required this.maxTemp,
    required this.uvIndex,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.windGust,
    this.sunrise,
    this.sunset,
    required this.precipitation,
    required this.precipitationProbability,
    required this.location,
    required this.timestamp,
  });

  String get mainCondition {
    if (precipitation > 0.5) return 'Chuva';
    if (temperature > 30) return 'Ensolarado';
    if (temperature < 15) return 'Nublado';
    return 'Parcialmente Nublado';
  }

  String get weatherIcon {
    if (precipitation > 0.5) return '🌧️';
    if (temperature > 30) return '☀️';
    if (temperature < 15) return '☁️';
    return '⛅';
  }

  // Backward compatibility
  double get temperatureC => temperature;
  double get temperatureF => temperatureFahrenheit;
  double get tempMin => minTemp;
  double get tempMax => maxTemp;
  double get windGusts => windGust;
  double get precipProbability => precipitationProbability;
}
