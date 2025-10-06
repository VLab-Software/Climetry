import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/weather/domain/entities/daily_weather.dart';
import '../../features/weather/domain/entities/weather_alert.dart';
import '../../features/activities/domain/entities/activity.dart';

class OpenAIService {
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static const String _model = 'gpt-4o-mini';

  Future<String> generateActivityTips({
    required Activity activity,
    required DailyWeather weather,
    List<WeatherAlert>? alerts,
  }) async {
    final alertsText = alerts?.isNotEmpty == true
        ? 'Weather alerts: ${alerts!.map((a) => '${a.type.label} (${a.value} ${a.unit})').join(', ')}'
        : 'No weather alerts';

    final prompt = '''
You are an intelligent weather assistant. Analyze the following information and provide practical and concise tips (maximum 3-5 tips):

**Event:** ${activity.title}
**Type:** ${activity.type.label}
**Date:** ${activity.date.day}/${activity.date.month}/${activity.date.year}
**Location:** ${activity.location}
${activity.description != null ? '**Description:** ${activity.description}' : ''}

**Forecasted Weather Conditions:**
- Temperature: ${weather.minTemp.toInt()}°F - ${weather.maxTemp.toInt()}°F (média: ${weather.meanTemp.toInt()}°F)
- Rain: ${weather.precipitation.toInt()}mm (${weather.precipitationProbability.toInt()}% chance)
- Wind: ${weather.windSpeed.toInt()} mph
- Humidity: ${weather.humidity.toInt()}%
- UV: ${weather.uvIndex.toInt()}
- $alertsText

Provide specific and practical recommendations in this format:
• [short and objective tip about what to bring]
• [tip about appropriate clothing]
• [tip about ideal time]
• [health precaution if necessary]
• [alternative in case of weather change]

Be direct, helpful, and focused on what the person needs to know to better enjoy the event.
''';

    return await _makeRequest(prompt, maxTokens: 300);
  }

