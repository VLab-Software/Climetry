import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/entities/hourly_weather.dart';
import '../../domain/entities/daily_weather.dart';
import '../../domain/entities/weather_alert.dart';

class MeteomaticsService {
  String get _username => dotenv.env['METEOMATICS_USERNAME'] ?? '';
  String get _password => dotenv.env['METEOMATICS_PASSWORD'] ?? '';
  static const String _baseUrl = 'api.meteomatics.com';

  String get _credentials => base64Encode(utf8.encode('$_username:$_password'));

  Map<String, String> get _headers => {
    'Authorization': 'Basic $_credentials',
    'Content-Type': 'application/json',
  };

  Future<CurrentWeather> getCurrentWeather(LatLng location) async {
    final params = [
      't_2m:C',
      't_2m:F',
      't_apparent:C',
      't_min_2m_24h:C',
      't_max_2m_24h:C',
      'uv:idx',
      'relative_humidity_2m:p',
      'wind_speed_10m:kmh',
      'wind_dir_10m:d',
      'wind_gusts_10m_1h:kmh',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/now/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseCurrentWeather(data, location);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar clima atual: $e');
    }
  }

  Future<List<HourlyWeather>> getHourlyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final future24h = now.add(const Duration(hours: 24));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = future24h.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_2m:C',
      't_apparent:C',
      'uv:idx',
      'wind_speed_10m:kmh',
      'relative_humidity_2m:p',
      'precip_1h:mm',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr--$endStr:PT1H/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseHourlyForecast(data);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão horária: $e');
    }
  }

  Future<List<DailyWeather>> getWeeklyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 7));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:C',
      't_min_2m_24h:C',
      'precip_24h:mm',
      'wind_gusts_10m_24h:kmh',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:kmh',
      'hail:cm',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr--$endStr:P1D/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDailyForecast(data);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão semanal: $e');
    }
  }

  Future<List<DailyWeather>> getMonthlyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 30));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:C',
      't_min_2m_24h:C',
      'precip_24h:mm',
      'wind_gusts_10m_24h:kmh',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:kmh',
      'hail:cm',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr--$endStr:P1D/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDailyForecast(data);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão mensal: $e');
    }
  }

  Future<List<DailyWeather>> getSixMonthsForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 180));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:C',
      't_min_2m_24h:C',
      'precip_24h:mm',
      'wind_gusts_10m_24h:kmh',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:kmh',
      'hail:cm',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr--$endStr:P1D/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDailyForecast(data);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão semestral: $e');
    }
  }

  Future<Map<String, double>> getClimateAnomalies(LatLng location) async {
    final params = [
      't_2m:C',
      't_2m_10y_mean:C',
      'anomaly_t_mean_2m_24h:C',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/now/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['data'] as List;

        double getParam(String paramName) {
          try {
            final paramData = dataList.firstWhere(
              (d) => d['parameter'] == paramName,
              orElse: () => {
                'coordinates': [
                  {
                    'dates': [
                      {'value': 0},
                    ],
                  },
                ],
              },
            );
            final dates = paramData['coordinates'][0]['dates'] as List;
            return (dates[0]['value'] as num?)?.toDouble() ?? 0;
          } catch (e) {
            return 0;
          }
        }

        return {
          'current': getParam('t_2m:C'),
          'historical_mean': getParam('t_2m_10y_mean:C'),
          'anomaly': getParam('anomaly_t_mean_2m_24h:C'),
        };
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar anomalias climáticas: $e');
    }
  }

  Future<Map<String, dynamic>> getSunAndPrecipitation(LatLng location) async {
    final params = [
      'sunrise:sql',
      'sunset:sql',
      'precip_1h:mm',
      'prob_precip_1h:p',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/now/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['data'] as List;

        dynamic getParam(String paramName) {
          try {
            final paramData = dataList.firstWhere(
              (d) => d['parameter'] == paramName,
              orElse: () => {
                'coordinates': [
                  {
                    'dates': [
                      {'value': null},
                    ],
                  },
                ],
              },
            );
            final dates = paramData['coordinates'][0]['dates'] as List;
            return dates[0]['value'];
          } catch (e) {
            return null;
          }
        }

        return {
          'sunrise': getParam('sunrise:sql'),
          'sunset': getParam('sunset:sql'),
          'precipitation': (getParam('precip_1h:mm') as num?)?.toDouble() ?? 0,
          'precipitation_probability':
              (getParam('prob_precip_1h:p') as num?)?.toDouble() ?? 0,
        };
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar horários do sol: $e');
    }
  }

  List<WeatherAlert> calculateWeatherAlerts(List<DailyWeather> forecast) {
    final alerts = <WeatherAlert>[];

    int heatWaveDays = 0;
    for (var i = 0; i < forecast.length; i++) {
      final day = forecast[i];
      if (day.maxTemp >= 35) {
        heatWaveDays++;
        if (heatWaveDays >= 3) {
          alerts.add(
            WeatherAlert(
              type: WeatherAlertType.heatWave,
              date: day.date,
              value: day.maxTemp,
              unit: '°C',
              daysInSequence: heatWaveDays,
            ),
          );
          break;
        }
      } else {
        heatWaveDays = 0;
      }
    }

    for (var day in forecast) {
      if (day.maxTemp >= 30 && day.humidity >= 60) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.thermalDiscomfort,
            date: day.date,
            value: day.maxTemp,
            unit: '°C',
          ),
        );
      }

      if (day.minTemp <= 5) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.intenseCold,
            date: day.date,
            value: day.minTemp,
            unit: '°C',
          ),
        );
      }

      if (day.minTemp <= 3) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.frostRisk,
            date: day.date,
            value: day.minTemp,
            unit: '°C',
          ),
        );
      }

      if (day.precipitation > 30) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.heavyRain,
            date: day.date,
            value: day.precipitation,
            unit: 'mm',
          ),
        );
      }

      if (day.precipitation > 50) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.floodRisk,
            date: day.date,
            value: day.precipitation,
            unit: 'mm',
          ),
        );
      }

      if (day.cape != null && day.cape! > 2000) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.severeStorm,
            date: day.date,
            value: day.cape,
            unit: 'J/kg',
          ),
        );
      }

      if (day.hail != null && day.hail! > 0) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.hailRisk,
            date: day.date,
            value: day.hail,
            unit: 'cm',
          ),
        );
      }

      if (day.windGust != null && day.windGust! >= 60) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.strongWind,
            date: day.date,
            value: day.windGust,
            unit: 'km/h',
          ),
        );
      }
    }

    return alerts;
  }

  Future<DailyWeather> getEventDayForecast(
    LatLng location,
    DateTime eventDate,
  ) async {
    final eventUtc = eventDate.toUtc();
    final startStr = eventUtc.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:C',
      't_min_2m_24h:C',
      't_mean_2m_24h:C',
      'precip_24h:mm',
      'prob_precip_1h:p',
      'wind_speed_mean_10m_24h:kmh',
      'wind_gusts_10m_24h:kmh',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['data'] as List;

        double getParam(String paramName) {
          try {
            final paramData = dataList.firstWhere(
              (d) => d['parameter'] == paramName,
              orElse: () => {
                'coordinates': [
                  {
                    'dates': [
                      {'value': 0},
                    ],
                  },
                ],
              },
            );
            final dates = paramData['coordinates'][0]['dates'] as List;
            return (dates[0]['value'] as num?)?.toDouble() ?? 0;
          } catch (e) {
            return 0;
          }
        }

        final minTemp = getParam('t_min_2m_24h:C');
        final maxTemp = getParam('t_max_2m_24h:C');
        final meanTemp = getParam('t_mean_2m_24h:C');

        return DailyWeather(
          date: eventDate,
          minTemp: minTemp,
          maxTemp: maxTemp,
          meanTemp: meanTemp > 0 ? meanTemp : (minTemp + maxTemp) / 2,
          precipitation: getParam('precip_24h:mm'),
          precipitationProbability: getParam('prob_precip_1h:p'),
          windSpeed: getParam('wind_speed_mean_10m_24h:kmh'),
          windGust: getParam('wind_gusts_10m_24h:kmh'),
          humidity: getParam('relative_humidity_2m:p'),
          uvIndex: getParam('uv:idx'),
          cape: getParam('cape:Jkg'),
          hail: 0,
        );
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão para data específica: $e');
    }
  }

  Future<List<HourlyWeather>> getEventDayHourlyForecast(
    LatLng location,
    DateTime eventDate,
  ) async {
    final eventStart = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      0,
      0,
    ).toUtc();
    final eventEnd = eventStart.add(const Duration(hours: 24));

    final startStr = eventStart.toIso8601String().split('.')[0] + 'Z';
    final endStr = eventEnd.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_2m:C',
      't_apparent:C',
      'precip_1h:mm',
      'prob_precip_1h:p',
      'wind_speed_10m:kmh',
      'wind_gusts_10m_1h:kmh',
      'relative_humidity_2m:p',
      'uv:idx',
      'weather_symbol_1h:idx',
      'visibility:km',
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$startStr--$endStr:PT1H/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseHourlyForecastExtended(data);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar previsão horária do evento: $e');
    }
  }

  Future<Map<String, dynamic>> detectWeatherChanges({
    required LatLng location,
    required DateTime eventDate,
    required DailyWeather previousForecast,
  }) async {
    try {
      final currentForecast = await getEventDayForecast(location, eventDate);

      final changes = <String, dynamic>{
        'hasChanges': false,
        'significantChanges': <Map<String, dynamic>>[],
        'previousForecast': previousForecast,
        'currentForecast': currentForecast,
      };

      
      final tempDiff = (currentForecast.maxTemp - previousForecast.maxTemp).abs();
      if (tempDiff >= 3) {
        changes['hasChanges'] = true;
        (changes['significantChanges'] as List).add({
          'type': 'temperature',
          'message': tempDiff > 0
              ? 'Temperatura máxima aumentou ${tempDiff.toInt()}°C'
              : 'Temperatura máxima diminuiu ${tempDiff.toInt()}°C',
          'severity': tempDiff >= 5 ? 'high' : 'medium',
          'icon': '🌡️',
          'previous': previousForecast.maxTemp,
          'current': currentForecast.maxTemp,
        });
      }

      final rainDiff = (currentForecast.precipitationProbability - 
          previousForecast.precipitationProbability).abs();
      if (rainDiff >= 20) {
        changes['hasChanges'] = true;
        (changes['significantChanges'] as List).add({
          'type': 'precipitation',
          'message': currentForecast.precipitationProbability > 
              previousForecast.precipitationProbability
              ? 'Chance de chuva aumentou ${rainDiff.toInt()}%'
              : 'Chance de chuva diminuiu ${rainDiff.toInt()}%',
          'severity': currentForecast.precipitationProbability > 70 ? 'high' : 'medium',
          'icon': '🌧️',
          'previous': previousForecast.precipitationProbability,
          'current': currentForecast.precipitationProbability,
        });
      }

      final precipDiff = (currentForecast.precipitation - 
          previousForecast.precipitation).abs();
      if (precipDiff >= 10) {
        changes['hasChanges'] = true;
        (changes['significantChanges'] as List).add({
          'type': 'precipitation_amount',
          'message': 'Volume de chuva previsto mudou ${precipDiff.toInt()}mm',
          'severity': currentForecast.precipitation > 30 ? 'high' : 'medium',
          'icon': '💧',
          'previous': previousForecast.precipitation,
          'current': currentForecast.precipitation,
        });
      }

      final windDiff = (currentForecast.windSpeed - previousForecast.windSpeed).abs();
      if (windDiff >= 15) {
        changes['hasChanges'] = true;
        (changes['significantChanges'] as List).add({
          'type': 'wind',
          'message': 'Velocidade do vento mudou ${windDiff.toInt()} km/h',
          'severity': currentForecast.windSpeed > 40 ? 'high' : 'medium',
          'icon': '💨',
          'previous': previousForecast.windSpeed,
          'current': currentForecast.windSpeed,
        });
      }

      final previousAlerts = calculateWeatherAlerts([previousForecast]);
      final currentAlerts = calculateWeatherAlerts([currentForecast]);
      
      if (currentAlerts.length > previousAlerts.length) {
        changes['hasChanges'] = true;
        (changes['significantChanges'] as List).add({
          'type': 'new_alerts',
          'message': 'Novos alertas climáticos detectados',
          'severity': 'high',
          'icon': '⚠️',
          'alerts': currentAlerts.map((a) => a.type.label).toList(),
        });
      }

      return changes;
    } catch (e) {
      throw Exception('Erro ao detectar mudanças climáticas: $e');
    }
  }

  Future<Map<String, dynamic>> getEventWeatherSummary({
    required LatLng location,
    required DateTime eventDate,
    required String eventName,
  }) async {
    try {
      final forecast = await getEventDayForecast(location, eventDate);
      final alerts = calculateWeatherAlerts([forecast]);
      final daysUntil = eventDate.difference(DateTime.now()).inDays;

      String getConditionEmoji() {
        if (forecast.precipitation > 30) return '🌧️';
        if (forecast.precipitationProbability > 70) return '☁️';
        if (forecast.maxTemp > 30) return '☀️';
        if (forecast.minTemp < 15) return '🌡️';
        return '⛅';
      }

      String getRecommendation() {
        if (forecast.precipitation > 30) {
          return 'Leve guarda-chuva ou capa de chuva';
        } else if (forecast.maxTemp > 30) {
          return 'Mantenha-se hidratado e use protetor solar';
        } else if (forecast.minTemp < 15) {
          return 'Leve um agasalho';
        } else if (alerts.isNotEmpty) {
          return 'Atenção aos alertas climáticos';
        }
        return 'Condições favoráveis para o evento';
      }

      return {
        'eventName': eventName,
        'daysUntil': daysUntil,
        'emoji': getConditionEmoji(),
        'title': '$eventName - ${daysUntil == 0 ? 'Hoje' : daysUntil == 1 ? 'Amanhã' : 'Em $daysUntil dias'}',
        'body': '${forecast.minTemp.toInt()}-${forecast.maxTemp.toInt()}°C, ${forecast.precipitationProbability.toInt()}% chuva',
        'recommendation': getRecommendation(),
        'forecast': forecast,
        'alerts': alerts,
        'shouldNotify': alerts.isNotEmpty || 
            forecast.precipitationProbability > 50 ||
            daysUntil <= 3,
      };
    } catch (e) {
      throw Exception('Erro ao gerar resumo climático: $e');
    }
  }


  CurrentWeather _parseCurrentWeather(
    Map<String, dynamic> json,
    LatLng location,
  ) {
    final dataList = json['data'] as List;

    double getParam(String paramName) {
      try {
        final paramData = dataList.firstWhere(
          (d) => d['parameter'] == paramName,
          orElse: () => {
            'coordinates': [
              {
                'dates': [
                  {'value': 0},
                ],
              },
            ],
          },
        );
        final dates = paramData['coordinates'][0]['dates'] as List;
        return (dates[0]['value'] as num?)?.toDouble() ?? 0;
      } catch (e) {
        return 0;
      }
    }

    return CurrentWeather(
      temperature: getParam('t_2m:C'),
      temperatureFahrenheit: getParam('t_2m:F'),
      feelsLike: getParam('t_apparent:C'),
      minTemp: getParam('t_min_2m_24h:C'),
      maxTemp: getParam('t_max_2m_24h:C'),
      uvIndex: getParam('uv:idx'),
      humidity: getParam('relative_humidity_2m:p'),
      windSpeed: getParam('wind_speed_10m:kmh'),
      windDirection: getParam('wind_dir_10m:d'),
      windGust: getParam('wind_gusts_10m_1h:kmh'),
      precipitation: 0,
      precipitationProbability: 0,
      location: location,
      timestamp: DateTime.now(),
    );
  }

  List<HourlyWeather> _parseHourlyForecast(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final hourlyData = <HourlyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      final date = coordinates[i];
      final timestamp = DateTime.parse(date['date'] as String);

      double getParamValue(String paramName) {
        try {
          final paramData = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramData['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      hourlyData.add(
        HourlyWeather(
          time: timestamp,
          temperature: getParamValue('t_2m:C'),
          feelsLike: getParamValue('t_apparent:C'),
          uvIndex: getParamValue('uv:idx'),
          windSpeed: getParamValue('wind_speed_10m:kmh'),
          humidity: getParamValue('relative_humidity_2m:p'),
          precipitation: getParamValue('precip_1h:mm'),
          precipitationProbability: 0,
        ),
      );
    }

    return hourlyData;
  }

  List<HourlyWeather> _parseHourlyForecastExtended(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final hourlyData = <HourlyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      final date = coordinates[i];
      final timestamp = DateTime.parse(date['date'] as String);

      double getParamValue(String paramName) {
        try {
          final paramData = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramData['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      hourlyData.add(
        HourlyWeather(
          time: timestamp,
          temperature: getParamValue('t_2m:C'),
          feelsLike: getParamValue('t_apparent:C'),
          uvIndex: getParamValue('uv:idx'),
          windSpeed: getParamValue('wind_speed_10m:kmh'),
          humidity: getParamValue('relative_humidity_2m:p'),
          precipitation: getParamValue('precip_1h:mm'),
          precipitationProbability: getParamValue('prob_precip_1h:p'),
        ),
      );
    }

    return hourlyData;
  }

  List<DailyWeather> _parseDailyForecast(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final dailyData = <DailyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      double getParamValue(String paramName) {
        try {
          final paramData = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramData['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      final minTemp = getParamValue('t_min_2m_24h:C');
      final maxTemp = getParamValue('t_max_2m_24h:C');

      dailyData.add(
        DailyWeather(
          date: DateTime.parse(coordinates[i]['date'] as String),
          minTemp: minTemp,
          maxTemp: maxTemp,
          meanTemp: (minTemp + maxTemp) / 2,
          precipitation: getParamValue('precip_24h:mm'),
          windSpeed: getParamValue('wind_speed_10m:kmh'),
          windGust: getParamValue('wind_gusts_10m_24h:kmh'),
          humidity: getParamValue('relative_humidity_2m:p'),
          uvIndex: getParamValue('uv:idx'),
          cape: getParamValue('cape:Jkg'),
          precipitationProbability: getParamValue('prob_precip_1h:p'),
          hail: getParamValue('hail:cm'),
        ),
      );
    }

    return dailyData;
  }
}
