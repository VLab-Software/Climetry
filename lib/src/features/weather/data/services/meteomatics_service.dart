import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/entities/hourly_weather.dart';
import '../../domain/entities/daily_weather.dart';
import '../../domain/entities/weather_alert.dart';

class MeteomaticsService {
  static const String _username = 'soares_rodrigo';
  static const String _password = 'Jv37937j7LF8noOrpK1c';
  static const String _baseUrl = 'api.meteomatics.com';

  String get _credentials => base64Encode(utf8.encode('$_username:$_password'));

  Map<String, String> get _headers => {
        'Authorization': 'Basic $_credentials',
        'Content-Type': 'application/json',
      };

  /// Chamada 1: Condições Atuais Completas (10 parâmetros)
  /// https://api.meteomatics.com/now/t_2m:C,t_2m:F,t_apparent:C,t_min_2m_24h:C,t_max_2m_24h:C,uv:idx,relative_humidity_2m:p,wind_speed_10m:kmh,wind_dir_10m:d,wind_gusts_10m_1h:kmh/-18.7333,-47.5000/json
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

  /// Chamada 2: Tendência Próximas 24 Horas (6 parâmetros)
  /// Formato correto: usar datas ISO8601, não now--PT24H
  Future<List<HourlyWeather>> getHourlyForecast(LatLng location) async {
    final now = DateTime.now().toUtc();
    final past24h = now.subtract(const Duration(hours: 24));
    
    final startStr = past24h.toIso8601String().split('.')[0] + 'Z';
    final endStr = now.toIso8601String().split('.')[0] + 'Z';
    
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

  /// Chamada 3: Previsão Próximos 7 Dias (10 parâmetros)
  /// Para cálculos de alertas climáticos
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

  /// Chamada 4: Previsão Próximo Mês (30 dias) - 10 parâmetros
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

  /// Chamada 5: Previsão Próximos 6 Meses (180 dias) - 10 parâmetros
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

  /// Chamada Extra: Contexto Climático e Anomalias (3 parâmetros)
  /// https://api.meteomatics.com/now/t_2m:C,t_2m_10y_mean:C,anomaly_t_mean_2m_24h:C/-18.7333,-47.5000/json
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
              orElse: () => {'coordinates': [{'dates': [{'value': 0}]}]},
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

  /// Chamada Extra: Horários do Sol e Precipitação (4 parâmetros)
  /// https://api.meteomatics.com/now/sunrise:sql,sunset:sql,precip_1h:mm,prob_precip_1h:p/-18.7333,-47.5000/json
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
              orElse: () => {'coordinates': [{'dates': [{'value': null}]}]},
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
          'precipitation_probability': (getParam('prob_precip_1h:p') as num?)?.toDouble() ?? 0,
        };
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar horários do sol: $e');
    }
  }

  /// Cálculo de Alertas Climáticos
  List<WeatherAlert> calculateWeatherAlerts(List<DailyWeather> forecast) {
    final alerts = <WeatherAlert>[];
    
    // Alerta 1: Onda de Calor (3+ dias com temp >= 35°C)
    int heatWaveDays = 0;
    for (var i = 0; i < forecast.length; i++) {
      final day = forecast[i];
      if (day.maxTemp >= 35) {
        heatWaveDays++;
        if (heatWaveDays >= 3) {
          alerts.add(WeatherAlert(
            type: WeatherAlertType.heatWave,
            date: day.date,
            value: day.maxTemp,
            unit: '°C',
            daysInSequence: heatWaveDays,
          ));
          break;
        }
      } else {
        heatWaveDays = 0;
      }
    }

    for (var day in forecast) {
      // Alerta 2: Desconforto Térmico Elevado
      if (day.maxTemp >= 30 && day.humidity >= 60) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.thermalDiscomfort,
          date: day.date,
          value: day.maxTemp,
          unit: '°C',
        ));
      }

      // Alerta 3: Frio Intenso
      if (day.minTemp <= 5) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.intenseCold,
          date: day.date,
          value: day.minTemp,
          unit: '°C',
        ));
      }

      // Alerta 4: Risco de Geada
      if (day.minTemp <= 3) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.frostRisk,
          date: day.date,
          value: day.minTemp,
          unit: '°C',
        ));
      }

      // Alerta 5: Chuva Intensa
      if (day.precipitation > 30) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.heavyRain,
          date: day.date,
          value: day.precipitation,
          unit: 'mm',
        ));
      }

      // Alerta 6: Risco de Enchente
      if (day.precipitation > 50) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.floodRisk,
          date: day.date,
          value: day.precipitation,
          unit: 'mm',
        ));
      }

      // Alerta 7: Potencial para Tempestades Severas
      if (day.cape != null && day.cape! > 2000) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.severeStorm,
          date: day.date,
          value: day.cape,
          unit: 'J/kg',
        ));
      }

      // Alerta 8: Risco de Granizo
      if (day.hail != null && day.hail! > 0) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.hailRisk,
          date: day.date,
          value: day.hail,
          unit: 'cm',
        ));
      }

      // Alerta 9: Ventania Forte
      if (day.windGust != null && day.windGust! >= 60) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.strongWind,
          date: day.date,
          value: day.windGust,
          unit: 'km/h',
        ));
      }
    }

    return alerts;
  }

  // Parsing methods
  
  CurrentWeather _parseCurrentWeather(Map<String, dynamic> json, LatLng location) {
    final dataList = json['data'] as List;
    
    double getParam(String paramName) {
      try {
        final paramData = dataList.firstWhere(
          (d) => d['parameter'] == paramName,
          orElse: () => {'coordinates': [{'dates': [{'value': 0}]}]},
        );
        // A API retorna: coordinates[0].dates[0].value
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

    // Pega primeiro parâmetro para obter lista de timestamps
    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      final date = coordinates[i];
      final timestamp = DateTime.parse(date['date'] as String);

      double getParamValue(String paramName) {
        try {
          final paramData = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {'coordinates': [{'dates': []}]},
          );
          final value = paramData['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      hourlyData.add(HourlyWeather(
        time: timestamp,
        temperature: getParamValue('t_2m:C'),
        feelsLike: getParamValue('t_apparent:C'),
        uvIndex: getParamValue('uv:idx'),
        windSpeed: getParamValue('wind_speed_10m:kmh'),
        humidity: getParamValue('relative_humidity_2m:p'),
        precipitation: getParamValue('precip_1h:mm'),
        precipitationProbability: 0,
      ));
    }

    return hourlyData;
  }

  List<DailyWeather> _parseDailyForecast(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final dailyData = <DailyWeather>[];

    // Pega primeiro parâmetro para obter lista de timestamps
    final firstParam = dataList.first;
    final coordinates = firstParam['coordinates'][0]['dates'] as List;

    for (var i = 0; i < coordinates.length; i++) {
      double getParamValue(String paramName) {
        try {
          final paramData = dataList.firstWhere(
            (d) => d['parameter'] == paramName,
            orElse: () => {'coordinates': [{'dates': []}]},
          );
          final value = paramData['coordinates'][0]['dates'][i]['value'];
          return (value as num?)?.toDouble() ?? 0;
        } catch (e) {
          return 0;
        }
      }

      final minTemp = getParamValue('t_min_2m_24h:C');
      final maxTemp = getParamValue('t_max_2m_24h:C');

      dailyData.add(DailyWeather(
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
      ));
    }

    return dailyData;
  }
}
