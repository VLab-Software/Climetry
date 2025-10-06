// ignore_for_file: prefer_const_constructors_in_immutables

/// Modelo de insight de clima gerado pela OpenAI
class WeatherInsight {
  final String title;
  final String description;
  final double rating; // 0.0 a 10.0
  final List<String> recommendations;
  final List<String> whatToBring;
  final String bestTime;
  final List<WeatherAlert> alerts;
  final WeatherChartData? chartData;

  WeatherInsight({
    required this.title,
    required this.description,
    required this.rating,
    required this.recommendations,
    required this.whatToBring,
    required this.bestTime,
    required this.alerts,
    this.chartData,
  });

  factory WeatherInsight.fromJson(Map<String, dynamic> json) {
    return WeatherInsight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      whatToBring: List<String>.from(json['whatToBring'] ?? []),
      bestTime: json['bestTime'] ?? '',
      alerts: (json['alerts'] as List?)
              ?.map((e) => WeatherAlert.fromJson(e))
              .toList() ??
          [],
      chartData: json['chartData'] != null
          ? WeatherChartData.fromJson(json['chartData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'rating': rating,
      'recommendations': recommendations,
      'whatToBring': whatToBring,
      'bestTime': bestTime,
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'chartData': chartData?.toJson(),
    };
  }
}

/// Alerta de clima
class WeatherAlert {
  final String type; // warning, danger, info
  final String message;
  final String icon;

  WeatherAlert({
    required this.type,
    required this.message,
    required this.icon,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      icon: json['icon'] ?? '⚠️',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'icon': icon,
    };
  }
}

/// Dados para gráficos
class WeatherChartData {
  final List<ChartPoint> temperature;
  final List<ChartPoint> precipitation;
  final List<ChartPoint> windSpeed;
  final double uvIndex;

  WeatherChartData({
    required this.temperature,
    required this.precipitation,
    required this.windSpeed,
    required this.uvIndex,
  });

  factory WeatherChartData.fromJson(Map<String, dynamic> json) {
    return WeatherChartData(
      temperature: (json['temperature'] as List?)
              ?.map((e) => ChartPoint.fromJson(e))
              .toList() ??
          [],
      precipitation: (json['precipitation'] as List?)
              ?.map((e) => ChartPoint.fromJson(e))
              .toList() ??
          [],
      windSpeed: (json['windSpeed'] as List?)
              ?.map((e) => ChartPoint.fromJson(e))
              .toList() ??
          [],
      uvIndex: (json['uvIndex'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature.map((e) => e.toJson()).toList(),
      'precipitation': precipitation.map((e) => e.toJson()).toList(),
      'windSpeed': windSpeed.map((e) => e.toJson()).toList(),
      'uvIndex': uvIndex,
    };
  }
}

/// Ponto do gráfico
class ChartPoint {
  final DateTime time;
  final double value;
  final String? label;

  ChartPoint({
    required this.time,
    required this.value,
    this.label,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      time: DateTime.parse(json['time']),
      value: (json['value'] ?? 0).toDouble(),
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'value': value,
      'label': label,
    };
  }
}
