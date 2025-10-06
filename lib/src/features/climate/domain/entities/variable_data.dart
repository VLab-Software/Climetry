import 'package:flutter/material.dart';
import 'time_series_point.dart';

class VariableDate {
  final String name;
  final String parameter;
  final String unit;
  final IconDate icon;
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final double change;
  final List<TimeSeriesPoint> timeSeriesDate;

  const VariableDate({
    required this.name,
    required this.parameter,
    required this.unit,
    required this.icon,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.change,
    required this.timeSeriesDate,
  });
}
