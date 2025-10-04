import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'climate_details_screen.dart';

// Data model for a climate variable
class ClimateVariable {
  final String name;
  final String apiParam;
  final IconData icon;
  bool isSelected;

  ClimateVariable(this.name, this.apiParam, this.icon, this.isSelected);
}

class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  LocationSuggestion(this.displayName, this.lat, this.lon);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earth Data Analysis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        primaryColor: const Color(0xFF00D9FF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D9FF),
          surface: const Color(0xFF1A1F2E),
          onSurface: Colors.white,
        ),
      ),
      home: const ClimateScreen(),
    );
  }
}

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  // --- STATE VARIABLES ---
  final locationController = TextEditingController();
  final MapController mapController = MapController();
  final FocusNode locationFocusNode = FocusNode();
  DateTimeRange? _selectedDateRange;
  DateTime? _selectedSingleDate;
  bool _isSingleDate = true; // true = single date, false = date range
  LatLng currentLocation = LatLng(-18.7394, -46.8767);
  List<LocationSuggestion> locationSuggestions = [];
  bool showSuggestions = false;
  Timer? _debounce;

  // Meteomatics API credentials (substitua com suas credenciais)
  final String meteomaticsUsername = 'soares_rodrigo';
  final String meteomaticsPassword = 'Jv37937j7LF8noOrpK1c';

  final List<ClimateVariable> apiVariables = [
    ClimateVariable('Temperature', 't_2m:C', Icons.thermostat_outlined, false),
    ClimateVariable('Precipitation', 'precip_1h:mm', Icons.water_drop_outlined, false),
    ClimateVariable('Wind Speed', 'wind_speed_10m:ms', Icons.waves, false),
    ClimateVariable('Humidity', 'relative_humidity_2m:p', Icons.water_outlined, false),
    ClimateVariable('Pressure', 'msl_pressure:hPa', Icons.speed, false),
    ClimateVariable('Cloud Cover', 'total_cloud_cover:p', Icons.cloud_outlined, false),
    ClimateVariable('UV Index', 'uv:idx', Icons.wb_sunny_outlined, false),
    ClimateVariable('Visibility', 'visibility:m', Icons.visibility, false),
    ClimateVariable('Dew Point', 'dew_point_2m:C', Icons.opacity, false),
    ClimateVariable('Solar Radiation', 'global_rad:W', Icons.wb_sunny, false),
  ];

  bool isLoading = false;
  final int maxVariables = 10;

  // --- GETTERS ---
  int get selectedCount => apiVariables.where((v) => v.isSelected).length;
  List<ClimateVariable> get selectedVariables =>
      apiVariables.where((v) => v.isSelected).toList();

  String get _formattedApiDateRange {
    if (_isSingleDate && _selectedSingleDate != null) {
      final date = _selectedSingleDate!;
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00Z';
    } else if (!_isSingleDate && _selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}T00:00:00Z--${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}T23:59:59Z:PT1H';
    }
    return '';
  }

  String get _userFriendlyDateRange {
    if (_isSingleDate && _selectedSingleDate != null) {
      final date = _selectedSingleDate!;
      return '${date.month}/${date.day}/${date.year}';
    } else if (!_isSingleDate && _selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      return '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
    }
    return 'Select Date';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    locationController.dispose();
    locationFocusNode.dispose();
    super.dispose();
  }

  // --- LOCATION AUTOCOMPLETE WITH DEBOUNCING ---
  Future<void> _searchLocationSuggestions(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) return;

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
      try {
        final response = await http.get(url, headers: {'User-Agent': 'climetry'});
        if (response.statusCode == 200) {
          final results = json.decode(response.body) as List;
          if (mounted) {
            setState(() {
              locationSuggestions = results
                  .map((r) => LocationSuggestion(
                r['display_name'],
                double.parse(r['lat']),
                double.parse(r['lon']),
              ))
                  .toList();
              showSuggestions = locationSuggestions.isNotEmpty;
            });
          }
        }
      } catch (e) {
        print('Error fetching suggestions: $e');
      }
    });
  }

  void _selectLocation(LocationSuggestion suggestion) {
    setState(() {
      currentLocation = LatLng(suggestion.lat, suggestion.lon);
      locationController.text = suggestion.displayName;
      showSuggestions = false;
      locationSuggestions = [];
    });
    mapController.move(currentLocation, 13.0);
    locationFocusNode.unfocus();
  }

  // --- METEOMATICS API INTEGRATION ---
  Future<void> _generateAnalysis() async {
    if (selectedVariables.isEmpty) {
      _showSnackBar('Please select at least one variable.');
      return;
    }
    if (_isSingleDate && _selectedSingleDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }
    if (!_isSingleDate && _selectedDateRange == null) {
      _showSnackBar('Please select a date range.');
      return;
    }
    if (locationController.text.isEmpty) {
      _showSnackBar('Please select a location.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final variables = selectedVariables.map((v) => v.apiParam).join(',');
      final timeRange = _formattedApiDateRange;
      final location = '${currentLocation.latitude},${currentLocation.longitude}';

      // Construir URL da Meteomatics API
      final apiUrl = 'https://api.meteomatics.com/$timeRange/$variables/$location/json';

      // Criar credenciais base64
      final credentials = base64Encode(utf8.encode('$meteomaticsUsername:$meteomaticsPassword'));

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Accept': 'application/json',
        },
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Navegar para a tela de detalhes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClimateDetailsScreen(
              location: locationController.text,
              date: _userFriendlyDateRange,
              coordinates: currentLocation,
              weatherData: data,
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        _showSnackBar('Authentication failed. Check your Meteomatics credentials.');
      } else {
        _showSnackBar('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error: $e');
    }
  }

  void _showResultsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Analysis Complete',
              style: TextStyle(color: Color(0xFF00D9FF)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${locationController.text}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Period: $_userFriendlyDateRange',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Retrieved:',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedVariables.length} variables\n${data['data']?.length ?? 0} data points',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'API Response received successfully!\n\nNote: Replace credentials in code with your Meteomatics API key.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- UI METHODS ---
  void showSelectVariablesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select API Variables',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Meteomatics Weather Data',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selectedCount >= maxVariables
                                  ? Colors.orange.withOpacity(0.2)
                                  : const Color(0xFF00D9FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedCount >= maxVariables
                                    ? Colors.orange
                                    : const Color(0xFF00D9FF),
                              ),
                            ),
                            child: Text(
                              '$selectedCount/$maxVariables selected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selectedCount >= maxVariables
                                    ? Colors.orange
                                    : const Color(0xFF00D9FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: apiVariables.length,
                    itemBuilder: (context, index) {
                      final variable = apiVariables[index];
                      final canSelect =
                          selectedCount < maxVariables || variable.isSelected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: canSelect
                              ? () {
                            setModalState(() =>
                            variable.isSelected = !variable.isSelected);
                            setState(() {});
                          }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: variable.isSelected
                                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: variable.isSelected
                                    ? const Color(0xFF00D9FF)
                                    : Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: variable.isSelected
                                        ? const Color(0xFF00D9FF).withOpacity(0.3)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    variable.icon,
                                    color: variable.isSelected
                                        ? const Color(0xFF00D9FF)
                                        : Colors.white
                                        .withOpacity(canSelect ? 0.7 : 0.3),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    variable.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: variable.isSelected
                                          ? const Color(0xFF00D9FF)
                                          : Colors.white
                                          .withOpacity(canSelect ? 0.9 : 0.3),
                                      fontWeight: variable.isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (variable.isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00D9FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Color(0xFF0A0E1A),
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedCount > 0
                          ? () => Navigator.pop(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF0A0E1A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: Text(
                        selectedCount > 0
                            ? 'Confirm Selection'
                            : 'Select at least one variable',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9FF),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _selectedSingleDate = null;
      });
    }
  }

  Future<void> _selectSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSingleDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9FF),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedSingleDate) {
      setState(() {
        _selectedSingleDate = picked;
        _selectedDateRange = null;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            TextField(
              controller: locationController,
              focusNode: locationFocusNode,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Type at least 3 characters...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: locationController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    locationController.clear();
                    setState(() {
                      showSuggestions = false;
                      locationSuggestions = [];
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _searchLocationSuggestions(value);
                } else {
                  setState(() {
                    locationSuggestions = [];
                    showSuggestions = false;
                  });
                }
              },
            ),
            if (showSuggestions && locationSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: locationSuggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = locationSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Color(0xFF00D9FF),
                      ),
                      title: Text(
                        suggestion.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectLocation(suggestion),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeframe',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                value: true,
                groupValue: _isSingleDate,
                onChanged: (value) {
                  setState(() {
                    _isSingleDate = value!;
                    if (_isSingleDate) {
                      _selectedDateRange = null;
                    } else {
                      _selectedSingleDate = null;
                    }
                  });
                },
                title: const Text(
                  'Single Date',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: const Color(0xFF00D9FF),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                value: false,
                groupValue: _isSingleDate,
                onChanged: (value) {
                  setState(() {
                    _isSingleDate = value!;
                    if (_isSingleDate) {
                      _selectedDateRange = null;
                    } else {
                      _selectedSingleDate = null;
                    }
                  });
                },
                title: const Text(
                  'Date Range',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: const Color(0xFF00D9FF),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSingleDate ? _selectSingleDate : _selectDateRange,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_userFriendlyDateRange),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earth Data Analysis - Meteomatics'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: isWebLayout ? _buildWebLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: currentLocation,
                        initialZoom: 10.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'climetry',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLocation,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Selected Variables',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00D9FF),
                              ),
                            ),
                            child: Text(
                              '$selectedCount/$maxVariables',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00D9FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (selectedVariables.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No variables selected',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          children: selectedVariables
                              .map(
                                (v) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D9FF)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00D9FF),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    v.icon,
                                    size: 18,
                                    color: const Color(0xFF00D9FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    v.name,
                                    style: const TextStyle(
                                      color: Color(0xFF00D9FF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: showSelectVariablesBottomSheet,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Variables'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF00D9FF).withOpacity(0.1),
                            foregroundColor: const Color(0xFF00D9FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF00D9FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Configuration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLocationField(),
                  const SizedBox(height: 24),
                  _buildTimeframeSelector(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add your Meteomatics credentials in the code',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _generateAnalysis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF0A0E1A),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0A0E1A)),
                        ),
                      )
                          : const Text(
                        'Generate Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _buildLocationField(),
          const SizedBox(height: 16),
          _buildTimeframeSelector(),
          const SizedBox(height: 24),
          Text(
            'Selected Variables',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (selectedVariables.isEmpty)
            Center(
              child: Text(
                'No variables selected. Tap below to add.',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: selectedVariables
                  .map(
                    (v) => Chip(
                  label: Text(v.name),
                  backgroundColor:
                  const Color(0xFF00D9FF).withOpacity(0.2),
                  side: BorderSide.none,
                ),
              )
                  .toList(),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: showSelectVariablesBottomSheet,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Variables'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1F2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'climetry',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _generateAnalysis,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: const Color(0xFF0A0E1A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            ),
            child: isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF0A0E1A)),
              ),
            )
                : const Text(
              'Generate Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}