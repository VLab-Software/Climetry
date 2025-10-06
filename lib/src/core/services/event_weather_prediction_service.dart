import 'package:flutter/material.dart';
import '../../features/activities/domain/entities/activity.dart';
import '../../features/weather/data/services/meteomatics_service.dart';
import '../../features/weather/domain/entities/daily_weather.dart';
import '../../features/weather/domain/entities/weather_alert.dart';
import 'openai_service.dart';
import 'dart:convert';

enum EventWeatherRisk {
  safe, // Verde - Sem problemas
  warning, // Amarelo - Atenção necessária
  critical, // Vermelho - Risco alto
  unknown, // Gray - No data yet
}

class EventWeatherAnalysis {
  final Activity activity;
  final DailyWeather? weather;
  final EventWeatherRisk risk;
  final String riskDescription;
  final List<WeatherAlert> alerts;
  final String? aiInsight;
  final List<EventSuggestion> suggestions;
  final DateTime analyzedAt;
  final int daysUntilEvent;

  EventWeatherAnalysis({
    required this.activity,
    this.weather,
    required this.risk,
    required this.riskDescription,
    required this.alerts,
    this.aiInsight,
    required this.suggestions,
    required this.analyzedAt,
    required this.daysUntilEvent,
  });

  bool get needsAttention =>
      risk == EventWeatherRisk.warning || risk == EventWeatherRisk.critical;

  Color get riskColor {
    switch (risk) {
      case EventWeatherRisk.safe:
        return const Color(0xFF10B981);
      case EventWeatherRisk.warning:
        return const Color(0xFFF59E0B);
      case EventWeatherRisk.critical:
        return const Color(0xFFEF4444);
      case EventWeatherRisk.unknown:
        return const Color(0xFF6B7280);
    }
  }

  String get riskLabel {
    switch (risk) {
      case EventWeatherRisk.safe:
        return 'Clima Favorável';
      case EventWeatherRisk.warning:
        return 'Atenção Necessária';
      case EventWeatherRisk.critical:
        return 'Risco Alto';
      case EventWeatherRisk.unknown:
        return 'Analisando...';
    }
  }

  IconData get riskIcon {
    switch (risk) {
      case EventWeatherRisk.safe:
        return Icons.check_circle;
      case EventWeatherRisk.warning:
        return Icons.warning_amber;
      case EventWeatherRisk.critical:
        return Icons.dangerous;
      case EventWeatherRisk.unknown:
        return Icons.help_outline;
    }
  }
}

class EventSuggestion {
  final String title;
  final String description;
  final SuggestionType type;
  final SuggestionPriority priority;
  final String icon;

  EventSuggestion({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.icon,
  });

  factory EventSuggestion.fromJson(Map<String, dynamic> json) {
    return EventSuggestion(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseType(json['type']),
      priority: _parsePriority(json['priority']),
      icon: json['icon'] ?? '💡',
    );
  }

  static SuggestionType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'reschedule':
        return SuggestionType.reschedule;
      case 'relocate':
        return SuggestionType.relocate;
      case 'prepare':
        return SuggestionType.prepare;
      case 'cancel':
        return SuggestionType.cancel;
      default:
        return SuggestionType.other;
    }
  }

  static SuggestionPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return SuggestionPriority.high;
      case 'medium':
        return SuggestionPriority.medium;
      default:
        return SuggestionPriority.low;
    }
  }
}

enum SuggestionType {
  reschedule, // Reagendar horário
  relocate, // Mudar local
  prepare, // Preparation needed
  cancel, // Considerar cancelamento
  other, // Outras sugestões
}

enum SuggestionPriority { high, medium, low }

class EventWeatherPredictionService {
  final MeteomaticsService _weatherService = MeteomaticsService();
  final OpenAIService _aiService = OpenAIService();

