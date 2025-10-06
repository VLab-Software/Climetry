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
        ? 'Alertas climáticos: ${alerts!.map((a) => '${a.type.label} (${a.value} ${a.unit})').join(', ')}'
        : 'Sem alertas climáticos';

    final prompt = '''
Você é um assistente climático inteligente. Analise as seguintes informações e forneça dicas práticas e concisas (máximo 3-5 dicas):

**Atividade:** ${activity.title}
**Tipo:** ${activity.type.label}
**Data:** ${activity.date.day}/${activity.date.month}/${activity.date.year}
**Local:** ${activity.location}
${activity.description != null ? '**Descrição:** ${activity.description}' : ''}

**Condições Climáticas Previstas:**
- Temperatura: ${weather.minTemp.toInt()}°C - ${weather.maxTemp.toInt()}°C (média: ${weather.meanTemp.toInt()}°C)
- Chuva: ${weather.precipitation.toInt()}mm (${weather.precipitationProbability.toInt()}% de chance)
- Vento: ${weather.windSpeed.toInt()} km/h
- Umidade: ${weather.humidity.toInt()}%
- UV: ${weather.uvIndex.toInt()}
- $alertsText

Forneça recomendações específicas e práticas no formato:
• [dica curta e objetiva sobre o que levar]
• [dica sobre roupas apropriadas]
• [dica sobre horário ideal]
• [cuidado com a saúde se necessário]
• [alternativa em caso de mudança climática]

Seja direto, útil e focado no que a pessoa precisa saber para aproveitar melhor o evento.
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
Você é um assistente de planejamento de eventos. O usuário tem o seguinte evento ao ar livre:

**Atividade:** ${activity.title}
**Tipo:** ${activity.type.label}
**Local atual:** ${activity.location}
**Cidade:** $cityName

**Problema Climático:**
${alerts.map((a) => '- ${a.type.label}: ${a.type.description}').join('\n')}
- Temperatura: ${weather.minTemp.toInt()}°C - ${weather.maxTemp.toInt()}°C
- Chuva: ${weather.precipitation.toInt()}mm (${weather.precipitationProbability.toInt()}%)

O clima está ameaçando o evento. Sugira 3 locais alternativos REAIS e ESPECÍFICOS em $cityName que sejam:
1. Cobertos/protegidos do clima
2. Adequados para ${activity.type.label}
3. Fáceis de encontrar

Responda APENAS em JSON válido:
{
  "reason": "explicação breve do problema climático",
  "alternatives": [
    {
      "name": "Nome do local real",
      "type": "Tipo de local (shopping, ginásio, etc)",
      "reason": "Por que é uma boa alternativa",
      "address": "Endereço aproximado ou região"
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
      'reason': 'Condições climáticas desfavoráveis detectadas',
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
Você é um meteorologista especialista. Analise este alerta climático e forneça insights práticos:

**Alerta:** ${alert.type.label}
**Local:** $location
**Data:** ${alert.date.day}/${alert.date.month}
**Severidade:** ${alert.value} ${alert.unit}

**Condições Previstas:**
- Temperatura: ${weather.minTemp.toInt()}°C - ${weather.maxTemp.toInt()}°C
- Chuva: ${weather.precipitation.toInt()}mm
- Vento: ${weather.windSpeed.toInt()} km/h
- Umidade: ${weather.humidity.toInt()}%

Forneça:
1. **Impacto esperado** (1 frase)
2. **Precauções essenciais** (2-3 itens)
3. **Recomendações práticas** (2-3 itens)

Seja técnico mas acessível. Máximo 150 palavras.
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
Você é um assistente climático. Analise as condições atuais e crie 3 dicas práticas:

**Local:** $location
**Condições Atuais:**
- Temperatura: ${temperature.toInt()}°C
- Umidade: ${humidity.toInt()}%
- UV: ${uvIndex.toInt()}
- Vento: ${windSpeed.toInt()} km/h
- Chuva: ${precipitation.toInt()}mm

Crie 3 cards de dicas no formato JSON:
{
  "cards": [
    {
      "icon": "emoji relevante",
      "title": "Título curto (máx 4 palavras)",
      "tip": "Dica prática (máx 15 palavras)"
    }
  ]
}

Foque em ações práticas que a pessoa pode tomar AGORA.
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
                'title': card['title']?.toString() ?? 'Dica',
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
        'title': 'Hidratação',
        'tip': 'Beba água regularmente ao longo do dia',
      },
      {
        'icon': '🧴',
        'title': 'Proteção Solar',
        'tip': 'Use protetor solar FPS 30+',
      },
      {
        'icon': '👕',
        'title': 'Vestimenta',
        'tip': 'Vista roupas leves e confortáveis',
      },
    ];
  }

  Future<String> generateWeatherNarrative({
    required List<DailyWeather> forecast,
    required String location,
  }) async {
    if (forecast.isEmpty) return 'Sem dados de previsão disponíveis.';

    final next3Days = forecast.take(3).toList();
    final temps = next3Days
        .map((w) => '${w.minTemp.toInt()}-${w.maxTemp.toInt()}°C')
        .join(', ');
    final rains = next3Days
        .map((w) => '${w.precipitationProbability.toInt()}%')
        .join(', ');

    final prompt =
        '''
Você é um meteorologista. Analise a previsão de 3 dias e crie uma narrativa curta e natural:

**Local:** $location
**Próximos 3 dias:**
- Temperaturas: $temps
- Chance de chuva: $rains
- Média de vento: ${next3Days.map((w) => w.windSpeed.toInt()).reduce((a, b) => a + b) ~/ 3} km/h

