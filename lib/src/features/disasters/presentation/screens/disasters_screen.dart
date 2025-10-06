import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../data/repositories/alert_preferences_repository.dart';
import 'package:intl/intl.dart';
import '../widgets/location_picker_widget.dart';
import '../../../../core/theme/theme_provider.dart';
import 'alert_details_screen.dart';

class DisastersScreen extends StatefulWidget {
  const DisastersScreen({super.key});

  @override
  State<DisastersScreen> createState() => _DisastersScreenState();
}

class _DisastersScreenState extends State<DisastersScreen>
    with AutomaticKeepAliveClientMixin {
  final MeteomaticsService _weatherService = MeteomaticsService();
  final AlertPreferencesRepository _prefsRepo = AlertPreferencesRepository();

  List<WeatherAlert> _alerts = [];
  List<DailyWeather> _forecast = [];
  Set<WeatherAlertType> _enabledAlerts = {};
  bool _loading = true;
  LatLng _monitoringLocation = const LatLng(-23.5505, -46.6333);
  String _locationName = 'São Paulo, SP';

  @override
  bool get wantKeepAlive => true;

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
      final locationDate = await _prefsRepo.getMonitoringLocation();

      if (!mounted) return;
      setState(() {
        _enabledAlerts = enabledAlerts;
        if (locationDate != null) {
          _monitoringLocation = LatLng(
            locationDate['latitude'],
            locationDate['longitude'],
          );
          _locationName = locationDate['name'];
        }
      });

      await _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAlerts() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final forecast = await _weatherService.getWeeklyForecast(
        _monitoringLocation,
      );
      final allAlerts = _weatherService.calculateWeatherAlerts(forecast);

      final alerts = allAlerts
          .where((alert) => _enabledAlerts.contains(alert.type))
          .toList();

      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _forecast = forecast;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: LocationPickerWidget(
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Location alterada para $_locationName'),
              backgroundColor: Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  void _showFilterModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipos de Alertas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 20),
            ...WeatherAlertType.values.map((type) {
              final isEnabled = _enabledAlerts.contains(type);
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: isEnabled,
                  onChanged: (value) {
                    _toggleAlert(type, value);
                    Navigator.pop(context);
                  },
                  title: Row(
                    children: [
                      Text(_getAlertIcon(type), style: TextStyle(fontSize: 20)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  activeColor: Color(0xFF3B82F6),
                  dense: true,
                ),
              );
            }).toList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<WeatherAlert> get _filteredAlerts {
    return _alerts;
  }

  Color _getAlertColor(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heatWave ||
      WeatherAlertType.thermalDiscomfort => Color(0xFFF59E0B),
      WeatherAlertType.intenseCold ||
      WeatherAlertType.frostRisk => Color(0xFF3B82F6),
      WeatherAlertType.heavyRain ||
      WeatherAlertType.floodRisk => Color(0xFFEF4444),
      WeatherAlertType.severeStorm ||
      WeatherAlertType.hailRisk => Color(0xFF8B5CF6),
      WeatherAlertType.strongWind => Color(0xFF06B6D4),
    };
  }

  String _getAlertIcon(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heatWave || WeatherAlertType.thermalDiscomfort => '🌡️',
      WeatherAlertType.intenseCold || WeatherAlertType.frostRisk => '❄️',
      WeatherAlertType.heavyRain || WeatherAlertType.floodRisk => '🌧️',
      WeatherAlertType.severeStorm => '⛈️',
      WeatherAlertType.hailRisk => '🧊',
      WeatherAlertType.strongWind => '💨',
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF111827) : Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: Color(0xFF3B82F6),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildModernHeader(isDark, themeProvider),
            ),

            if (!_loading && _alerts.isNotEmpty)
              SliverToBoxAdapter(child: _buildStatsCards(isDark)),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'Loading alertas...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_alerts.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(isDark))
            else
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildModernAlertCard(
                      _filteredAlerts[index],
                      isDark,
                    );
                  }, childCount: _filteredAlerts.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, ThemeProvider themeProvider) {
    final criticalCount = _alerts.where((a) {
      return a.type == WeatherAlertType.floodRisk ||
          a.type == WeatherAlertType.severeStorm ||
          a.type == WeatherAlertType.hailRisk;
    }).length;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas Climáticos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF1F2937),
                        ),
                      ),
                      if (_alerts.isNotEmpty)
                        Text(
                          '$criticalCount alertas ativos',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                        size: 20,
                      ),
                      onPressed: () => _showFilterModal(isDark),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                        size: 20,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: _selectLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF3B82F6).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitorando',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _locationName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_location_alt,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final critical = _alerts
        .where(
          (a) =>
              a.type == WeatherAlertType.floodRisk ||
              a.type == WeatherAlertType.severeStorm ||
              a.type == WeatherAlertType.hailRisk,
        )
        .length;

    final warning = _alerts
        .where(
          (a) =>
              a.type == WeatherAlertType.heavyRain ||
              a.type == WeatherAlertType.heatWave ||
              a.type == WeatherAlertType.strongWind,
        )
        .length;

    final info = _alerts
        .where(
          (a) =>
              a.type == WeatherAlertType.thermalDiscomfort ||
              a.type == WeatherAlertType.intenseCold ||
              a.type == WeatherAlertType.frostRisk,
        )
        .length;

    return Container(
      margin: EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatCard('🚨', critical, 'Críticos', Color(0xFFEF4444), isDark),
          SizedBox(width: 12),
          _buildStatCard('⚠️', warning, 'Atenção', Color(0xFFF59E0B), isDark),
          SizedBox(width: 12),
          _buildStatCard('ℹ️', info, 'Info', Color(0xFF3B82F6), isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    int count,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAlertCard(WeatherAlert alert, bool isDark) {
    final color = _getAlertColor(alert.type);
    final icon = _getAlertIcon(alert.type);
    final dateFormat = DateFormat('EEE, d MMM', 'pt_BR');

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AlertDetailsScreen(alert: alert, forecast: _forecast),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(icon, style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.type.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            dateFormat.format(alert.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: color),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.type.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (alert.value != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, size: 14, color: color),
                            SizedBox(width: 6),
                            Text(
                              '${alert.value!.toStringAsFixed(1)} ${alert.unit ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alert.daysInSequence > 1) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF374151)
                                : Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${alert.daysInSequence} dias seguidos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1F2937) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No active alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Clima está favorável em $_locationName',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFilterModal(isDark),
            icon: Icon(Icons.tune),
            label: Text('Configurar Alertas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