  Future<EventWeatherAnalysis> analyzeEvent(Activity activity) async {
    final now = DateTime.now();
    final daysUntil = activity.date.difference(now).inDays;

    try {
      List<DailyWeather> forecasts;

      if (daysUntil <= 7) {
        forecasts = await _weatherService.getWeeklyForecast(
          activity.coordinates,
        );
      } else if (daysUntil <= 30) {
        forecasts = await _weatherService.getMonthlyForecast(
          activity.coordinates,
        );
      } else {
        forecasts = await _weatherService.getSixMonthsForecast(
          activity.coordinates,
        );
      }

      DailyWeather? weather;
      for (final forecast in forecasts) {
        if (forecast.date.day == activity.date.day &&
            forecast.date.month == activity.date.month &&
            forecast.date.year == activity.date.year) {
          weather = forecast;
          break;
        }
      }

      weather ??= forecasts.isEmpty
          ? throw Exception('Sem previsão disponível')
          : forecasts.first;

      final alerts = _analyzeWeatherAlerts(weather, activity);

      final risk = _calculateRisk(weather, activity, alerts);

      final aiAnalysis = await _generateAIAnalysis(
        activity,
        weather,
        alerts,
        risk,
        daysUntil,
      );

      return EventWeatherAnalysis(
        activity: activity,
        weather: weather,
        risk: risk,
        riskDescription: _getRiskDescription(risk, alerts),
        alerts: alerts,
        aiInsight: aiAnalysis['insight'],
        suggestions: aiAnalysis['suggestions'],
        analyzedAt: DateTime.now(),
        daysUntilEvent: daysUntil,
      );
    } catch (e) {
      debugPrint('Error ao analisar ewind ${activity.title}: $e');

      return EventWeatherAnalysis(
        activity: activity,
        weather: null,
        risk: EventWeatherRisk.unknown,
        riskDescription: 'Could not get weather forecast',
        alerts: [],
        suggestions: [],
        analyzedAt: DateTime.now(),
        daysUntilEvent: daysUntil,
      );
    }
  }

  Future<List<EventWeatherAnalysis>> analyzeMultipleEvents(
    List<Activity> activities,
  ) async {
    final futures = activities.map((activity) => analyzeEvent(activity));
    return await Future.wait(futures);
  }

  List<WeatherAlert> _analyzeWeatherAlerts(
    DailyWeather weather,
    Activity activity,
  ) {
    final alerts = <WeatherAlert>[];

    if (weather.precipitation > 30) {
      alerts.add(
        WeatherAlert(
          type: weather.precipitation > 50
              ? WeatherAlertType.floodRisk
              : WeatherAlertType.heavyRain,
          date: weather.date,
          value: weather.precipitation,
          unit: 'mm',
        ),
      );
    }

    if (weather.maxTemp > 35) {
      alerts.add(
        WeatherAlert(
          type: WeatherAlertType.heatWave,
          date: weather.date,
          value: weather.maxTemp,
          unit: '°F',
        ),
      );
    }

    if (weather.minTemp < 5) {
      alerts.add(
        WeatherAlert(
          type: weather.minTemp < 3
              ? WeatherAlertType.frostRisk
              : WeatherAlertType.intenseCold,
          date: weather.date,
          value: weather.minTemp,
          unit: '°F',
        ),
      );
    }

    if (weather.windSpeed > 60) {
      alerts.add(
        WeatherAlert(
          type: WeatherAlertType.strongWind,
          date: weather.date,
          value: weather.windSpeed,
          unit: 'km/h',
        ),
      );
    }

    if (weather.precipitation > 40 && weather.windSpeed > 50) {
      alerts.add(
        WeatherAlert(
          type: WeatherAlertType.severeStorm,
          date: weather.date,
          value: weather.precipitation,
          unit: 'mm',
        ),
      );
    }

    if (activity.type == ActivityType.outdoor) {
      if (weather.precipitationProbability > 70 && weather.precipitation > 5) {
        final hasRainAlert = alerts.any(
          (a) =>
              a.type == WeatherAlertType.heavyRain ||
              a.type == WeatherAlertType.floodRisk,
        );

        if (!hasRainAlert) {
          alerts.add(
            WeatherAlert(
              type: WeatherAlertType.heavyRain,
              date: weather.date,
              value: weather.precipitationProbability,
              unit: '%',
            ),
          );
        }
      }
    }

    return alerts;
  }

  EventWeatherRisk _calculateRisk(
    DailyWeather weather,
    Activity activity,
    List<WeatherAlert> alerts,
  ) {
    if (alerts.isEmpty) {
      return EventWeatherRisk.safe;
    }

    final hasCriticalAlert = alerts.any(
      (a) =>
          a.type == WeatherAlertType.floodRisk ||
          a.type == WeatherAlertType.severeStorm ||
          a.type == WeatherAlertType.hailRisk,
    );

    if (hasCriticalAlert) {
      return EventWeatherRisk.critical;
    }

    if (activity.type == ActivityType.outdoor && alerts.length >= 2) {
      return EventWeatherRisk.critical;
    }

    if (alerts.isNotEmpty) {
      return EventWeatherRisk.warning;
    }

    return EventWeatherRisk.safe;
  }

  String _getRiskDescription(EventWeatherRisk risk, List<WeatherAlert> alerts) {
    if (alerts.isEmpty) {
      return 'Favorable weather conditions for the event';
    }

    final problems = alerts.map((a) => a.type.description).join(', ');

    switch (risk) {
      case EventWeatherRisk.safe:
        return 'Clima adequado, sem preocupações';
      case EventWeatherRisk.warning:
        return 'Atenção: $problems';
      case EventWeatherRisk.critical:
        return 'Risco alto: $problems';
      case EventWeatherRisk.unknown:
        return 'Análise indisponível';
    }
  }

