import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../weather/data/services/meteomatics_service.dart';
import '../../../weather/domain/entities/daily_weather.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final MeteomaticsService _weatherService = MeteomaticsService();
  DailyWeather? _weatherForecast;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    try {
      final forecast = await _weatherService.getWeeklyForecast(
        widget.activity.coordinates,
      );
      // Encontrar previsão para o dia da atividade
      final activityWeather = forecast.firstWhere(
        (w) =>
            w.date.day == widget.activity.date.day &&
            w.date.month == widget.activity.date.month &&
            w.date.year == widget.activity.date.year,
        orElse: () => forecast.first,
      );
      setState(() {
        _weatherForecast = activityWeather;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _getTimeUntilEvent() {
    final now = DateTime.now();
    final difference = widget.activity.date.difference(now);

    if (difference.isNegative) return 'Evento passou';

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else {
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  String _getRainChanceLevel(double probability) {
    if (probability < 30) return 'Baixa';
    if (probability < 70) return 'Média';
    return 'Alta';
  }

  Color _getRainChanceColor(double probability) {
    if (probability < 30) return Colors.green;
    if (probability < 70) return Colors.orange;
    return Colors.red;
  }

  Future<void> _shareOnWhatsApp() async {
    final message =
        '''
🌤️ ${widget.activity.title}

📍 ${widget.activity.location}
📅 ${DateFormat('d MMM yyyy', 'pt_BR').format(widget.activity.date)}
⏰ ${widget.activity.startTime ?? 'Horário não definido'}

${_weatherForecast != null ? '🌡️ Temperatura: ${_weatherForecast!.tempMin.toInt()}°C - ${_weatherForecast!.tempMax.toInt()}°C\n☔ Chance de chuva: ${_weatherForecast!.precipProbability.toInt()}%' : ''}

Vamos juntos? 😊
''';

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addToCalendar() async {
    final startDate = widget.activity.date;
    final title = Uri.encodeComponent(widget.activity.title);
    final location = Uri.encodeComponent(widget.activity.location);
    final details = Uri.encodeComponent(
      '${widget.activity.description ?? ''}\n\nPrevisão: ${_weatherForecast?.mainCondition ?? 'N/A'}',
    );

    // Google Calendar URL
    final dateFormat = DateFormat('yyyyMMddTHHmmss');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(startDate.add(const Duration(hours: 2)));

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=${startStr}Z/${endStr}Z&details=$details&location=$location',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');

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
            onPressed: _shareOnWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(widget.activity.date),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.activity.startTime ?? '--:--'} - ${widget.activity.endTime ?? '9:00'}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.activity.location,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tempo para o evento
                  _buildTimeUntilCard(),
                  const SizedBox(height: 16),

                  // Chance de chuva
                  if (_weatherForecast != null) ...[
                    _buildRainChanceCard(),
                    const SizedBox(height: 24),

                    // Condição climática
                    const Text(
                      'Possível condição climática para a hora do evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWeatherConditions(),
                    const SizedBox(height: 24),

                    // Recomendações
                    const Text(
                      'Recomendações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendations(),
                  ],

                  const SizedBox(height: 24),
                  _buildActionButton(
                    'Ver mais detalhes',
                    Colors.transparent,
                    const Color(0xFF4A9EFF),
                    () {
                      // Navegar para tela de detalhes expandida
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Salvar no Calendário',
                    const Color(0xFF4A9EFF),
                    Colors.white,
                    _addToCalendar,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeUntilCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Tempo para o evento',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _getTimeUntilEvent(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainChanceCard() {
    final probability = _weatherForecast!.precipProbability;
    final level = _getRainChanceLevel(probability);
    final color = _getRainChanceColor(probability);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Chance de chuva',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$level (${probability.toInt()}%)',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A previsão pode mudar. Verifique novamente mais perto do evento.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherConditions() {
    final times = ['8:00', '8:30', '9:00'];
    final temps = [
      _weatherForecast!.tempMin.toInt() + 2,
      (_weatherForecast!.tempMin + _weatherForecast!.tempMax) ~/ 2,
      _weatherForecast!.tempMax.toInt() - 2,
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final isSelected = index == 1;
          return Container(
            width: 120,
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A9EFF).withOpacity(0.3)
                  : const Color(0xFF2A3A4D),
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: const Color(0xFF4A9EFF), width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  times[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _weatherForecast!.weatherIcon,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  '${temps[index]}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    if (_weatherForecast!.uvIndex > 5) {
      recommendations.add({
        'icon': '☀️',
        'text': 'Leve protetor solar',
        'color': const Color(0xFFFFF8E1),
      });
    }

    if (_weatherForecast!.tempMax > 28) {
      recommendations.add({
        'icon': '💧',
        'text': 'Hidrate-se bem',
        'color': const Color(0xFFE3F2FD),
      });
    }

    if (_weatherForecast!.precipProbability > 50) {
      recommendations.add({
        'icon': '⛈️',
        'text': 'Cancele se houver tempestade',
        'color': const Color(0xFFFFEBEE),
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': '✅',
        'text':
            'O tempo estará agradável. Leve um agasalho leve para o final da tarde.',
        'color': const Color(0xFFF1F8E9),
      });
    }

    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (rec['color'] as Color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (rec['color'] as Color).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rec['color'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rec['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['text'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: bgColor == Colors.transparent
                ? BorderSide(color: textColor)
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A3A4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Editar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar para edição
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
