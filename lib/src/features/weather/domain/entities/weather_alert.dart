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
        return 'Onda de Calor';
      case WeatherAlertType.thermalDiscomfort:
        return 'Desconforto Térmico Elevado';
      case WeatherAlertType.intenseCold:
        return 'Frio Intenso';
      case WeatherAlertType.frostRisk:
        return 'Risco de Geada';
      case WeatherAlertType.heavyRain:
        return 'Chuva Intensa';
      case WeatherAlertType.floodRisk:
        return 'Risco de Enchente';
      case WeatherAlertType.severeStorm:
        return 'Tempestade Severa';
      case WeatherAlertType.hailRisk:
        return 'Risco de Granizo';
      case WeatherAlertType.strongWind:
        return 'Ventania Forte';
    }
  }

  String get description {
    switch (this) {
      case WeatherAlertType.heatWave:
        return 'Temperaturas elevadas por 3 ou mais dias seguidos (≥35°C)';
      case WeatherAlertType.thermalDiscomfort:
        return 'Alta temperatura combinada com umidade elevada';
      case WeatherAlertType.intenseCold:
        return 'Temperatura mínima ≤5°C';
      case WeatherAlertType.frostRisk:
        return 'Temperatura mínima ≤3°C - Perigo para agricultura';
      case WeatherAlertType.heavyRain:
        return 'Precipitação >30mm - Risco de alagamentos pontuais';
      case WeatherAlertType.floodRisk:
        return 'Precipitação >50mm - Alto risco de enchentes e deslizamentos';
      case WeatherAlertType.severeStorm:
        return 'CAPE >2000 J/kg - Alto potencial para tempestades';
      case WeatherAlertType.hailRisk:
        return 'Previsão de queda de granizo';
      case WeatherAlertType.strongWind:
        return 'Ventos ≥60 km/h';
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
