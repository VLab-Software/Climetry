import 'package:flutter/material.dart';
import '../../features/activities/domain/entities/activity.dart';
import '../../features/weather/domain/entities/daily_weather.dart';

class CustomAlertsService {
  Future<List<CustomAlert>> checkEventAlerts(
    Activity event,
    DailyWeather weather,
  ) async {
    final alerts = <CustomAlert>[];

    for (final condition in event.monitoredConditions) {
      final alert = _checkCondition(condition, event, weather);
      if (alert != null) {
        alerts.add(alert);
      }
    }

    return alerts;
  }

  Future<Map<String, List<CustomAlert>>> checkMultipleEvents(
    Map<Activity, DailyWeather> eventsWithWeather,
  ) async {
    final Map<String, List<CustomAlert>> allAlerts = {};

    for (final entry in eventsWithWeather.entries) {
      final alerts = await checkEventAlerts(entry.key, entry.value);
      if (alerts.isNotEmpty) {
        allAlerts[entry.key.id] = alerts;
      }
    }

    return allAlerts;
  }

  CustomAlert? _checkCondition(
    WeatherCondition condition,
    Activity event,
    DailyWeather weather,
  ) {
    switch (condition) {
      case WeatherCondition.temperature:
        return _checkTemperature(event, weather);
      case WeatherCondition.rain:
        return _checkRain(event, weather);
      case WeatherCondition.wind:
        return _checkWind(event, weather);
      case WeatherCondition.humidity:
        return _checkHumidity(event, weather);
      case WeatherCondition.uv:
        return _checkUV(event, weather);
    }
  }