  Future<Map<String, dynamic>> suggestAlternativeLocations({
    required Activity activity,
    required String cityName,
    required DailyWeather weather,
    required List<WeatherAlert> alerts,
  }) async {
    final prompt =
        '''
You are an event planning assistant. The user has the following outdoor event:

**Event:** ${activity.title}
**Type:** ${activity.type.label}
**Current location:** ${activity.location}
**City:** $cityName

**Weather Problem:**
${alerts.map((a) => '- ${a.type.label}: ${a.type.description}').join('\n')}
- Temperature: ${weather.minTemp.toInt()}°F - ${weather.maxTemp.toInt()}°F
- Rain: ${weather.precipitation.toInt()}mm (${weather.precipitationProbability.toInt()}%)

The weather is threatening the event. Suggest 3 REAL and SPECIFIC alternative locations in $cityName that are:
1. Covered/protected from weather
2. Suitable for ${activity.type.label}
3. Easy to find

Respond ONLY in valid JSON:
{
  "reason": "brief explanation of the weather problem",
  "alternatives": [
    {
      "name": "Real location name",
      "type": "Type of venue (mall, gym, etc)",
      "reason": "Why it is a good alternative",
      "address": "Approximate address or area"
    }
  ]
}
''';

    final response = await _makeRequest(prompt, maxTokens: 400);

    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr);
      }
    } catch (e) {
    }

    return {
      'reason': 'Unfavorable weather conditions detected',
      'alternatives': [],
    };
  }

  Future<String> generateAlertInsights({
    required WeatherAlert alert,
    required DailyWeather weather,
    required String location,
  }) async {
    final prompt =
        '''
You are an expert meteorologist. Analyze this weather alert and provide practical insights:

**Alert:** ${alert.type.label}
**Location:** $location
**Date:** ${alert.date.day}/${alert.date.month}
**Severity:** ${alert.value} ${alert.unit}

**Forecasted Conditions:**
- Temperature: ${weather.minTemp.toInt()}°F - ${weather.maxTemp.toInt()}°F
- Rain: ${weather.precipitation.toInt()}mm
- Wind: ${weather.windSpeed.toInt()} mph
- Humidity: ${weather.humidity.toInt()}%

Provide:
1. **Expected impact** (1 sentence)
2. **Essential precautions** (2-3 items)
3. **Practical recommendations** (2-3 items)

Be technical but accessible. Maximum 150 words.
''';

    return await _makeRequest(prompt, maxTokens: 250);
  }

  Future<List<Map<String, String>>> generateWeatherInsightCards({
    required double temperature,
    required double humidity,
    required double uvIndex,
    required double windSpeed,
    required double precipitation,
    required String location,
  }) async {
    final prompt =
        '''
You are a weather assistant. Analyze current conditions and create 3 practical tips:

**Location:** $location
**Current Conditions:**
- Temperature: ${temperature.toInt()}°F
- Humidity: ${humidity.toInt()}%
- UV: ${uvIndex.toInt()}
- Wind: ${windSpeed.toInt()} mph
- Rain: ${precipitation.toInt()}mm

Create 3 tip cards in JSON format:
{
  "cards": [
    {
      "icon": "relevant emoji",
      "title": "Short title (max 4 words)",
      "tip": "Practical tip (max 15 words)"
    }
  ]
}

Focus on practical actions the person can take NOW.
''';

    final response = await _makeRequest(prompt, maxTokens: 250);

    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        if (data['cards'] != null && data['cards'] is List) {
          return List<Map<String, String>>.from(
            (data['cards'] as List).map(
              (card) => {
                'icon': card['icon']?.toString() ?? '💡',
                'title': card['title']?.toString() ?? 'Tip',
                'tip': card['tip']?.toString() ?? '',
              },
            ),
          );
        }
      }
    } catch (e) {
    }

    return [
      {
        'icon': '☀️',
        'title': 'Hydration',
        'tip': 'Drink water regularly throughout the day',
      },
      {
        'icon': '🧴',
        'title': 'Sun Protection',
        'tip': 'Use sunscreen SPF 30+',
      },
      {
        'icon': '👕',
        'title': 'Clothing',
        'tip': 'Wear light and comfortable clothes',
      },
    ];
  }

  Future<String> generateWeatherNarrative({
    required List<DailyWeather> forecast,
    required String location,
  }) async {
    if (forecast.isEmpty) return 'No forecast data available.';

    final next3Days = forecast.take(3).toList();
    final temps = next3Days
        .map((w) => '${w.minTemp.toInt()}-${w.maxTemp.toInt()}°F')
        .join(', ');
    final rains = next3Days
        .map((w) => '${w.precipitationProbability.toInt()}%')
        .join(', ');

    final prompt =
        '''
You are a meteorologist. Analyze the 3-day forecast and create a short, natural narrative:

**Location:** $location
**Next 3 days:**
- Temperatures: $temps
- Chance de rain: $rains
- Média de wind: ${next3Days.map((w) => w.windSpeed.toInt()).reduce((a, b) => a + b) ~/ 3} mph

Create a natural forecast narrative (maximum 40 words) that describes the trend and gives a practical tip.
Be conversational and friendly.
''';

    return await _makeRequest(prompt, maxTokens: 100);
  }

  Future<String> generateEventAnalysis(
    String prompt, {
    int maxTokens = 600,
  }) async {
    return await _makeRequest(prompt, maxTokens: maxTokens);
  }

  Future<Map<String, dynamic>> generateWeatherInsights({
    required Activity activity,
    required List<DailyWeather> forecast,
    List<WeatherAlert>? alerts,
  }) async {
    if (forecast.isEmpty) {
      return {
        'title': 'No data available',
        'description': 'No weather forecast for this event.',
        'rating': 5.0,
        'recommendations': [],
        'whatToBring': [],
        'bestTime': 'Undetermined',
        'alerts': [],
      };
    }

    final eventWeather = forecast.first;
    final alertsText = alerts?.isNotEmpty == true
        ? alerts!.map((a) => '${a.type.label}: ${a.value} ${a.unit}').join(', ')
        : 'Sem alertas';

    final prompt = '''
You are an expert meteorologist. Analyze the weather conditions for the event and provide detailed insights in JSON:

**Event:** ${activity.title}
**Type:** ${activity.type.label}
**Date:** ${activity.date.day}/${activity.date.month}/${activity.date.year}
**Location:** ${activity.location}

**Forecast for the day:**
- Temperature: ${eventWeather.minTemp.toInt()}°F - ${eventWeather.maxTemp.toInt()}°F
- Rain: ${eventWeather.precipitation.toInt()}mm (${eventWeather.precipitationProbability.toInt()}%)
- Wind: ${eventWeather.windSpeed.toInt()} mph
- Humidity: ${eventWeather.humidity.toInt()}%
- UV: ${eventWeather.uvIndex.toInt()}
- Alerts: $alertsText

**Forecast for the coming days:**
${forecast.take(7).map((w) => '${w.date.day}/${w.date.month}: ${w.minTemp.toInt()}-${w.maxTemp.toInt()}°F, ${w.precipitation.toInt()}mm').join('\n')}

Responda APENAS with JSON válido neste formato:
{
  "title": "Descriptive analysis title (max 50 chars)",
  "description": "General weather analysis and event impact (100-150 words)",
  "rating": 8.5,
  "recommendations": [
    "Practical recommendation 1",
    "Practical recommendation 2",
    "Practical recommendation 3"
  ],
  "whatToBring": [
    "Essential item 1",
    "Essential item 2",
    "Essential item 3"
  ],
  "bestTime": "Best time for the event (e.g.: 'Morning (8am-12pm)' or 'Afternoon (2pm-6pm)')",
  "alerts": [
    {
      "type": "warning",
      "message": "Alert message",
      "icon": "⚠️"
    }
  ],
  "chartDate": {
    "temperature": [
      {"time": "${forecast[0].date.toIso8601String()}", "value": ${eventWeather.meanTemp}, "label": "Dia ${forecast[0].date.day}"}
    ],
    "precipitation": [
      {"time": "${forecast[0].date.toIso8601String()}", "value": ${eventWeather.precipitation}, "label": "Dia ${forecast[0].date.day}"}
    ],
    "windSpeed": [
      {"time": "${forecast[0].date.toIso8601String()}", "value": ${eventWeather.windSpeed}, "label": "Dia ${forecast[0].date.day}"}
    ],
    "uvIndex": ${eventWeather.uvIndex}
  }
}

- rating: 0-10, onde 10 = condições perfeitas
- alerts type: "info", "warning" ou "danger"
- Seja específico e útil
- Include real data for temperature, rain and wind for the charts
''';

    final response = await _makeRequest(prompt, maxTokens: 800);

    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr);
      }
    } catch (e) {
    }

    return {
      'title': 'Weather Analysis - ${activity.title}',
      'description':
          'Forecasted conditions: temperature entre ${eventWeather.minTemp.toInt()}°F e ${eventWeather.maxTemp.toInt()}°F, '
          'with ${eventWeather.precipitationProbability.toInt()}% chance de rain. '
          'Wind de ${eventWeather.windSpeed.toInt()} mph and UV index ${eventWeather.uvIndex.toInt()}.',
      'rating': _calculateRating(eventWeather),
      'recommendations': [
        'Check updated forecast close to the date',
        'Prepare for temperature variations',
        'Consider bringing protective items',
      ],
      'whatToBring': _suggestItems(eventWeather, activity.type),
      'bestTime': _suggestBestTime(eventWeather),
      'alerts': _buildAlerts(alerts ?? []),
      'chartDate': {
        'temperature': forecast.take(7).map((w) => {
          'time': w.date.toIso8601String(),
          'value': w.meanTemp,
          'label': 'Dia ${w.date.day}'
        }).toList(),
        'precipitation': forecast.take(7).map((w) => {
          'time': w.date.toIso8601String(),
          'value': w.precipitation,
          'label': 'Dia ${w.date.day}'
        }).toList(),
        'windSpeed': forecast.take(7).map((w) => {
          'time': w.date.toIso8601String(),
          'value': w.windSpeed,
          'label': 'Dia ${w.date.day}'
        }).toList(),
        'uvIndex': eventWeather.uvIndex,
      },
    };
  }

  double _calculateRating(DailyWeather weather) {
    double rating = 10.0;
    
    if (weather.maxTemp > 35 || weather.minTemp < 5) rating -= 2;
    if (weather.maxTemp > 38 || weather.minTemp < 0) rating -= 2;
    
    if (weather.precipitationProbability > 50) rating -= 2;
    if (weather.precipitationProbability > 80) rating -= 2;
    
    if (weather.windSpeed > 40) rating -= 1;
    if (weather.windSpeed > 60) rating -= 2;
    
    return rating.clamp(0, 10);
  }

  List<String> _suggestItems(DailyWeather weather, ActivityType type) {
    final items = <String>[];
    
    if (weather.precipitationProbability > 30) {
      items.add('Umbrella or raincoat');
    }
    if (weather.uvIndex > 6) {
      items.add('Sunscreen SPF 50+');
    }
    if (weather.maxTemp > 28) {
      items.add('Water bottle (1L+)');
    }
    if (weather.minTemp < 15) {
      items.add('Sweater or jacket');
    }
    if (weather.windSpeed > 30) {
      items.add('Windbreaker clothing');
    }
    
    if (type == ActivityType.sport) {
      items.add('Appropriate sportswear');
    } else if (type == ActivityType.social) {
      items.add('Comfortable clothing');
    }
    
    return items.isEmpty ? ['Basic preparation recommended'] : items;
  }

  String _suggestBestTime(DailyWeather weather) {
    if (weather.maxTemp > 32) {
      return 'Morning (6am-10am) or late afternoon (5pm-8pm)';
    } else if (weather.minTemp < 10) {
      return 'Midday (11am-3pm)';
    } else if (weather.precipitationProbability > 50) {
      return 'Check hourly forecast before leaving';
    }
    return 'Any time of day';
  }

  List<Map<String, dynamic>> _buildAlerts(List<WeatherAlert> alerts) {
    return alerts.map((alert) {
      String type = 'info';
      String icon = 'ℹ️';
      
      final value = alert.value ?? 0;
      if (value > 30) {
        type = 'danger';
        icon = '⛔';
      } else if (value > 15) {
        type = 'warning';
        icon = '⚠️';
      }
      
      return {
        'type': type,
        'message': '${alert.type.label}: ${alert.type.description}',
        'icon': icon,
      };
    }).toList();
  }

  Future<String> _makeRequest(String prompt, {int maxTokens = 200}) async {
    if (_apiKey.isEmpty) {
      return 'ℹ️ **AI Analysis Unavailable**\n\nTo enable intelligent analysis:\n• Configure the OpenAI API key\n• Run with: flutter run --dart-define=OPENAI_API_KEY=your_key';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model, // gpt-4o-mini - mais barato e eficiente
          'messages': [
            {
              'role': 'system',
              'content':
                  'Você é um meteorologista especialista e assistente climático. Forneça análises detalhadas, técnicas mas acessíveis, with insights valiosos e recomendações práticas. Use dados meteorológicos para gerar previsões precisas e alternativas viáveis.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else if (response.statusCode == 401) {
        return '🔐 **Authentication Error**\n\nInvalid or expired OpenAI key. Check your configuration.';
      } else if (response.statusCode == 429) {
        return '⏱️ **Request Limit**\n\nToo many requests. Wait a few moments and try again.';
      } else {
        throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return '⚠️ **Temporary Error**\n\nCould not connect to AI analysis service.\n\nCheck your internet connection and try again.';
    }
  }
}
