class HourlyWeather {
  final DateTime time;
  final double temperature;
  final double feelsLike;
  final double uvIndex;
  final double windSpeed;
  final double humidity;
  final double precipitation;
  final double precipitationProbability;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.uvIndex,
    required this.windSpeed,
    required this.humidity,
    required this.precipitation,
    required this.precipitationProbability,
  });

  String get weatherIcon {
    if (precipitation > 0.5) return '🌧️';
    if (temperature > 30) return '☀️';
    if (temperature < 15) return '🌥️';
    if (humidity > 80) return '🌫️';
    return '⛅';
  }

  String get weatherCondition {
    if (precipitation > 0.5) return 'Rain';
    if (temperature > 30) return 'Ensolarado';
    if (temperature < 15) return 'Nublado';
    if (humidity > 80) return 'Nevoeiro';
    return 'Parcialmente Nublado';
  }
}