  CustomAlert? _checkTemperature(Activity event, DailyWeather weather) {
    if (weather.maxTemp > 35) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.temperature,
        severity: AlertSeverity.high,
        title: 'Temperatura Extrema',
        message:
            'Temperatura prevista de ${weather.maxTemp.toStringAsFixed(1)}°C. '
            'Considere reagendar ou tomar precauções contra o calor.',
        value: weather.maxTemp,
        unit: '°C',
        timestamp: DateTime.now(),
      );
    }

    if (weather.minTemp < 5) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.temperature,
        severity: AlertSeverity.medium,
        title: 'Temperatura Baixa',
        message:
            'Temperatura prevista de ${weather.minTemp.toStringAsFixed(1)}°C. '
            'Vista-se adequadamente e leve agasalhos.',
        value: weather.minTemp,
        unit: '°C',
        timestamp: DateTime.now(),
      );
    }

    final amplitude = weather.maxTemp - weather.minTemp;
    if (amplitude > 15) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.temperature,
        severity: AlertSeverity.low,
        title: 'Grande Variação Térmica',
        message:
            'Diferença de ${amplitude.toStringAsFixed(1)}°C entre mínima e máxima. '
            'Leve roupas extras.',
        value: amplitude,
        unit: '°C',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  CustomAlert? _checkRain(Activity event, DailyWeather weather) {
    if (weather.precipitation > 30) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.rain,
        severity: weather.precipitation > 50
            ? AlertSeverity.high
            : AlertSeverity.medium,
        title: weather.precipitation > 50 ? 'Chuva Intensa' : 'Chuva Forte',
        message:
            'Previsão de ${weather.precipitation.toStringAsFixed(0)}mm de chuva. '
            '${weather.precipitation > 50 ? 'Considere reagendar ou mudar para local coberto.' : 'Leve guarda-chuva e evite áreas abertas.'}',
        value: weather.precipitation,
        unit: 'mm',
        timestamp: DateTime.now(),
      );
    }

    if (weather.precipitation > 10) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.rain,
        severity: AlertSeverity.low,
        title: 'Possibilidade de Chuva',
        message:
            'Previsão de ${weather.precipitation.toStringAsFixed(0)}mm de chuva. '
            'Leve guarda-chuva e planeje rotas cobertas.',
        value: weather.precipitation,
        unit: 'mm',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  CustomAlert? _checkWind(Activity event, DailyWeather weather) {
    if (weather.windSpeed > 60) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.wind,
        severity: AlertSeverity.high,
        title: 'Vento Muito Forte',
        message:
            'Ventos de até ${weather.windSpeed.toStringAsFixed(0)} km/h previstos. '
            'Evite atividades ao ar livre e áreas com árvores.',
        value: weather.windSpeed,
        unit: 'km/h',
        timestamp: DateTime.now(),
      );
    }

    if (weather.windSpeed > 40) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.wind,
        severity: AlertSeverity.medium,
        title: 'Vento Forte',
        message:
            'Ventos de até ${weather.windSpeed.toStringAsFixed(0)} km/h previstos. '
            'Proteja objetos leves e evite áreas abertas.',
        value: weather.windSpeed,
        unit: 'km/h',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  CustomAlert? _checkHumidity(Activity event, DailyWeather weather) {
    if (weather.humidity > 85) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.humidity,
        severity: AlertSeverity.medium,
        title: 'Umidade Elevada',
        message:
            'Umidade de ${weather.humidity.toStringAsFixed(0)}% prevista. '
            'Pode causar desconforto e sensação de calor. Mantenha-se hidratado.',
        value: weather.humidity,
        unit: '%',
        timestamp: DateTime.now(),
      );
    }

    if (weather.humidity < 30) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.humidity,
        severity: AlertSeverity.low,
        title: 'Umidade Baixa',
        message:
            'Umidade de ${weather.humidity.toStringAsFixed(0)}% prevista. '
            'Ar seco pode causar desconforto. Beba bastante água.',
        value: weather.humidity,
        unit: '%',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  CustomAlert? _checkUV(Activity event, DailyWeather weather) {
    if (weather.uvIndex > 8) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.uv,
        severity: AlertSeverity.high,
        title: 'Índice UV Extremo',
        message:
            'Índice UV de ${weather.uvIndex.toStringAsFixed(0)} previsto. '
            'Use protetor solar FPS 50+, chapéu e óculos. Evite exposição das 10h às 16h.',
        value: weather.uvIndex,
        unit: '',
        timestamp: DateTime.now(),
      );
    }

    if (weather.uvIndex > 6) {
      return CustomAlert(
        eventId: event.id,
        eventTitle: event.title,
        condition: WeatherCondition.uv,
        severity: AlertSeverity.medium,
        title: 'Índice UV Alto',
        message:
            'Índice UV de ${weather.uvIndex.toStringAsFixed(0)} previsto. '
            'Use protetor solar FPS 30+, chapéu e óculos de sol.',
        value: weather.uvIndex,
        unit: '',
        timestamp: DateTime.now(),
      );
    }

    return null;
  }
}

class CustomAlert {
  final String eventId;
  final String eventTitle;
  final WeatherCondition condition;
  final AlertSeverity severity;
  final String title;
  final String message;
  final double value;
  final String unit;
  final DateTime timestamp;

  CustomAlert({
    required this.eventId,
    required this.eventTitle,
    required this.condition,
    required this.severity,
    required this.title,
    required this.message,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.low:
        return const Color(0xFFFBBF24); // Amarelo
      case AlertSeverity.medium:
        return const Color(0xFFF59E0B); // Laranja
      case AlertSeverity.high:
        return const Color(0xFFEF4444); // Vermelho
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info_outline;
      case AlertSeverity.medium:
        return Icons.warning_amber;
      case AlertSeverity.high:
        return Icons.error_outline;
    }
  }

  String get conditionLabel {
    switch (condition) {
      case WeatherCondition.temperature:
        return 'Temperatura';
      case WeatherCondition.rain:
        return 'Chuva';
      case WeatherCondition.wind:
        return 'Vento';
      case WeatherCondition.humidity:
        return 'Umidade';
      case WeatherCondition.uv:
        return 'UV';
    }
  }
}

enum AlertSeverity {
  low, // Informativo
  medium, // Atenção
  high, // Crítico
}
