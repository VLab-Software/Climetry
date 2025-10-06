import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/weather/domain/entities/daily_weather.dart';
import '../../features/weather/domain/entities/weather_alert.dart';
import '../../features/activities/domain/entities/activity.dart';

class OpenAIService {
  // ✅ Carregar API key do .env (seguro e não vai para o Git)
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // ✅ Usar GPT-4o-mini - modelo mais barato e eficiente
  static const String _model = 'gpt-4o-mini';

  /// Gera dicas personalizadas para uma atividade baseada no clima
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

  /// Sugere locais alternativos cobertos quando o clima ameaça evento ao ar livre
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
      // Extrai JSON da resposta
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr);
      }
    } catch (e) {
      // Fallback se JSON parsing falhar
    }

    return {
      'reason': 'Condições climáticas desfavoráveis detectadas',
      'alternatives': [],
    };
  }

  /// Gera insights detalhados sobre um alerta climático
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

  /// Gera cards dinâmicos de dicas baseados nas condições atuais
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
      // Fallback
    }

    // Cards padrão se API falhar
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

  /// Analisa tendência climática e gera previsão narrativa
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

  /// Gera análise específica para um evento
  Future<String> generateEventAnalysis(
    String prompt, {
    int maxTokens = 600,
  }) async {
    return await _makeRequest(prompt, maxTokens: maxTokens);
  }

  /// Requisição genérica para OpenAI
  Future<String> _makeRequest(String prompt, {int maxTokens = 200}) async {
    // Verificar se API key está configurada
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
      // Em caso de erro, retorna mensagem informativa
      return '⚠️ **Erro Temporário**\n\nNão foi possível conectar ao serviço de análise IA.\n\nVerifique sua conexão com a internet e tente novamente.';
    }
  }
}
