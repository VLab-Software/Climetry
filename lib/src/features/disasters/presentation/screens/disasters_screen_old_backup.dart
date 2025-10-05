import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../data/repositories/alert_preferences_repository.dart';
import 'package:intl/intl.dart';
import '../widgets/location_picker_widget.dart';
import 'alert_details_screen.dart';

class DisastersScreen extends StatefulWidget {
  const DisastersScreen({super.key});

  @override
  State<DisastersScreen> createState() => _DisastersScreenState();
}

class _DisastersScreenState extends State<DisastersScreen> {
  final MeteomaticsService _weatherService = MeteomaticsService();
  final AlertPreferencesRepository _prefsRepo = AlertPreferencesRepository();
  
  List<WeatherAlert> _alerts = [];
  List<DailyWeather> _forecast = [];
  Set<WeatherAlertType> _enabledAlerts = {};
  bool _loading = true;
  LatLng _monitoringLocation = const LatLng(-23.5505, -46.6333);
  String _locationName = 'São Paulo, SP';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final enabledAlerts = await _prefsRepo.getEnabledAlerts();
      final locationData = await _prefsRepo.getMonitoringLocation();
      
      if (!mounted) return;
      setState(() {
        _enabledAlerts = enabledAlerts;
        if (locationData != null) {
          _monitoringLocation = LatLng(
            locationData['latitude'],
            locationData['longitude'],
          );
          _locationName = locationData['name'];
        }
      });
      
      await _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _loadAlerts() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final forecast = await _weatherService.getWeeklyForecast(_monitoringLocation);
      final allAlerts = _weatherService.calculateWeatherAlerts(forecast);
      
      // Filtrar alertas pelos tipos habilitados
      final alerts = allAlerts.where((alert) => _enabledAlerts.contains(alert.type)).toList();
      
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _forecast = forecast;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar: $e'),
            action: SnackBarAction(label: 'Tentar Novamente', onPressed: _loadAlerts),
          ),
        );
      }
    }
  }

  Future<void> _toggleAlert(WeatherAlertType type, bool enabled) async {
    final newEnabled = Set<WeatherAlertType>.from(_enabledAlerts);
    if (enabled) {
      newEnabled.add(type);
    } else {
      newEnabled.remove(type);
    }
    
    try {
      await _prefsRepo.saveEnabledAlerts(newEnabled);
      if (!mounted) return;
      setState(() => _enabledAlerts = newEnabled);
      await _loadAlerts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          initialLocation: _monitoringLocation,
          initialLocationName: _locationName,
        ),
      ),
    );
    
    if (result != null) {
      try {
        await _prefsRepo.saveMonitoringLocation(
          result['location'].latitude,
          result['location'].longitude,
          result['name'],
        );
        
        if (!mounted) return;
        setState(() {
          _monitoringLocation = result['location'];
          _locationName = result['name'];
        });
        
        await _loadAlerts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  Color _getAlertColor(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.heatWave:
      case WeatherAlertType.thermalDiscomfort:
        return Colors.orange;
      case WeatherAlertType.intenseCold:
      case WeatherAlertType.frostRisk:
        return Colors.blue;
      case WeatherAlertType.heavyRain:
      case WeatherAlertType.floodRisk:
        return Colors.red;
      case WeatherAlertType.severeStorm:
      case WeatherAlertType.hailRisk:
        return Colors.purple;
      case WeatherAlertType.strongWind:
        return Colors.teal;
    }
  }

  String _getAlertIcon(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.heatWave:
      case WeatherAlertType.thermalDiscomfort:
        return '🌡️';
      case WeatherAlertType.intenseCold:
      case WeatherAlertType.frostRisk:
        return '❄️';
      case WeatherAlertType.heavyRain:
      case WeatherAlertType.floodRisk:
        return '🌧️';
      case WeatherAlertType.severeStorm:
        return '⛈️';
      case WeatherAlertType.hailRisk:
        return '🧊';
      case WeatherAlertType.strongWind:
        return '💨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        title: const Text('Alertas Climáticos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsBottomSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding para floating tab bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationHeader(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildAlertsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4A9EFF).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.location_on, color: Color(0xFF4A9EFF), size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monitorando', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _locationName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_location, color: Colors.white60),
            onPressed: _selectLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final critical = _alerts.where((a) => 
      a.type == WeatherAlertType.floodRisk || 
      a.type == WeatherAlertType.heatWave ||
      a.type == WeatherAlertType.severeStorm
    ).length;
    
    final warning = _alerts.where((a) => 
      a.type == WeatherAlertType.heavyRain ||
      a.type == WeatherAlertType.strongWind ||
      a.type == WeatherAlertType.hailRisk
    ).length;
    
    final info = _alerts.length - critical - warning;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Críticos', critical, Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Avisos', warning, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Info', info, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Sem Alertas', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Não há alertas para $_locationName',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas Ativos (${_alerts.length})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._alerts.map(_buildAlertCard),
      ],
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    final color = _getAlertColor(alert.type);
    final icon = _getAlertIcon(alert.type);
    final dateFormat = DateFormat('d MMM', 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlertDetailsScreen(
                alert: alert,
                forecast: _forecast,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.type.label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(alert.type.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: color),
                                const SizedBox(width: 6),
                                Text(dateFormat.format(alert.date), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (alert.value != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.speed, size: 14, color: color),
                                  const SizedBox(width: 6),
                                  Text('${alert.value!.toStringAsFixed(1)} ${alert.unit ?? ''}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A3A4D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Selecione os Alertas', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: WeatherAlertType.values.map((type) {
                  final isEnabled = _enabledAlerts.contains(type);
                  final color = _getAlertColor(type);
                  final icon = _getAlertIcon(type);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isEnabled ? color.withValues(alpha: 0.5) : Colors.white10, width: 2),
                    ),
                    child: CheckboxListTile(
                      value: isEnabled,
                      onChanged: (value) => _toggleAlert(type, value ?? false),
                      title: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(type.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Text(type.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ),
                      activeColor: color,
                      checkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
