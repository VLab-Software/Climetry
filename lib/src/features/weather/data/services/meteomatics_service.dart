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
      't_2m:F',
      't_apparent:F',
      't_min_2m_24h:F',
      't_max_2m_24h:F',
      'uv:idx',
      'relative_humidity_2m:p',
      'wind_speed_10m:mph',
      'wind_dir_10m:d',
      'wind_gusts_10m_1h:mph',
      'precip_1h:inch',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch current weather: $e');
    }
  }

  Future<List<HourlyWeather>> getHourlyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final future24h = now.add(const Duration(hours: 24));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = future24h.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_2m:F',
      't_apparent:F',
      'uv:idx',
      'wind_speed_10m:mph',
      'relative_humidity_2m:p',
      'precip_1h:inch',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch hourly forecast: $e');
    }
  }

  Future<List<DailyWeather>> getWeeklyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 7));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:F',
      't_min_2m_24h:F',
      'precip_24h:inch',
      'wind_gusts_10m_24h:mph',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:mph',
      'hail:inch',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weekly forecast: $e');
    }
  }

  Future<List<DailyWeather>> getMonthlyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 30));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:F',
      't_min_2m_24h:F',
      'precip_24h:inch',
      'wind_gusts_10m_24h:mph',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:mph',
      'hail:inch',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch monthly forecast: $e');
    }
  }

  Future<List<DailyWeather>> getSixMonthsForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final endDate = now.add(const Duration(days: 180));

    final startStr = now.toIso8601String().split('.')[0] + 'Z';
    final endStr = endDate.toIso8601String().split('.')[0] + 'Z';

    final params = [
      't_max_2m_24h:F',
      't_min_2m_24h:F',
      'precip_24h:inch',
      'wind_gusts_10m_24h:mph',
      'relative_humidity_2m:p',
      'uv:idx',
      'cape:Jkg',
      'prob_precip_1h:p',
      'wind_speed_10m:mph',
      'hail:inch',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch 6-month forecast: $e');
    }
  }

  Future<Map<String, double>> getClimateAnomalies(LatLng location) async {
    final params = [
      't_2m:F',
      't_2m_10y_mean:F',
      'anomaly_t_mean_2m_24h:F',
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
            final paramDate = dataList.firstWhere(
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
            final dates = paramDate['coordinates'][0]['dates'] as List;
            return (dates[0]['value'] as num?)?.toDouble() ?? 0;
          } catch (e) {
            return 0;
          }
        }

        return {
          'current': getParam('t_2m:F'),
          'historical_mean': getParam('t_2m_10y_mean:F'),
          'anomaly': getParam('anomaly_t_mean_2m_24h:F'),
        };
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch climate anomalies: $e');
    }
  }

  Future<Map<String, dynamic>> getSunAndPrecipitation(LatLng location) async {
    final params = [
      'sunrise:sql',
      'sunset:sql',
      'precip_1h:inch',
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
            final paramDate = dataList.firstWhere(
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
            final dates = paramDate['coordinates'][0]['dates'] as List;
            return dates[0]['value'];
          } catch (e) {
            return null;
          }
        }

        return {
          'sunrise': getParam('sunrise:sql'),
          'sunset': getParam('sunset:sql'),
          'precipitation': (getParam('precip_1h:inch') as num?)?.toDouble() ?? 0,
          'precipitation_probability':
              (getParam('prob_precip_1h:p') as num?)?.toDouble() ?? 0,
        };
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch horários do sol: $e');
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
              unit: '°F',
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
            unit: '°F',
          ),
        );
      }

      if (day.minTemp <= 5) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.intenseCold,
            date: day.date,
            value: day.minTemp,
            unit: '°F',
          ),
        );
      }

      if (day.minTemp <= 3) {
        alerts.add(
          WeatherAlert(
            type: WeatherAlertType.frostRisk,
            date: day.date,
            value: day.minTemp,
            unit: '°F',
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
      't_max_2m_24h:F',
      't_min_2m_24h:F',
      't_mean_2m_24h:F',
      'precip_24h:inch',
      'prob_precip_1h:p',
      'wind_speed_mean_10m_24h:mph',
      'wind_gusts_10m_24h:mph',
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
            final paramDate = dataList.firstWhere(
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
            final dates = paramDate['coordinates'][0]['dates'] as List;
            return (dates[0]['value'] as num?)?.toDouble() ?? 0;
          } catch (e) {
            return 0;
          }
        }

        final minTemp = getParam('t_min_2m_24h:F');
        final maxTemp = getParam('t_max_2m_24h:F');
        final meanTemp = getParam('t_mean_2m_24h:F');

        return DailyWeather(
          date: eventDate,
          minTemp: minTemp,
          maxTemp: maxTemp,
          meanTemp: meanTemp > 0 ? meanTemp : (minTemp + maxTemp) / 2,
          precipitation: getParam('precip_24h:inch'),
          precipitationProbability: getParam('prob_precip_1h:p'),
          windSpeed: getParam('wind_speed_mean_10m_24h:mph'),
          windGust: getParam('wind_gusts_10m_24h:mph'),
          humidity: getParam('relative_humidity_2m:p'),
          uvIndex: getParam('uv:idx'),
          cape: getParam('cape:Jkg'),
          hail: 0,
        );
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch previsão para data específica: $e');
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
      't_2m:F',
      't_apparent:F',
      'precip_1h:inch',
      'prob_precip_1h:p',
      'wind_speed_10m:mph',
      'wind_gusts_10m_1h:mph',
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
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch hourly forecast do ewind: $e');
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
              ? 'Temperature máxima aumentou ${tempDiff.toInt()}°F'
              : 'Temperature máxima diminuiu ${tempDiff.toInt()}°F',
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
              ? 'Chance de rain aumentou ${rainDiff.toInt()}%'
              : 'Chance de rain diminuiu ${rainDiff.toInt()}%',
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
          'message': 'Volume de rain previsto mudou ${precipDiff.toInt()}mm',
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
          'message': 'Velocidade do wind mudou ${windDiff.toInt()} mph',
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
      throw Exception('Error ao detectar mudanças climáticas: $e');
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
          return 'Leve guarda-rain ou capa de rain';
        } else if (forecast.maxTemp > 30) {
          return 'Mantenha-se hidratado e use protetor solar';
        } else if (forecast.minTemp < 15) {
          return 'Leve um agasalho';
        } else if (alerts.isNotEmpty) {
          return 'Atenção aos alertas climáticos';
        }
        return 'Condições favoráveis para o ewind';
      }

      return {
        'eventName': eventName,
        'daysUntil': daysUntil,
        'emoji': getConditionEmoji(),
        'title': '$eventName - ${daysUntil == 0 ? 'Today' : daysUntil == 1 ? 'Tomorrow' : 'In $daysUntil days'}',
        'body': '${forecast.minTemp.toInt()}-${forecast.maxTemp.toInt()}°F, ${forecast.precipitationProbability.toInt()}% rain',
        'recommendation': getRecommendation(),
        'forecast': forecast,
        'alerts': alerts,
        'shouldNotify': alerts.isNotEmpty || 
            forecast.precipitationProbability > 50 ||
            daysUntil <= 3,
      };
    } catch (e) {
      throw Exception('Error ao gerar resumo climático: $e');
    }
  }


  CurrentWeather _parseCurrentWeather(
    Map<String, dynamic> json,
    LatLng location,
  ) {
    final dataList = json['data'] as List;

    double getParam(String paramName) {
      try {
        final paramDate = dataList.firstWhere(
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
        final dates = paramDate['coordinates'][0]['dates'] as List;
        return (dates[0]['value'] as num?)?.toDouble() ?? 0;
      } catch (e) {
        return 0;
      }
    }

    return CurrentWeather(
      temperature: getParam('t_2m:F'),
      temperatureFahrenheit: getParam('t_2m:F'),
      feelsLike: getParam('t_apparent:F'),
      minTemp: getParam('t_min_2m_24h:F'),
      maxTemp: getParam('t_max_2m_24h:F'),
      uvIndex: getParam('uv:idx'),
      humidity: getParam('relative_humidity_2m:p'),
      windSpeed: getParam('wind_speed_10m:mph'),
      windDirection: getParam('wind_dir_10m:d'),
      windGust: getParam('wind_gusts_10m_1h:mph'),
      precipitation: 0,
      precipitationProbability: 0,
      location: location,
      timestamp: DateTime.now(),
    );
  }

  List<HourlyWeather> _parseHourlyForecast(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final hourlyDate = <HourlyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      final date = coordinates[i];
      final timestamp = DateTime.parse(date['date'] as String);

      double getParamValue(String paramName) {
        try {
          final paramDate = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramDate['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      hourlyDate.add(
        HourlyWeather(
          time: timestamp,
          temperature: getParamValue('t_2m:F'),
          feelsLike: getParamValue('t_apparent:F'),
          uvIndex: getParamValue('uv:idx'),
          windSpeed: getParamValue('wind_speed_10m:mph'),
          humidity: getParamValue('relative_humidity_2m:p'),
          precipitation: getParamValue('precip_1h:inch'),
          precipitationProbability: 0,
        ),
      );
    }

    return hourlyDate;
  }

  List<HourlyWeather> _parseHourlyForecastExtended(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final hourlyDate = <HourlyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      final date = coordinates[i];
      final timestamp = DateTime.parse(date['date'] as String);

      double getParamValue(String paramName) {
        try {
          final paramDate = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramDate['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      hourlyDate.add(
        HourlyWeather(
          time: timestamp,
          temperature: getParamValue('t_2m:F'),
          feelsLike: getParamValue('t_apparent:F'),
          uvIndex: getParamValue('uv:idx'),
          windSpeed: getParamValue('wind_speed_10m:mph'),
          humidity: getParamValue('relative_humidity_2m:p'),
          precipitation: getParamValue('precip_1h:inch'),
          precipitationProbability: getParamValue('prob_precip_1h:p'),
        ),
      );
    }

    return hourlyDate;
  }

  List<DailyWeather> _parseDailyForecast(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final dailyDate = <DailyWeather>[];

    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      double getParamValue(String paramName) {
        try {
          final paramDate = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {
              'coordinates': [
                {'dates': []},
              ],
            },
          );
          final value = paramDate['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      final minTemp = getParamValue('t_min_2m_24h:F');
      final maxTemp = getParamValue('t_max_2m_24h:F');

      dailyDate.add(
        DailyWeather(
          date: DateTime.parse(coordinates[i]['date'] as String),
          minTemp: minTemp,
          maxTemp: maxTemp,
          meanTemp: (minTemp + maxTemp) / 2,
          precipitation: getParamValue('precip_24h:inch'),
          windSpeed: getParamValue('wind_speed_10m:mph'),
          windGust: getParamValue('wind_gusts_10m_24h:mph'),
          humidity: getParamValue('relative_humidity_2m:p'),
          uvIndex: getParamValue('uv:idx'),
          cape: getParamValue('cape:Jkg'),
          precipitationProbability: getParamValue('prob_precip_1h:p'),
          hail: getParamValue('hail:inch'),
        ),
      );
    }

    return dailyDate;
  }

  /// Get climate normals (historical averages) for a specific date and location
  /// Meteomatics provides climate normals based on historical data
  Future<Map<String, double>> getClimateNormals(
    LatLng location,
    DateTime targetDate,
  ) async {
    // Use the same month and day but from climate normal period
    final monthDay = '${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    
    // Meteomatics climate normals endpoint
    final params = [
      't_2m:F', // Temperature normal
      'precip_1h:inch', // Precipitation normal
      'wind_speed_10m:mph', // Wind speed normal
      'relative_humidity_2m:p', // Humidity normal
    ].join(',');

    final url = Uri.https(
      _baseUrl,
      '/$monthDay/climate_normals/$params/${location.latitude},${location.longitude}/json',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = <String, double>{};
        
        final dataList = data['data'] as List;
        for (var param in dataList) {
          final parameter = param['parameter'] as String;
          final coordinates = param['coordinates'] as List;
          
          if (coordinates.isNotEmpty) {
            final value = coordinates[0]['dates']?[0]?['value'];
            
            if (parameter.contains('t_2m')) {
              result['temperature'] = (value as num?)?.toDouble() ?? 0;
            } else if (parameter.contains('precip')) {
              result['precipitation'] = (value as num?)?.toDouble() ?? 0;
            } else if (parameter.contains('wind_speed')) {
              result['windSpeed'] = (value as num?)?.toDouble() ?? 0;
            } else if (parameter.contains('humidity')) {
              result['humidity'] = (value as num?)?.toDouble() ?? 0;
            }
          }
        }
        
        return result;
      } else {
        // If climate normals are not available, return estimated averages
        return {
          'temperature': 70.0,
          'precipitation': 0.5,
          'windSpeed': 8.0,
          'humidity': 60.0,
        };
      }
    } catch (e) {
      // Return reasonable defaults if API fails
      return {
        'temperature': 70.0,
        'precipitation': 0.5,
        'windSpeed': 8.0,
        'humidity': 60.0,
      };
    }
  }
}
