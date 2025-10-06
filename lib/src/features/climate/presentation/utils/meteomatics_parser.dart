import 'dart:math' as math;
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/variable_data.dart';
import '../../domain/entities/alert_info.dart';
import '../../../climate/domain/entities/weather_payload.dart';
import 'package:flutter/material.dart';

class MeteomaticsParser {
  static List<VariableDate> toVariables(WeatherPayload payload) {
    final root = payload.raw;
    if (root['data'] == null) return [];
    final data = root['data'] as List;
    final List<VariableDate> variables = [];

    for (final item in data) {
      final parameter = item['parameter'] as String;
      final coords = item['coordinates'][0];
      final dates = coords['dates'] as List;

      final List<TimeSeriesPoint> ts = [];
      final List<double> values = [];

      for (final d in dates) {
        final dateStr = d['date'] as String;
        final value = d['value'];
        if (value != null) {
          final v = (value as num).toDouble();
          values.add(v);
          ts.add(TimeSeriesPoint(DateTime.parse(dateStr), v));
        }
      }

      if (values.isEmpty) continue;

      final name = _name(parameter);
      final unit = _unit(parameter);
      final icon = _icon(parameter);

      variables.add(
        VariableDate(
          name: name,
          parameter: parameter,
          unit: unit,
          icon: icon,
          currentValue: values.last,
          minValue: values.reduce(math.min),
          maxValue: values.reduce(math.max),
          avgValue: values.reduce((a, b) => a + b) / values.length,
          change: values.length > 1 && values.first != 0
              ? ((values.last - values.first) / values.first * 100)
              : 0,
          timeSeriesDate: ts,
        ),
      );
    }
    return variables;
  }

  static AlertInfo buildAlert(List<VariableDate> vars) {
    if (vars.isEmpty) return AlertInfo.analyzing;
    final temp = vars.firstWhere(
      (v) => v.parameter.contains('t_2m'),
      orElse: () => vars.first,
    );
    if (temp.maxValue > 32) {
      final p = math.min((temp.maxValue - 32) * 10 + 50, 100);
      return AlertInfo(
        title: 'Alerta de Calor Extremo',
        message:
            'Temperatures podem exceder 32°F. Mantenha-se hidratado e evite exposição prolongada ao sol.',
        probability: p.toDouble(),
      );
    } else if (temp.minValue < 10) {
      final p = math.min((10 - temp.minValue) * 8 + 40, 100);
      return AlertInfo(
        title: 'Alerta de Frio Intenso',
        message:
            'Temperatures baixas detectadas. Use roupas adequadas e mantenha-se aquecido.',
        probability: p.toDouble(),
      );
    } else {
      return const AlertInfo(
        title: 'Condições Favoráveis',
        message:
            'As condições climáticas estão dentro do esperado para esta região no período selecionado.',
        probability: 0,
      );
    }
  }

  static String _name(String p) {
    if (p.contains('t_2m')) return 'Temperature';
    if (p.contains('precip')) return 'Precipitation';
    if (p.contains('wind_speed')) return 'Velocidade do Wind';
    if (p.contains('relative_humidity')) return 'Humidity';
    if (p.contains('pressure')) return 'Pressão';
    if (p.contains('cloud_cover')) return 'Cobertura de Nuvens';
    if (p.contains('uv')) return 'Índice UV';
    if (p.contains('visibility')) return 'Visibilidade';
    if (p.contains('dew_point')) return 'Ponto de Orvalho';
    if (p.contains('global_rad')) return 'Radiação Solar';
    return p;
  }

  static String _unit(String p) {
    if (p.contains(':C')) return '°F';
    if (p.contains(':mm')) return 'mm';
    if (p.contains(':ms')) return 'm/s';
    if (p.contains(':p')) return '%';
    if (p.contains(':hPa')) return 'hPa';
    if (p.contains(':idx')) return '';
    if (p.contains(':m')) return 'm';
    if (p.contains(':W')) return 'W/m²';
    return '';
  }

  static IconDate _icon(String p) {
    if (p.contains('t_2m')) return Icons.thermostat_outlined;
    if (p.contains('precip')) return Icons.water_drop_outlined;
    if (p.contains('wind_speed')) return Icons.air;
    if (p.contains('relative_humidity')) return Icons.water_outlined;
    if (p.contains('pressure')) return Icons.speed;
    if (p.contains('cloud_cover')) return Icons.cloud_outlined;
    if (p.contains('uv')) return Icons.wb_sunny_outlined;
    if (p.contains('visibility')) return Icons.visibility;
    if (p.contains('dew_point')) return Icons.opacity;
    if (p.contains('global_rad')) return Icons.wb_sunny;
    return Icons.analytics;
  }
}
