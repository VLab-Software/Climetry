import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../weather/domain/entities/weather_alert.dart';
import '../../../weather/domain/entities/daily_weather.dart';
import '../../../../core/services/openai_service.dart';

class AlertDetailsScreen extends StatefulWidget {
  final WeatherAlert alert;
  final List<DailyWeather> forecast;

  const AlertDetailsScreen({
    super.key,
    required this.alert,
    required this.forecast,
  });

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final OpenAIService _aiService = OpenAIService();
  String? _aiInsights;
  bool _loadingInsights = false;

  @override
  void initState() {
    super.initState();
    _loadAIInsights();
  }

  Future<void> _loadAIInsights() async {
    setState(() => _loadingInsights = true);

    try {
      final alertWeather = widget.forecast.firstWhere(
        (w) =>
            w.date.day == widget.alert.date.day &&
            w.date.month == widget.alert.date.month,
        orElse: () => widget.forecast.first,
      );

      final insights = await _aiService.generateAlertInsights(
        alert: widget.alert,
        weather: alertWeather,
        location: 'São Paulo, SP', // TODO: pegar localização real
      );

      setState(() {
        _aiInsights = insights;
        _loadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _aiInsights = 'Não foi possível gerar insights da IA no momento.';
        _loadingInsights = false;
      });
    }
  }

  Color _getAlertColor() {
    switch (widget.alert.type) {
      case WeatherAlertType.heatWave:
      case WeatherAlertType.thermalDiscomfort:
        return const Color(0xFFFF6B6B);
      case WeatherAlertType.intenseCold:
      case WeatherAlertType.frostRisk:
        return const Color(0xFF4ECDC4);
      case WeatherAlertType.heavyRain:
      case WeatherAlertType.floodRisk:
        return const Color(0xFF4A9EFF);
      case WeatherAlertType.severeStorm:
      case WeatherAlertType.hailRisk:
        return const Color(0xFFFFD93D);
      case WeatherAlertType.strongWind:
        return const Color(0xFFB8B8D1);
    }
  }

  String _getAlertIcon() {
    switch (widget.alert.type) {
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
      case WeatherAlertType.hailRisk:
        return '⛈️';
      case WeatherAlertType.strongWind:
        return '💨';
    }
  }

  List<FlSpot> _getChartData() {
    final data = <FlSpot>[];

    for (int i = 0; i < widget.forecast.length && i < 7; i++) {
      final day = widget.forecast[i];
      double value = 0;

      switch (widget.alert.type) {
        case WeatherAlertType.heatWave:
        case WeatherAlertType.thermalDiscomfort:
          value = day.maxTemp;
          break;
        case WeatherAlertType.intenseCold:
        case WeatherAlertType.frostRisk:
          value = day.minTemp;
          break;
        case WeatherAlertType.heavyRain:
        case WeatherAlertType.floodRisk:
          value = day.precipitation;
          break;
        case WeatherAlertType.strongWind:
          value = day.windSpeed;
          break;
        default:
          value = day.maxTemp;
      }

      data.add(FlSpot(i.toDouble(), value));
    }

    return data;
  }

  String _getChartLabel() {
    switch (widget.alert.type) {
      case WeatherAlertType.heatWave:
      case WeatherAlertType.thermalDiscomfort:
        return 'Temperatura Máxima (°C)';
      case WeatherAlertType.intenseCold:
      case WeatherAlertType.frostRisk:
        return 'Temperatura Mínima (°C)';
      case WeatherAlertType.heavyRain:
      case WeatherAlertType.floodRisk:
        return 'Precipitação (mm)';
      case WeatherAlertType.strongWind:
        return 'Velocidade do Vento (km/h)';
      default:
        return 'Valor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor();

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.alert.type.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    alertColor.withValues(alpha: 0.3),
                    const Color(0xFF2A3A4D),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: alertColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getAlertIcon(),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.alert.type.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.alert.type.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (widget.alert.value != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: alertColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.alert.value!.toStringAsFixed(1)} ${widget.alert.unit ?? ''}',
                              style: TextStyle(
                                color: alertColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Evolução nos Próximos Dias',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getChartLabel(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A4D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < widget.forecast.length &&
                              index < 7) {
                            final date = widget.forecast[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartData(),
                      isCurved: true,
                      color: alertColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 5,
                              color: alertColor,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF2A3A4D),
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            alertColor.withValues(alpha: 0.3),
                            alertColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF2A3A4D),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}\n${widget.alert.unit ?? ''}',
                            TextStyle(
                              color: alertColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Análise Meteorológica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: _loadingInsights
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Text(
                      _aiInsights ?? 'Insights não disponíveis',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Recomendações',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._buildRecommendations(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendations() {
    final recommendations = <Map<String, String>>[];

    switch (widget.alert.type) {
      case WeatherAlertType.heatWave:
      case WeatherAlertType.thermalDiscomfort:
        recommendations.addAll([
          {
            'icon': '💧',
            'text': 'Mantenha-se hidratado, beba água regularmente',
          },
          {'icon': '🌳', 'text': 'Evite exposição ao sol entre 10h e 16h'},
          {'icon': '👕', 'text': 'Use roupas leves e de cores claras'},
          {'icon': '🧴', 'text': 'Aplique protetor solar com FPS 30 ou maior'},
        ]);
        break;
      case WeatherAlertType.intenseCold:
      case WeatherAlertType.frostRisk:
        recommendations.addAll([
          {'icon': '🧥', 'text': 'Vista-se em camadas para manter o calor'},
          {'icon': '🏠', 'text': 'Proteja plantas sensíveis ao frio'},
          {'icon': '🚗', 'text': 'Cuidado com gelo nas estradas pela manhã'},
          {
            'icon': '☕',
            'text': 'Consuma bebidas quentes para manter a temperatura',
          },
        ]);
        break;
      case WeatherAlertType.heavyRain:
      case WeatherAlertType.floodRisk:
        recommendations.addAll([
          {'icon': '☔', 'text': 'Leve guarda-chuva e capa de chuva'},
          {'icon': '🚗', 'text': 'Evite áreas propensas a alagamentos'},
          {'icon': '🏠', 'text': 'Limpe calhas e ralos preventivamente'},
          {'icon': '📱', 'text': 'Mantenha-se informado sobre alertas locais'},
        ]);
        break;
      case WeatherAlertType.severeStorm:
      case WeatherAlertType.hailRisk:
        recommendations.addAll([
          {'icon': '🏠', 'text': 'Busque abrigo em construção segura'},
          {'icon': '🚗', 'text': 'Evite estacionar sob árvores'},
          {'icon': '📱', 'text': 'Mantenha celular carregado'},
          {'icon': '⚡', 'text': 'Desligue aparelhos eletrônicos da tomada'},
        ]);
        break;
      case WeatherAlertType.strongWind:
        recommendations.addAll([
          {'icon': '🪟', 'text': 'Feche janelas e portas bem'},
          {'icon': '🌳', 'text': 'Evite áreas com árvores altas'},
          {'icon': '📦', 'text': 'Prenda objetos que possam voar'},
          {'icon': '🚗', 'text': 'Dirija com cuidado, ventos laterais fortes'},
        ]);
        break;
    }

    return recommendations
        .map(
          (rec) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3A4D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(rec['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    rec['text']!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
