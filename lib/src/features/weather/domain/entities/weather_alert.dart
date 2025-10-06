enum WeatherAlertType {
  heatWave,
  thermalDiscomfort,
  intenseCold,
  frostRisk,
  heavyRain,
  floodRisk,
  severeStorm,
  hailRisk,
  strongWind;

  String get label {
    switch (this) {
      case WeatherAlertType.heatWave:
        return 'Heat Wave';
      case WeatherAlertType.thermalDiscomfort:
        return 'High Thermal Discomfort';
      case WeatherAlertType.intenseCold:
        return 'Intense Cold';
      case WeatherAlertType.frostRisk:
        return 'Frost Risk';
      case WeatherAlertType.heavyRain:
        return 'Heavy Rain';
      case WeatherAlertType.floodRisk:
        return 'Flood Risk';
      case WeatherAlertType.severeStorm:
        return 'Severe Storm';
      case WeatherAlertType.hailRisk:
        return 'Hail Risk';
      case WeatherAlertType.strongWind:
        return 'Strong Wind';
    }
  }

  String get description {
    switch (this) {
      case WeatherAlertType.heatWave:
        return 'High temperatures for 3 or more consecutive days (≥95°F)';
      case WeatherAlertType.thermalDiscomfort:
        return 'High temperature combined with elevated humidity';
      case WeatherAlertType.intenseCold:
        return 'Minimum temperature ≤41°F';
      case WeatherAlertType.frostRisk:
        return 'Minimum temperature ≤37°F - Danger to agriculture';
      case WeatherAlertType.heavyRain:
        return 'Precipitation >1.2 inches - Risk of localized flooding';
      case WeatherAlertType.floodRisk:
        return 'Precipitation >2 inches - High risk of floods and landslides';
      case WeatherAlertType.severeStorm:
        return 'CAPE >2000 J/kg - High potential for severe storms';
      case WeatherAlertType.hailRisk:
        return 'Hail forecast';
      case WeatherAlertType.strongWind:
        return 'Winds ≥37 mph';
    }
  }
}

class WeatherAlert {
  final WeatherAlertType type;
  final DateTime date;
  final double? value;
  final String? unit;
  final int daysInSequence;

  WeatherAlert({
    required this.type,
    required this.date,
    this.value,
    this.unit,
    this.daysInSequence = 1,
  });
}
