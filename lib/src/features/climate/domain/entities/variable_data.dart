import 'package:flutter/material.dart';
import 'time_series_point.dart';

class VariableData {
  final String name;
  final String parameter;
  final String unit;
  final IconData icon;
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final double change;
  final List<TimeSeriesPoint> timeSeriesData;

  const VariableData({
    required this.name,
    required this.parameter,
    required this.unit,
    required this.icon,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.change,
    required this.timeSeriesData,
  });
}
