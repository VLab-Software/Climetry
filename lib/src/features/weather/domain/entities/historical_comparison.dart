class HistoricalComparison {
  final DateTime eventDate;
  final double forecastTemperature;
  final double historicalAverageTemperature;
  final double forecastPrecipitation;
  final double historicalAveragePrecipitation;
  final double forecastWindSpeed;
  final double historicalAverageWindSpeed;
  final double forecastHumidity;
  final double historicalAverageHumidity;

  HistoricalComparison({
    required this.eventDate,
    required this.forecastTemperature,
    required this.historicalAverageTemperature,
    required this.forecastPrecipitation,
    required this.historicalAveragePrecipitation,
    required this.forecastWindSpeed,
    required this.historicalAverageWindSpeed,
    required this.forecastHumidity,
    required this.historicalAverageHumidity,
  });

  double get temperatureDifference =>
      forecastTemperature - historicalAverageTemperature;

  double get precipitationDifference =>
      forecastPrecipitation - historicalAveragePrecipitation;

  double get windSpeedDifference => forecastWindSpeed - historicalAverageWindSpeed;

  double get humidityDifference => forecastHumidity - historicalAverageHumidity;

  bool get isBetterThanAverage {
    // Event is better than average if:
    // - Temperature is closer to 68-77°F (20-25°C)
    // - Less precipitation
    // - Lower wind speed
    final tempScore = _getTemperatureScore(forecastTemperature) -
        _getTemperatureScore(historicalAverageTemperature);
    final precipScore = historicalAveragePrecipitation - forecastPrecipitation;
    final windScore = historicalAverageWindSpeed - forecastWindSpeed;

    return (tempScore + precipScore + windScore) > 0;
  }

  double _getTemperatureScore(double temp) {
    // Ideal range: 68-77°F (20-25°C)
    if (temp >= 68 && temp <= 77) return 10;
    if (temp >= 59 && temp <= 86) return 7;
    if (temp >= 50 && temp <= 95) return 4;
    return 0;
  }

  String get comparisonSummary {
    if (isBetterThanAverage) {
      return 'Weather conditions are better than the historical average for this date';
    } else {
      return 'Weather conditions are below the historical average for this date';
    }
  }

  String get temperatureComparison {
    if (temperatureDifference > 5) {
      return '${temperatureDifference.toStringAsFixed(1)}°F warmer than usual';
    } else if (temperatureDifference < -5) {
      return '${temperatureDifference.abs().toStringAsFixed(1)}°F cooler than usual';
    } else {
      return 'Near average temperature';
    }
  }

  String get precipitationComparison {
    if (precipitationDifference > 0.2) {
      return '${(precipitationDifference * 100).toStringAsFixed(0)}% more rain than usual';
    } else if (precipitationDifference < -0.2) {
      return '${(precipitationDifference.abs() * 100).toStringAsFixed(0)}% less rain than usual';
    } else {
      return 'Normal precipitation levels';
    }
  }

  String get windSpeedComparison {
    if (windSpeedDifference > 5) {
      return '${windSpeedDifference.toStringAsFixed(1)} mph windier than usual';
    } else if (windSpeedDifference < -5) {
      return '${windSpeedDifference.abs().toStringAsFixed(1)} mph calmer than usual';
    } else {
      return 'Normal wind conditions';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'eventDate': eventDate.toIso8601String(),
      'forecastTemperature': forecastTemperature,
      'historicalAverageTemperature': historicalAverageTemperature,
      'forecastPrecipitation': forecastPrecipitation,
      'historicalAveragePrecipitation': historicalAveragePrecipitation,
      'forecastWindSpeed': forecastWindSpeed,
      'historicalAverageWindSpeed': historicalAverageWindSpeed,
      'forecastHumidity': forecastHumidity,
      'historicalAverageHumidity': historicalAverageHumidity,
      'temperatureDifference': temperatureDifference,
      'isBetterThanAverage': isBetterThanAverage,
      'comparisonSummary': comparisonSummary,
      'temperatureComparison': temperatureComparison,
      'precipitationComparison': precipitationComparison,
      'windSpeedComparison': windSpeedComparison,
    };
  }
}
