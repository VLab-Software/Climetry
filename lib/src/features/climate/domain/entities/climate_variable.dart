import 'package:flutter/material.dart';

class ClimateVariable {
  final String name;
  final String apiParam;
  final IconData icon;
  final bool isSelected;
  const ClimateVariable(this.name, this.apiParam, this.icon, this.isSelected);

  ClimateVariable copyWith({bool? isSelected}) =>
      ClimateVariable(name, apiParam, icon, isSelected ?? this.isSelected);
}
