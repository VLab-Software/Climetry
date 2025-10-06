import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/variable_data.dart';
import '../../domain/entities/alert_info.dart';
import '../../../climate/domain/entities/weather_payload.dart';
import '../utils/meteomatics_parser.dart';

class ClimateDetailsViewModel extends ChangeNotifier {
  final String location;
  final String date;
  final LatLng coordinates;
  final WeatherPayload payload;

  ClimateDetailsViewModel({
    required this.location,
    required this.date,
    required this.coordinates,
    required this.payload,
  }) {
    _load();
  }

  List<VariableDate> variables = const [];
  AlertInfo alert = AlertInfo.analyzing;
  bool ready = false;

  Future<void> _load() async {
    variables = MeteomaticsParser.toVariables(payload);
    alert = MeteomaticsParser.buildAlert(variables);
    ready = true;
    notifyListeners();
  }
}