  Future<Map<String, dynamic>> _generateAIAnalysis(
    Activity activity,
    DailyWeather weather,
    List<WeatherAlert> alerts,
    EventWeatherRisk risk,
    int daysUntil,
  ) async {
    try {
      final prompt =
          '''
Você é um assistente especializado em análise climática para ewinds.

**EVENTO:**
- Nome: ${activity.title}
- Tipo: ${activity.type.label}
- Date: ${activity.date.day}/${activity.date.month}/${activity.date.year}
- Faltam: $daysUntil dias
- Local: ${activity.location}

**PREVISÃO CLIMÁTICA:**
- Temperature: ${weather.minTemp.round()}°F - ${weather.maxTemp.round()}°F
- Rain: ${weather.precipitation.round()}mm (${weather.precipitationProbability.round()}% chance)
- Wind: ${weather.windSpeed.round()} mph
- Humidity: ${weather.humidity.round()}%
- UV: ${weather.uvIndex.round()}
- Condição: ${weather.mainCondition}

**ALERTAS DETECTADOS:**
${alerts.isEmpty ? 'No alerts' : alerts.map((a) => '- ${a.type.label}: ${a.value?.round() ?? 0} ${a.unit ?? ''}').join('\n')}

**NÍVEL DE RISCO:** ${risk.name}

RESPONDA EM JSON:
{
  "insight": "Uma análise inteligente e específica sobre o impacto do clima neste ewind. Seja direto e prático.",
  "suggestions": [
    {
      "title": "Título curto",
      "description": "Ação específica recomendada",
      "type": "reschedule|relocate|prepare|cancel|other",
      "priority": "high|medium|low",
      "icon": "emoji apropriado"
    }
  ]
}

REGRAS:
- Se risco crítico: sugira mudanças sérias (reagendar, mudar local)
- Se risco médio: sugira preparação (guarda-rain, protetor solar, etc)
- Se seguro: dê dicas de otimização
- Máximo 3 sugestões, sempre práticas e acionáveis
- Considere que faltam $daysUntil dias (tempo para agir)
''';

      final response = await _aiService.generateEventAnalysis(
        prompt,
        maxTokens: 600,
      );

      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);

        return {
          'insight': data['insight'] ?? 'Análise indisponível',
          'suggestions':
              (data['suggestions'] as List?)
                  ?.map((s) => EventSuggestion.fromJson(s))
                  .toList() ??
              [],
        };
      }
    } catch (e) {
      debugPrint('Error ao gerar análise IA: $e');
    }

    return {
      'insight':
          'Monitore as condições climáticas conforme a data se aproxima.',
      'suggestions': _generateBasicSuggestions(risk, alerts, activity),
    };
  }

  List<EventSuggestion> _generateBasicSuggestions(
    EventWeatherRisk risk,
    List<WeatherAlert> alerts,
    Activity activity,
  ) {
    final suggestions = <EventSuggestion>[];

    if (risk == EventWeatherRisk.critical) {
      suggestions.add(
        EventSuggestion(
          title: 'Considere Reagendar',
          description: 'As condições climáticas apresentam risco alto',
          type: SuggestionType.reschedule,
          priority: SuggestionPriority.high,
          icon: '📅',
        ),
      );
    }

    if (alerts.any((a) => a.type == WeatherAlertType.heavyRain)) {
      suggestions.add(
        EventSuggestion(
          title: 'Prepare-se para Rain',
          description: 'Leve guarda-rain e considere local coberto',
          type: SuggestionType.prepare,
          priority: SuggestionPriority.medium,
          icon: '☔',
        ),
      );
    }

    if (alerts.any((a) => a.type == WeatherAlertType.thermalDiscomfort)) {
      suggestions.add(
        EventSuggestion(
          title: 'Proteção Solar',
          description: 'Use protetor solar e busque sombra',
          type: SuggestionType.prepare,
          priority: SuggestionPriority.medium,
          icon: '☀️',
        ),
      );
    }

    return suggestions;
  }

  bool shouldReanalyze(EventWeatherAnalysis oldAnalysis) {
    final hoursSinceAnalysis = DateTime.now()
        .difference(oldAnalysis.analyzedAt)
        .inHours;

    if (oldAnalysis.daysUntilEvent <= 3 && hoursSinceAnalysis >= 12) {
      return true;
    }

    if (oldAnalysis.daysUntilEvent <= 7 && hoursSinceAnalysis >= 24) {
      return true;
    }

    if (hoursSinceAnalysis >= 168) {
      return true;
    }

    return false;
  }
}