Crie uma previsão narrativa natural (máximo 40 palavras) que descreva a tendência e dê uma dica prática.
Seja conversacional e amigável.
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
        'title': 'Sem dados disponíveis',
        'description': 'Não há previsão climática para este evento.',
        'rating': 5.0,
        'recommendations': [],
        'whatToBring': [],
        'bestTime': 'Indeterminado',
        'alerts': [],
      };
    }

    final eventWeather = forecast.first;
    final alertsText = alerts?.isNotEmpty == true
        ? alerts!.map((a) => '${a.type.label}: ${a.value} ${a.unit}').join(', ')
        : 'Sem alertas';

    final prompt = '''
Você é um meteorologista especialista. Analise as condições climáticas para o evento e forneça insights detalhados em JSON:

**Evento:** ${activity.title}
**Tipo:** ${activity.type.label}
**Data:** ${activity.date.day}/${activity.date.month}/${activity.date.year}
**Local:** ${activity.location}

**Previsão para o dia:**
- Temperatura: ${eventWeather.minTemp.toInt()}°C - ${eventWeather.maxTemp.toInt()}°C
- Chuva: ${eventWeather.precipitation.toInt()}mm (${eventWeather.precipitationProbability.toInt()}%)
- Vento: ${eventWeather.windSpeed.toInt()} km/h
- Umidade: ${eventWeather.humidity.toInt()}%
- UV: ${eventWeather.uvIndex.toInt()}
- Alertas: $alertsText

**Previsão dos próximos dias:**
${forecast.take(7).map((w) => '${w.date.day}/${w.date.month}: ${w.minTemp.toInt()}-${w.maxTemp.toInt()}°C, ${w.precipitation.toInt()}mm').join('\n')}

Responda APENAS com JSON válido neste formato:
{
  "title": "Título descritivo da análise (máx 50 chars)",
  "description": "Análise geral do clima e impacto no evento (100-150 palavras)",
  "rating": 8.5,
  "recommendations": [
    "Recomendação prática 1",
    "Recomendação prática 2",
    "Recomendação prática 3"
  ],
  "whatToBring": [
    "Item essencial 1",
    "Item essencial 2",
    "Item essencial 3"
  ],
  "bestTime": "Melhor horário para o evento (ex: 'Manhã (8h-12h)' ou 'Tarde (14h-18h)')",
  "alerts": [
    {
      "type": "warning",
      "message": "Mensagem do alerta",
      "icon": "⚠️"
    }
  ],
  "chartData": {
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
- Inclua dados reais de temperatura, chuva e vento para os gráficos
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
      'title': 'Análise Climática - ${activity.title}',
      'description':
          'Condições previstas: temperatura entre ${eventWeather.minTemp.toInt()}°C e ${eventWeather.maxTemp.toInt()}°C, '
          'com ${eventWeather.precipitationProbability.toInt()}% de chance de chuva. '
          'Vento de ${eventWeather.windSpeed.toInt()} km/h e índice UV ${eventWeather.uvIndex.toInt()}.',
      'rating': _calculateRating(eventWeather),
      'recommendations': [
        'Verifique a previsão atualizada próximo à data',
        'Prepare-se para variações de temperatura',
        'Considere levar itens de proteção',
      ],
      'whatToBring': _suggestItems(eventWeather, activity.type),
      'bestTime': _suggestBestTime(eventWeather),
      'alerts': _buildAlerts(alerts ?? []),
      'chartData': {
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
      items.add('Guarda-chuva ou capa de chuva');
    }
    if (weather.uvIndex > 6) {
      items.add('Protetor solar FPS 50+');
    }
    if (weather.maxTemp > 28) {
      items.add('Garrafa de água (1L+)');
    }
    if (weather.minTemp < 15) {
      items.add('Agasalho ou jaqueta');
    }
    if (weather.windSpeed > 30) {
      items.add('Roupas corta-vento');
    }
    
    if (type == ActivityType.sport) {
      items.add('Roupas esportivas adequadas');
    } else if (type == ActivityType.social) {
      items.add('Roupas confortáveis');
    }
    
    return items.isEmpty ? ['Preparação básica recomendada'] : items;
  }

  String _suggestBestTime(DailyWeather weather) {
    if (weather.maxTemp > 32) {
      return 'Manhã (6h-10h) ou fim de tarde (17h-20h)';
    } else if (weather.minTemp < 10) {
      return 'Meio-dia (11h-15h)';
    } else if (weather.precipitationProbability > 50) {
      return 'Verifique previsão horária antes de sair';
    }
    return 'Qualquer horário do dia';
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
      return 'ℹ️ **Análise IA Indisponível**\n\nPara ativar análises inteligentes:\n• Configure a chave OpenAI API\n• Execute com: flutter run --dart-define=OPENAI_API_KEY=sua_chave';
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
                  'Você é um meteorologista especialista e assistente climático. Forneça análises detalhadas, técnicas mas acessíveis, com insights valiosos e recomendações práticas. Use dados meteorológicos para gerar previsões precisas e alternativas viáveis.',
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
        return '🔐 **Erro de Autenticação**\n\nChave OpenAI inválida ou expirada. Verifique sua configuração.';
      } else if (response.statusCode == 429) {
        return '⏱️ **Limite de Requisições**\n\nMuitas requisições. Aguarde alguns instantes e tente novamente.';
      } else {
        throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return '⚠️ **Erro Temporário**\n\nNão foi possível conectar ao serviço de análise IA.\n\nVerifique sua conexão com a internet e tente novamente.';
    }
  }
}
