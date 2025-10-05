import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../../weather/domain/entities/weather_alert.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final MeteomaticsService _weatherService = MeteomaticsService();
  DailyWeather? _weatherForecast;
  List<WeatherAlert> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Buscar previsão do tempo
      final forecast = await _weatherService.getWeeklyForecast(widget.activity.coordinates);
      
      if (!mounted) return;
      
      // Encontrar previsão para o dia da atividade
      final activityDate = widget.activity.date;
      final activityWeather = forecast.firstWhere(
        (w) => _isSameDay(w.date, activityDate),
        orElse: () => forecast.isNotEmpty ? forecast.first : _createDefaultWeather(),
      );

      // Calcular alertas para toda a previsão
      final allAlerts = _weatherService.calculateWeatherAlerts(forecast);
      
      // Filtrar alertas para o dia da atividade
      final activityAlerts = allAlerts.where((alert) => 
        _isSameDay(alert.date, activityDate)
      ).toList();

      if (!mounted) return;

      setState(() {
        _weatherForecast = activityWeather;
        _alerts = activityAlerts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DailyWeather _createDefaultWeather() {
    return DailyWeather(
      date: widget.activity.date,
      minTemp: 0,
      maxTemp: 0,
      meanTemp: 0,
      precipitation: 0,
      windSpeed: 0,
      humidity: 0,
      uvIndex: 0,
      precipitationProbability: 0,
    );
  }

  String _getTimeUntilEvent() {
    final now = DateTime.now();
    final difference = widget.activity.date.difference(now);

    if (difference.isNegative) {
      final pastDays = -difference.inDays;
      if (pastDays == 0) return 'Hoje (passou)';
      if (pastDays == 1) return 'Ontem';
      return 'Há $pastDays dias';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days == 0) {
      if (hours == 0) return 'Agora';
      return 'Em $hours horas';
    } else if (days == 1) {
      return 'Amanhã';
    } else if (days <= 7) {
      return 'Em $days dias';
    } else {
      final weeks = (days / 7).floor();
      return 'Em $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
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

  String _getRecommendation() {
    if (_weatherForecast == null) return 'Carregando recomendações...';
    
    final weather = _weatherForecast!;
    final recommendations = <String>[];
    
    // Chuva
    if (weather.precipitationProbability > 70) {
      recommendations.add('☔ Leve guarda-chuva e capa de chuva');
    } else if (weather.precipitationProbability > 30) {
      recommendations.add('🌂 Risco de chuva - leve guarda-chuva');
    }
    
    // Temperatura
    if (weather.maxTemp > 30) {
      recommendations.add('🌡️ Muito calor - use protetor solar e hidrate-se');
    } else if (weather.maxTemp < 15) {
      recommendations.add('🧥 Frio - leve casaco');
    }
    
    // UV
    if (weather.uvIndex > 7) {
      recommendations.add('🕶️ UV alto - use protetor e óculos');
    }
    
    // Vento
    if (weather.windSpeed > 40) {
      recommendations.add('💨 Vento forte - cuidado com objetos soltos');
    }
    
    // Sem problemas
    if (recommendations.isEmpty) {
      recommendations.add('✅ Clima ideal para o evento!');
    }
    
    return recommendations.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        title: const Text('Detalhes da Atividade'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareActivity,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadWeatherData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildWeatherCard(),
                        const SizedBox(height: 16),
                        if (_alerts.isNotEmpty) ...[
                          _buildAlertsSection(),
                          const SizedBox(height: 16),
                        ],
                        _buildRecommendationsCard(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
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
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar previsão',
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
              onPressed: _loadWeatherData,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9EFF).withValues(alpha: 0.3),
            const Color(0xFF2A3A4D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9EFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    widget.activity.type.icon,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.activity.type.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9EFF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Color(0xFF4A9EFF), size: 18),
                const SizedBox(width: 8),
                Text(
                  _getTimeUntilEvent(),
                  style: const TextStyle(
                    color: Color(0xFF4A9EFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherForecast == null) {
      return const Card(
        color: Color(0xFF2A3A4D),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final weather = _weatherForecast!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🌤️',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Previsão do Tempo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM', 'pt_BR').format(widget.activity.date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherItem(
                Icons.thermostat,
                '${weather.minTemp.toInt()}°C - ${weather.maxTemp.toInt()}°C',
                'Temperatura',
              ),
              _buildWeatherItem(
                Icons.water_drop,
                '${weather.precipitationProbability.toInt()}%',
                'Chuva',
              ),
              _buildWeatherItem(
                Icons.air,
                '${weather.windSpeed.toInt()} km/h',
                'Vento',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherItem(
                Icons.opacity,
                '${weather.humidity.toInt()}%',
                'Umidade',
              ),
              _buildWeatherItem(
                Icons.wb_sunny,
                weather.uvIndex.toInt().toString(),
                'UV',
              ),
              _buildWeatherItem(
                Icons.umbrella,
                '${weather.precipitation.toStringAsFixed(1)} mm',
                'Precip.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A9EFF), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Alertas (${_alerts.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._alerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAlertColor(alert.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getAlertColor(alert.type).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAlertColor(alert.type),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getAlertIcon(alert.type),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.type.label,
                          style: TextStyle(
                            color: _getAlertColor(alert.type),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.type.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (alert.value != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${alert.value!.toStringAsFixed(1)} ${alert.unit ?? ''}',
                            style: TextStyle(
                              color: _getAlertColor(alert.type),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Recomendações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getRecommendation(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            'Data',
            DateFormat('d MMMM yyyy', 'pt_BR').format(widget.activity.date),
          ),
          if (widget.activity.startTime != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              'Horário',
              widget.activity.startTime!,
            ),
          ],
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.location_on,
            'Local',
            widget.activity.location,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.pin_drop,
            'Coordenadas',
            '${widget.activity.coordinates.latitude.toStringAsFixed(4)}, ${widget.activity.coordinates.longitude.toStringAsFixed(4)}',
          ),
          if (widget.activity.description != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              'Descrição',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A9EFF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.map),
            label: const Text('Ver no Mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareActivity,
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareActivity() async {
    final weather = _weatherForecast;
    final alertsText = _alerts.isNotEmpty
        ? '\n⚠️ Alertas: ${_alerts.map((a) => a.type.label).join(', ')}'
        : '';
    
    final message = '''
🌤️ ${widget.activity.title}

📍 ${widget.activity.location}
📅 ${DateFormat('d MMM yyyy', 'pt_BR').format(widget.activity.date)}
⏰ ${widget.activity.startTime ?? 'Horário não definido'}

${weather != null ? '🌡️ ${weather.minTemp.toInt()}°C - ${weather.maxTemp.toInt()}°C\n☔ Chuva: ${weather.precipitationProbability.toInt()}%' : ''}$alertsText

${_getRecommendation()}

Vamos juntos? 😊
''';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final lat = widget.activity.coordinates.latitude;
    final lng = widget.activity.coordinates.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
