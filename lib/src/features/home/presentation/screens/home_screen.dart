import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/current_weather.dart';
import '../../../weather/domain/entities/hourly_weather.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MeteomaticsService _weatherService = MeteomaticsService();
  CurrentWeather? _currentWeather;
  List<HourlyWeather> _hourlyForecast = [];
  bool _loading = true;
  String? _error;
  String _locationName = 'São Paulo, SP';
  final LatLng _location = const LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    _loadWeather();
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
                    onRefresh: _loadWeather,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Adiciona padding bottom para floating tab bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(dayOfWeek, date),
                          const SizedBox(height: 24),
                          if (_currentWeather != null) ...[
                            _buildMainWeatherCard(),
                            const SizedBox(height: 24),
                            _buildWeatherDetails(),
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
            const Spacer(),
            Column(
              children: [
                Text(
                  _locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
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
            const Spacer(),
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
}

