class DailyWeather {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final double meanTemp;
  final double precipitation;
  final double windSpeed;
  final double? windGust;
  final double humidity;
  final double uvIndex;
  final double? cape;
  final double precipitationProbability;
  final double? hail;

  DailyWeather({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.meanTemp,
    required this.precipitation,
    required this.windSpeed,
    this.windGust,
    required this.humidity,
    required this.uvIndex,
    this.cape,
    required this.precipitationProbability,
    this.hail,
  });

  String get weatherIcon {
    if (precipitation > 30) return '🌧️';
    if (maxTemp > 32) return '🌡️';
    if (minTemp < 10) return '🥶';
    if (hail != null && hail! > 0) return '🧊';
    if (windGust != null && windGust! > 60) return '💨';
    return '⛅';
  }

  String get mainCondition {
    if (precipitation > 30) return 'Rain';
    if (maxTemp > 32) return 'Calor';
    if (minTemp < 10) return 'Frio';
    if (hail != null && hail! > 0) return 'Granizo';
    if (windGust != null && windGust! > 60) return 'Ventania';
    return 'Parcialmente Nublado';
  }

  double get tempMin => minTemp;
  double get tempMax => maxTemp;
  double get tempMean => meanTemp;
  double get windGusts => windGust ?? 0;
  double get precipProbability => precipitationProbability;
}
