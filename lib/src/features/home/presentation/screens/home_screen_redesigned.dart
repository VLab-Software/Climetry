import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../disasters/presentation/widgets/location_picker_widget.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final UserDateService _userDateService = UserDateService();
  final LocationService _locationService = LocationService();
  final EventWeatherPredictionService _predictionService =
      EventWeatherPredictionService();

  List<Activity> _upcomingEvents = [];
  List<EventWeatherAnalysis> _analyses = [];
  bool _loading = true;
  bool _loadingLocation = false;
  String _locationName = 'Loading...';
  LatLng _location = const LatLng(-23.5505, -46.6333);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);

    try {
      final locationDate = await _locationService.getActiveLocation();
      if (!mounted) return;
      setState(() {
        _location = locationDate['coordinates'] as LatLng;
        _locationName = locationDate['name'] as String;
        _loadingLocation = false;
      });
      await _loadEventsPredictions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationName = 'São Paulo';
        _loadingLocation = false;
      });
      await _loadEventsPredictions();
    }
  }

  Future<void> _loadEventsPredictions() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final events = await _userDateService.getActivities();
      final now = DateTime.now();
      final sixMonthsLater = now.add(const Duration(days: 180));

      final upcomingEvents = events.where((event) {
        return event.date.isAfter(now) && event.date.isBefore(sixMonthsLater);
      }).toList();

      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
      final eventsToAnalyze = upcomingEvents.take(10).toList();

      final analyses = <EventWeatherAnalysis>[];
      for (final event in eventsToAnalyze) {
        try {
          final analysis = await _predictionService.analyzeEvent(event);
          analyses.add(analysis);
        } catch (e) {
          debugPrint('Error ao analisar ewind ${event.title}: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _upcomingEvents = upcomingEvents;
        _analyses = analyses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          initialLocation: _location,
          initialLocationName: _locationName,
        ),
      ),
    );

    if (result != null && mounted) {
      final newLocation = result['location'] as LatLng;
      final newName = result['name'] as String;

      await _locationService.saveCustomLocation(
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        name: newName,
      );

      if (!mounted) return;
      setState(() {
        _location = newLocation;
        _locationName = newName;
      });
      await _loadEventsPredictions();
    }
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
      backgroundColor: isDark
          ? const Color(0xFF0F1419)
          : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadEventsPredictions,
        color: const Color(0xFF3B82F6),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildModernHeader(isDark, themeProvider),
            ),

            if (!_loading && _analyses.isNotEmpty)
              SliverToBoxAdapter(child: _buildCleanSummaryCard(isDark)),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'Analisando ewinds...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_analyses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1F2937) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No upcoming events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Adicione ewinds na aba Agenda',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildModernEventCard(_analyses[index], isDark);
                  }, childCount: _analyses.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, ThemeProvider themeProvider) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Climetry',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestão Inteligente de Ewinds',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
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
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                        size: 20,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: _loadingLocation
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? Colors.white
                                    : Color(0xFF1F2937),
                              ),
                            )
                          : Icon(
                              Icons.location_on_outlined,
                              color: isDark ? Colors.white : Color(0xFF1F2937),
                              size: 20,
                            ),
                      onPressed: _loadingLocation ? null : _changeLocation,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 6),
                Text(
                  _locationName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanSummaryCard(bool isDark) {
    final criticalCount = _analyses
        .where((a) => a.risk == EventWeatherRisk.critical)
        .length;
    final warningCount = _analyses
        .where((a) => a.risk == EventWeatherRisk.warning)
        .length;
    final safeCount = _analyses
        .where((a) => a.risk == EventWeatherRisk.safe)
        .length;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Análise de Ewinds',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  '✅',
                  safeCount.toString(),
                  'Seguros',
                  Color(0xFF10B981),
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  '⚠️',
                  warningCount.toString(),
                  'Atenção',
                  Color(0xFFF59E0B),
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  '🚨',
                  criticalCount.toString(),
                  'Críticos',
                  Color(0xFFEF4444),
                  isDark,
                ),
              ),
            ],
          ),
          if (_upcomingEvents.length > 10) ...[
            SizedBox(height: 12),
            Text(
              '+${_upcomingEvents.length - 10} ewinds adicionais',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    String emoji,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
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
            value,
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
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEventCard(EventWeatherAnalysis analysis, bool isDark) {
    final dateFormat = DateFormat('dd MMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(analysis: analysis),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: analysis.riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          analysis.activity.type.icon,
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.activity.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${dateFormat.format(analysis.activity.date)} • ${timeFormat.format(analysis.activity.date)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: analysis.riskColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analysis.riskIcon,
                            size: 14,
                            color: analysis.riskColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            analysis.riskLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: analysis.riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (analysis.weather != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF374151) : Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildWeatherInfo(
                          Icons.thermostat,
                          '${analysis.weather!.maxTemp.toStringAsFixed(0)}°',
                          isDark,
                        ),
                        SizedBox(width: 16),
                        _buildWeatherInfo(
                          Icons.water_drop,
                          '${analysis.weather!.precipitation.toStringAsFixed(0)}mm',
                          isDark,
                        ),
                        SizedBox(width: 16),
                        _buildWeatherInfo(
                          Icons.air,
                          '${analysis.weather!.windSpeed.toStringAsFixed(0)}km/h',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],

                if (analysis.alerts.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: analysis.alerts.take(3).map((alert) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getAlertLabel(alert.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Color(0xFF3B82F6)),
                    SizedBox(width: 4),
                    Text(
                      'Em ${analysis.daysUntilEvent} dias',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(IconDate icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  String _getAlertLabel(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.heavyRain:
        return 'Rain Forte';
      case WeatherAlertType.floodRisk:
        return 'Risco de Alagamento';
      case WeatherAlertType.heatWave:
        return 'Calor Extremo';
      case WeatherAlertType.intenseCold:
        return 'Frio Intenso';
      case WeatherAlertType.frostRisk:
        return 'Risco de Geada';
      case WeatherAlertType.strongWind:
        return 'Wind Forte';
      case WeatherAlertType.severeStorm:
        return 'Tempestade';
      case WeatherAlertType.thermalDiscomfort:
        return 'Desconforto Térmico';
      default:
        return type.toString();
    }
  }
}
