import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/event_weather_prediction_service.dart';
import '../../../../core/widgets/event_weather_card.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../disasters/presentation/widgets/location_picker_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final UserDataService _userDataService = UserDataService();
  final LocationService _locationService = LocationService();
  final EventWeatherPredictionService _predictionService =
      EventWeatherPredictionService();

  List<Activity> _upcomingEvents = [];
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
        _upcomingEvents = upcomingEvents;
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
            backgroundColor: const Color(0xFF4A9EFF),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A2332)
          : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // AppBar moderno
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF2A3A4D)
                : const Color(0xFF4A9EFF),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Climetry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Gestão Inteligente de Eventos',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Color(0xFF2A3A4D), Color(0xFF1A2332)]
                        : [Color(0xFF4A9EFF), Color(0xFF5DADE2)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Ícones decorativos
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Icon(
                        Icons.cloud_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      top: 100,
                      left: 40,
                      child: Icon(
                        Icons.calendar_today,
                        size: 40,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Botão trocar tema
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
              // Botão trocar localização
              IconButton(
                icon: _loadingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.location_on, color: Colors.white),
                onPressed: _loadingLocation ? null : _changeLocation,
              ),
            ],
          ),

          // Localização atual
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: isDark ? Color(0xFF4A9EFF) : Color(0xFF2A3A4D),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _locationName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF2A3A4D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resumo de eventos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildEventsSummary(isDark),
            ),
          ),

          // Lista de eventos com previsões
          if (_loading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_analyses.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum evento nos próximos 6 meses',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Adicione eventos na aba Agenda',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventWeatherCard(
                      analysis: _analyses[index],
                      compact: false,
                    ),
                  );
                }, childCount: _analyses.length),
              ),
            ),

          // Espaço para o bottom navigation bar
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEventsSummary(bool isDark) {
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2A3A4D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: isDark ? Color(0xFF4A9EFF) : Color(0xFF2A3A4D),
              ),
              SizedBox(width: 8),
              Text(
                'Resumo dos Eventos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF2A3A4D),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '🔴',
                'Crítico',
                criticalCount,
                Colors.red,
                isDark,
              ),
              _buildSummaryItem(
                '🟡',
                'Atenção',
                warningCount,
                Colors.orange,
                isDark,
              ),
              _buildSummaryItem(
                '🟢',
                'Seguro',
                safeCount,
                Colors.green,
                isDark,
              ),
            ],
          ),
          if (_upcomingEvents.length > 10) ...[
            SizedBox(height: 12),
            Text(
              '+${_upcomingEvents.length - 10} eventos adicionais',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String emoji,
    String label,
    int count,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(emoji, style: TextStyle(fontSize: 24)),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
