import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart'; // TODO: Usar quando aplicar tema
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/current_weather.dart';
import '../../../weather/domain/entities/hourly_weather.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/services/openai_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
// import '../../../../core/theme/theme_provider.dart'; // TODO: Usar quando aplicar tema
// import '../../../../core/theme/app_theme.dart'; // TODO: Usar quando aplicar tema
// import '../../../../core/widgets/animated_widgets.dart'; // TODO: Usar quando aplicar tema
import '../../../disasters/presentation/widgets/location_picker_widget.dart';
import 'dart:math' as math;
// import 'dart:convert'; // TODO: Usar quando implementar análise de eventos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MeteomaticsService _weatherService = MeteomaticsService();
  final OpenAIService _aiService = OpenAIService();
  final UserDataService _userDataService = UserDataService();
  final LocationService _locationService = LocationService();
  
  CurrentWeather? _currentWeather;
  List<HourlyWeather> _hourlyForecast = [];
  Activity? _nextActivity;
  DailyWeather? _nextActivityWeather;
  String? _activityTips;
  Map<String, dynamic>? _alternativeLocations;
  List<Map<String, String>> _insightCards = [];
  bool _loading = true;
  bool _loadingInsights = false;
  bool _loadingLocation = false;
  String? _error;
  String _locationName = 'Carregando...';
  LatLng _location = const LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _loadingLocation = true);
    
    try {
      final locationData = await _locationService.getActiveLocation();
      
      if (mounted) {
        setState(() {
          _location = locationData['coordinates'] as LatLng;
          _locationName = locationData['name'] as String;
          _loadingLocation = false;
        });
        
        // Carregar dados do tempo após obter localização
        _loadWeather();
        _loadNextActivity();
      }
    } catch (e) {
      debugPrint('Erro ao carregar localização: $e');
      if (mounted) {
        setState(() {
          _locationName = 'São Paulo';
          _loadingLocation = false;
        });
        _loadWeather();
        _loadNextActivity();
      }
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
      
      // Salvar nova localização
      await _locationService.saveCustomLocation(
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        name: newName,
      );
      
      setState(() {
        _location = newLocation;
        _locationName = newName;
      });
      
      // Recarregar dados do tempo
      _loadWeather();
      _loadNextActivity();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Localização alterada para $newName'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2A3A4D),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    
    try {
      // Ativar uso de GPS
      await _locationService.setUseCurrentLocation(true);
      
      // Recarregar localização
      await _loadLocation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Usando sua localização atual: $_locationName'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2A3A4D),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Não foi possível obter sua localização'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2A3A4D),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final current = await _weatherService.getCurrentWeather(_location);
      final hourly = await _weatherService.getHourlyForecast(_location);
      
      setState(() {
        _currentWeather = current;
        _hourlyForecast = hourly;
        _loading = false;
      });

      // Carregar insights da IA
      _loadAIInsights();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              onPressed: _loadWeather,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadNextActivity() async {
    try {
      final activities = await _userDataService.getActivities();
      
      if (activities.isEmpty) return;

      // Filtrar atividades futuras e ordenar por data
      final futureActivities = activities.where(
        (a) => a.date.isAfter(DateTime.now())
      ).toList()..sort((a, b) => a.date.compareTo(b.date));

      if (futureActivities.isEmpty) return;

      final next = futureActivities.first;
      
      // Buscar previsão do tempo para o dia da atividade
      final forecast = await _weatherService.getWeeklyForecast(next.coordinates);
      final activityWeather = forecast.firstWhere(
        (w) => w.date.day == next.date.day && 
               w.date.month == next.date.month &&
               w.date.year == next.date.year,
        orElse: () => forecast.first,
      );

      // Buscar alertas
      final alerts = _weatherService.calculateWeatherAlerts(forecast)
        .where((alert) => alert.date.day == next.date.day)
        .toList();

      // Gerar dicas da IA
      final tips = await _aiService.generateActivityTips(
        activity: next,
        weather: activityWeather,
        alerts: alerts,
      );

      // Verificar se evento é ao ar livre e clima está ruim
      Map<String, dynamic>? alternatives;
      final isOutdoorActivity = next.type == ActivityType.outdoor || 
                                 next.type == ActivityType.sport;
      
      if (isOutdoorActivity && _shouldSuggestAlternatives(activityWeather, alerts)) {
        alternatives = await _aiService.suggestAlternativeLocations(
          activity: next,
          cityName: _locationName,
          weather: activityWeather,
          alerts: alerts,
        );
      }

      if (mounted) {
        setState(() {
          _nextActivity = next;
          _nextActivityWeather = activityWeather;
          _activityTips = tips;
          _alternativeLocations = alternatives;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar próxima atividade: $e');
    }
  }

  bool _shouldSuggestAlternatives(DailyWeather weather, List<dynamic> alerts) {
    // Sugere alternativas se houver alertas críticos ou condições ruins
    if (alerts.isNotEmpty) return true;
    if (weather.precipitationProbability > 60) return true;
    if (weather.windSpeed > 50) return true;
    return false;
  }

  Future<void> _loadAIInsights() async {
    if (_currentWeather == null) return;

    setState(() => _loadingInsights = true);

    try {
      final cards = await _aiService.generateWeatherInsightCards(
        temperature: _currentWeather!.temperature,
        humidity: _currentWeather!.humidity,
        uvIndex: _currentWeather!.uvIndex,
        windSpeed: _currentWeather!.windSpeed,
        precipitation: _currentWeather!.precipitation,
        location: _locationName,
      );

      if (mounted) {
        setState(() {
          _insightCards = cards;
          _loadingInsights = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar insights: $e');
      setState(() => _loadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat.EEEE('pt_BR').format(now);
    final date = DateFormat('d \'de\' MMMM', 'pt_BR').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadWeather();
                      await _loadNextActivity();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Adiciona padding bottom para floating tab bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(dayOfWeek, date),
                          const SizedBox(height: 24),
                          
                          // Card do Próximo Evento
                          if (_nextActivity != null) ...[
                            _buildNextEventCard(),
                            const SizedBox(height: 24),
                          ],
                          
                          if (_currentWeather != null) ...[
                            _buildMainWeatherCard(),
                            const SizedBox(height: 24),
                            _buildWeatherDetails(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Cards de Insights da IA
                          if (_insightCards.isNotEmpty) ...[
                            _buildAIInsightsSection(),
                            const SizedBox(height: 24),
                          ],
                          
                          if (_hourlyForecast.isNotEmpty) ...[
                            _buildHourlyForecastSection(),
                            const SizedBox(height: 24),
                            _buildTemperatureChart(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              'Erro ao Carregar Clima',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Erro desconhecido',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9EFF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dayOfWeek, String date) {
    return Column(
      children: [
        Row(
          children: [
            // Botão para usar localização atual (GPS)
            IconButton(
              onPressed: _loadingLocation ? null : _useCurrentLocation,
              icon: Icon(
                Icons.my_location,
                color: _loadingLocation
                    ? Colors.white38
                    : const Color(0xFF4A9EFF),
              ),
              tooltip: 'Usar minha localização',
            ),
            const Spacer(),
            GestureDetector(
              onTap: _changeLocation,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.edit_location_alt,
                        color: Color(0xFF4A9EFF),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dayOfWeek, $date',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Botão para abrir configurações (espaço reservado)
            IconButton(
              onPressed: () {
                // TODO: Abrir tela de configurações
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configurações em breve...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings,
                color: Colors.white54,
              ),
              tooltip: 'Configurações',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    final weather = _currentWeather!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9EFF).withValues(alpha: 0.3),
            const Color(0xFF2A3A4D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            weather.weatherIcon,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.temperature.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                '°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          Text(
            weather.mainCondition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sensação térmica ${weather.feelsLike.round()}°',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMinMaxTemp('Min', weather.minTemp),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildMinMaxTemp('Máx', weather.maxTemp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinMaxTemp(String label, double temp) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${temp.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetails() {
    final weather = _currentWeather!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.water_drop,
                  'Umidade',
                  '${weather.humidity.round()}%',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.air,
                  'Vento',
                  '${weather.windSpeed.round()} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.wb_sunny,
                  'Índice UV',
                  weather.uvIndex.round().toString(),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.umbrella,
                  'Chuva',
                  '${weather.precipitationProbability.round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A9EFF), size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsão Horária',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(_hourlyForecast.length, 24),
            itemBuilder: (context, index) {
              final forecast = _hourlyForecast[index];
              return _buildHourlyCard(forecast);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyCard(HourlyWeather forecast) {
    final time = DateFormat.Hm('pt_BR').format(forecast.time);
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            forecast.precipitation > 0 ? '🌧️' : '☀️',
            style: const TextStyle(fontSize: 28),
          ),
          Text(
            '${forecast.temperature.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (forecast.precipitationProbability > 20)
            Text(
              '${forecast.precipitationProbability.round()}%',
              style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    if (_hourlyForecast.length < 2) return const SizedBox.shrink();
    
    // Simplificado - remover gráfico complexo temporariamente
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendência de Temperatura (24h)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A3A4D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Gráfico de tendência em desenvolvimento',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextEventCard() {
    if (_nextActivity == null || _nextActivityWeather == null) {
      return const SizedBox.shrink();
    }

    final activity = _nextActivity!;
    final weather = _nextActivityWeather!;
    final daysUntil = activity.date.difference(DateTime.now()).inDays;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5DD3D3).withValues(alpha: 0.3),
            const Color(0xFF2A3A4D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5DD3D3).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5DD3D3).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      activity.type.icon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Próximo Evento',
                        style: TextStyle(
                          color: Color(0xFF5DD3D3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        daysUntil == 0
                            ? 'Hoje'
                            : daysUntil == 1
                                ? 'Amanhã'
                                : 'Em $daysUntil dias',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Previsão do Tempo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A3A).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEventWeatherItem(
                      '🌡️',
                      '${weather.minTemp.toInt()}-${weather.maxTemp.toInt()}°C',
                    ),
                    _buildEventWeatherItem(
                      '💧',
                      '${weather.precipitationProbability.toInt()}%',
                    ),
                    _buildEventWeatherItem(
                      '💨',
                      '${weather.windSpeed.toInt()} km/h',
                    ),
                  ],
                ),
                
                if (_activityTips != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🤖',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dicas da IA',
                              style: TextStyle(
                                color: Color(0xFF5DD3D3),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _activityTips!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (_alternativeLocations != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showAlternativeLocationsDialog(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD93D).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('⚠️', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clima Desfavorável Detectado',
                                  style: TextStyle(
                                    color: Color(0xFFFFD93D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ver locais alternativos sugeridos pela IA',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFFFD93D),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventWeatherItem(String emoji, String text) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Insights Climáticos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A9EFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    'IA',
                    style: TextStyle(
                      color: Color(0xFF4A9EFF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_loadingInsights)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _insightCards.length,
              itemBuilder: (context, index) {
                final card = _insightCards[index];
                return _buildInsightCard(
                  icon: card['icon']!,
                  title: card['title']!,
                  tip: card['tip']!,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String icon,
    required String title,
    required String tip,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9EFF).withValues(alpha: 0.15),
            const Color(0xFF2A3A4D),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A9EFF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showAlternativeLocationsDialog() {
    if (_alternativeLocations == null) return;

    final alternatives = _alternativeLocations!['alternatives'] as List? ?? [];
    final reason = _alternativeLocations!['reason'] as String? ?? 
                   'Condições climáticas desfavoráveis detectadas';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1E2A3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD93D).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('⚠️', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Locais Alternativos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text('🤖', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Sugeridos pela IA',
                                  style: TextStyle(
                                    color: Color(0xFF4A9EFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index] as Map<String, dynamic>;
                  return _buildAlternativeCard(alt);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> alternative) {
    final name = alternative['name'] as String? ?? 'Local não especificado';
    final type = alternative['type'] as String? ?? '';
    final reason = alternative['reason'] as String? ?? '';
    final address = alternative['address'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A9EFF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9EFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.place,
                  color: Color(0xFF4A9EFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (type.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: TextStyle(
                          color: const Color(0xFF4A9EFF).withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reason,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
