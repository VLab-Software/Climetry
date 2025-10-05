import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../disasters/presentation/widgets/location_picker_widget.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final UserDataService _userDataService = UserDataService();
  final LocationService _locationService = LocationService();
  final EventWeatherPredictionService _predictionService = EventWeatherPredictionService();
  
  List<EventWeatherAnalysis> _analyses = [];
  bool _loading = true;
  bool _loadingLocation = false;
  String _locationName = 'Carregando...';
  LatLng _location = const LatLng(-23.5505, -46.6333);
  
  // Manter estado ao trocar de tab
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
      final locationData = await _locationService.getActiveLocation();
      
      if (!mounted) return;
      setState(() {
        _location = locationData['coordinates'] as LatLng;
        _locationName = locationData['name'] as String;
        _loadingLocation = false;
      });
      
      await _loadEventsPredictions();
    } catch (e) {
      debugPrint('Erro ao carregar localização: $e');
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
      // Carregar eventos dos próximos 6 meses
      final events = await _userDataService.getActivities();
      
      // Filtrar eventos futuros (até 6 meses)
      final now = DateTime.now();
      final sixMonthsLater = now.add(const Duration(days: 180));
      
      final upcomingEvents = events.where((event) {
        return event.date.isAfter(now) && event.date.isBefore(sixMonthsLater);
      }).toList();
      
      // Ordenar por data
      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
      
      // Analisar clima para cada evento (até 10 eventos mais próximos)
      final eventsToAnalyze = upcomingEvents.take(10).toList();
      
      // Analisar cada evento individualmente
      final analyses = <EventWeatherAnalysis>[];
      for (final event in eventsToAnalyze) {
        try {
          final analysis = await _predictionService.analyzeEvent(event);
          analyses.add(analysis);
        } catch (e) {
          debugPrint('Erro ao analisar evento ${event.title}: $e');
        }
      }
      
      if (!mounted) return;
      setState(() {
        _analyses = analyses;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar previsões: $e');
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Localização alterada para $newName'),
            backgroundColor: const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadEventsPredictions,
        color: const Color(0xFF3B82F6),
        child: CustomScrollView(
          slivers: [
            // Header moderno e clean (consistente com outras telas)
            SliverToBoxAdapter(
              child: _buildModernHeader(isDark, themeProvider),
            ),

            // Lista de eventos
            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      SizedBox(height: 16),
                      Text(
                        'Analisando eventos...',
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
                        padding: EdgeInsets.all(32),
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
                        'Nenhum evento próximo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Adicione eventos na aba Agenda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildModernEventCard(_analyses[index], isDark);
                    },
                    childCount: _analyses.length,
                  ),
                ),
              ),

            // Espaço para tab bar
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, ThemeProvider themeProvider) {
    final criticalCount = _analyses.where((a) => a.risk == EventWeatherRisk.critical).length;
    final warningCount = _analyses.where((a) => a.risk == EventWeatherRisk.warning).length;
    final safeCount = _analyses.where((a) => a.risk == EventWeatherRisk.safe).length;
    
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
                      Icons.home,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Climetry',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Gestão Inteligente de Eventos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Tema
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: isDark ? Colors.white : Color(0xFF1F2937),
                        size: 20,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Localização
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
                                color: isDark ? Colors.white : Color(0xFF1F2937),
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
          // Localização atual
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
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
          // Resumo inline (sem card separado)
          if (_analyses.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(
              children: [
                _buildInlineStat('✅', safeCount, 'Seguros', Color(0xFF10B981)),
                SizedBox(width: 12),
                _buildInlineStat('⚠️', warningCount, 'Atenção', Color(0xFFF59E0B)),
                SizedBox(width: 12),
                _buildInlineStat('🚨', criticalCount, 'Críticos', Color(0xFFEF4444)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineStat(String emoji, int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEventCard(EventWeatherAnalysis analysis, bool isDark) {
    final event = analysis.activity;
    final riskColor = analysis.riskColor;
    final riskIcon = analysis.riskIcon;
    final riskText = analysis.riskLabel;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(analysis: analysis),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do card com risco
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(riskIcon, color: riskColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    riskText,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDaysUntil(event.date),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Data e hora
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(event.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (event.startTime != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.startTime!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Previsão do clima
                  if (analysis.weather != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherMetric(
                            Icons.thermostat,
                            '${analysis.weather!.meanTemp.toStringAsFixed(0)}°C',
                            isDark,
                          ),
                          _buildWeatherMetric(
                            Icons.water_drop,
                            '${analysis.weather!.precipitation.toStringAsFixed(0)}mm',
                            isDark,
                          ),
                          _buildWeatherMetric(
                            Icons.air,
                            '${analysis.weather!.windSpeed.toStringAsFixed(0)} km/h',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Alertas
                  if (analysis.alerts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: analysis.alerts.take(2).map((alert) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: riskColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAlertIcon(alert.type),
                                size: 12,
                                color: riskColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getAlertName(alert.type),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference < 7) return 'Em $difference dias';
    if (difference < 30) return 'Em ${(difference / 7).floor()} semanas';
    return 'Em ${(difference / 30).floor()} meses';
  }

  IconData _getAlertIcon(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain => Icons.water_drop,
      WeatherAlertType.severeStorm => Icons.thunderstorm,
      WeatherAlertType.heatWave => Icons.wb_sunny,
      WeatherAlertType.thermalDiscomfort => Icons.hot_tub,
      WeatherAlertType.intenseCold => Icons.ac_unit,
      WeatherAlertType.frostRisk => Icons.ac_unit,
      WeatherAlertType.strongWind => Icons.air,
      WeatherAlertType.floodRisk => Icons.waves,
      WeatherAlertType.hailRisk => Icons.cloud,
    };
  }

  String _getAlertName(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain => 'Chuva Forte',
      WeatherAlertType.severeStorm => 'Tempestade',
      WeatherAlertType.heatWave => 'Onda de Calor',
      WeatherAlertType.thermalDiscomfort => 'Desconforto',
      WeatherAlertType.intenseCold => 'Frio Intenso',
      WeatherAlertType.frostRisk => 'Geada',
      WeatherAlertType.strongWind => 'Vento Forte',
      WeatherAlertType.floodRisk => 'Enchente',
      WeatherAlertType.hailRisk => 'Granizo',
    };
  }
}
