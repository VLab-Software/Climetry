import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/climate_variable.dart';
import '../../domain/entities/location_suggestion.dart';
import '../../domain/entities/weather_payload.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/weather_repository.dart';

class ClimateViewModel extends ChangeNotifier {
  bool locationMenuOpen = false;
  void setLocationMenuOpen(bool v) {
    if (locationMenuOpen == v) return;
    locationMenuOpen = v;
    notifyListeners();
  }

  ClimateViewModel({
    required this.weatherRepository,
    required this.locationRepository,
  }) {
    _apiVariables = [
      ClimateVariable('Temperature', 't_2m:C', Icons.thermostat_outlined, true),
      ClimateVariable(
        'Precipitation',
        'precip_1h:mm',
        Icons.water_drop_outlined,
        false,
      ),
      ClimateVariable('Wind Speed', 'wind_speed_10m:ms', Icons.waves, false),
      ClimateVariable(
        'Humidity',
        'relative_humidity_2m:p',
        Icons.water_outlined,
        false,
      ),
      ClimateVariable('Pressure', 'msl_pressure:hPa', Icons.speed, false),
      ClimateVariable(
        'Cloud Cover',
        'total_cloud_cover:p',
        Icons.cloud_outlined,
        false,
      ),
      ClimateVariable('UV Index', 'uv:idx', Icons.wb_sunny_outlined, false),
      ClimateVariable('Visibility', 'visibility:m', Icons.visibility, false),
      ClimateVariable('Dew Point', 'dew_point_2m:C', Icons.opacity, false),
      ClimateVariable('Solar Radiation', 'global_rad:W', Icons.wb_sunny, false),
    ];
  }

  final WeatherRepository weatherRepository;
  final LocationRepository locationRepository;

  final locationController = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();
  DateTimeRange? selectedDateRange;
  DateTime? selectedSingleDate;
  bool isSingleDate = true;
  int maxVariables = 10;
  bool isLoading = false;

  late List<ClimateVariable> _apiVariables;
  List<ClimateVariable> get apiVariables => _apiVariables;
  List<ClimateVariable> get selectedVariables =>
      _apiVariables.where((v) => v.isSelected).toList();
  int get selectedCount => selectedVariables.length;

  LatLng _currentLocation = const LatLng(-18.7394, -46.8767);
  LatLng get currentLocation => _currentLocation;
  set currentLocation(LatLng value) {
    _currentLocation = value;
    notifyListeners();
  }

  List<LocationSuggestion> suggestions = [];
  bool showSuggestions = false;
  Timer? _debounce;

  String get formattedApiDateRange {
    if (isSingleDate && selectedSingleDate != null) {
      final d = selectedSingleDate!;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00Z';
    } else if (!isSingleDate && selectedDateRange != null) {
      final s = selectedDateRange!.start;
      final e = selectedDateRange!.end;
      return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}T00:00:00Z--'
          '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}T23:59:59Z:PT1H';
    }
    return '';
  }

  String get userFriendlyDateRange {
    if (isSingleDate && selectedSingleDate != null) {
      final d = selectedSingleDate!;
      return '${d.month}/${d.day}/${d.year}';
    } else if (!isSingleDate && selectedDateRange != null) {
      final s = selectedDateRange!.start;
      final e = selectedDateRange!.end;
      return '${s.month}/${s.day}/${s.year} - ${e.month}/${e.day}/${e.year}';
    }
    return 'Select Date';
  }

  void toggleVariable(ClimateVariable v) {
    final idx = _apiVariables.indexWhere((e) => e.apiParam == v.apiParam);
    if (idx == -1) return;
    final isSelected = _apiVariables[idx].isSelected;
    if (!isSelected && selectedCount >= maxVariables) return;
    _apiVariables[idx] = _apiVariables[idx].copyWith(isSelected: !isSelected);
    notifyListeners();
  }

  void setSingleDateMode(bool value) {
    isSingleDate = value;
    if (isSingleDate) {
      selectedDateRange = null;
    } else {
      selectedSingleDate = null;
    }
    notifyListeners();
  }

  Future<void> searchLocations(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final q = query.trim();
      if (q.length < 3) {
        showSuggestions = false;
        suggestions = [];
        notifyListeners();
        return;
      }
      try {
        final res = await locationRepository.search(q);
        suggestions = res;
        showSuggestions = res.isNotEmpty;
      } catch (_) {
        showSuggestions = false;
        suggestions = [];
      }
      notifyListeners();
    });
  }

  void selectLocation(LocationSuggestion s) {
    _currentLocation = LatLng(s.lat, s.lon);
    locationController.text = s.displayName;
    showSuggestions = false;
    suggestions = [];
    notifyListeners();
  }

  Future<WeatherPayload> generateAnalysis() async {
    if (selectedCount == 0) {
      throw StateError('Select at least one variable');
    }
    if ((isSingleDate && selectedSingleDate == null) ||
        (!isSingleDate && selectedDateRange == null)) {
      throw StateError('Select a date or date range');
    }
    if (locationController.text.trim().isEmpty) {
      throw StateError('Select a location');
    }

    final variables = selectedVariables.map((v) => v.apiParam).join(',');
    final timeRange = formattedApiDateRange;
    final location = '${currentLocation.latitude},${currentLocation.longitude}';

    isLoading = true;
    notifyListeners();
    try {
      final payload = await weatherRepository.fetch(
        timeRange: timeRange,
        variables: variables,
        location: location,
      );
      return payload;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
