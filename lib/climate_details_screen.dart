import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class ClimateDetailsScreen extends StatefulWidget {
  final String location;
  final String date;
  final LatLng coordinates;
  final Map<String, dynamic>? weatherData;

  const ClimateDetailsScreen({
    super.key,
    required this.location,
    required this.date,
    required this.coordinates,
    this.weatherData,
  });

  @override
  State<ClimateDetailsScreen> createState() => _ClimateDetailsScreenState();
}

class _ClimateDetailsScreenState extends State<ClimateDetailsScreen> {
  List<VariableData> variables = [];
  String alertTitle = 'Analisando dados...';
  String alertMessage = '';
  double alertProbability = 0;

  @override
  void initState() {
    super.initState();
    _processWeatherData();
  }

  void _processWeatherData() {
    if (widget.weatherData == null || widget.weatherData!['data'] == null) {
      return;
    }

    try {
      final data = widget.weatherData!['data'] as List;
      variables.clear();

      for (var item in data) {
        final parameter = item['parameter'] as String;
        final coords = item['coordinates'][0];
        final dates = coords['dates'] as List;

        List<TimeSeriesPoint> timeSeriesData = [];
        List<double> values = [];

        for (var dateEntry in dates) {
          final dateStr = dateEntry['date'] as String;
          final value = dateEntry['value'];
          if (value != null) {
            final doubleValue = value.toDouble();
            values.add(doubleValue);
            timeSeriesData.add(TimeSeriesPoint(
              DateTime.parse(dateStr),
              doubleValue,
            ));
          }
        }

        if (values.isNotEmpty) {
          final variableName = _getVariableName(parameter);
          final unit = _getUnit(parameter);
          final icon = _getIcon(parameter);

          variables.add(VariableData(
            name: variableName,
            parameter: parameter,
            unit: unit,
            icon: icon,
            currentValue: values.last,
            minValue: values.reduce(math.min),
            maxValue: values.reduce(math.max),
            avgValue: values.reduce((a, b) => a + b) / values.length,
            change: values.length > 1 && values.first != 0
                ? ((values.last - values.first) / values.first * 100)
                : 0,
            timeSeriesData: timeSeriesData,
          ));
        }
      }

      // Generate alert based on data
      _generateAlert();
      setState(() {});
    } catch (e) {
      print('Error processing weather data: $e');
    }
  }

  String _getVariableName(String parameter) {
    if (parameter.contains('t_2m')) return 'Temperatura';
    if (parameter.contains('precip')) return 'Precipitação';
    if (parameter.contains('wind_speed')) return 'Velocidade do Vento';
    if (parameter.contains('relative_humidity')) return 'Umidade';
    if (parameter.contains('pressure')) return 'Pressão';
    if (parameter.contains('cloud_cover')) return 'Cobertura de Nuvens';
    if (parameter.contains('uv')) return 'Índice UV';
    if (parameter.contains('visibility')) return 'Visibilidade';
    if (parameter.contains('dew_point')) return 'Ponto de Orvalho';
    if (parameter.contains('global_rad')) return 'Radiação Solar';
    return parameter;
  }

  String _getUnit(String parameter) {
    if (parameter.contains(':C')) return '°C';
    if (parameter.contains(':mm')) return 'mm';
    if (parameter.contains(':ms')) return 'm/s';
    if (parameter.contains(':p')) return '%';
    if (parameter.contains(':hPa')) return 'hPa';
    if (parameter.contains(':idx')) return '';
    if (parameter.contains(':m')) return 'm';
    if (parameter.contains(':W')) return 'W/m²';
    return '';
  }

  IconData _getIcon(String parameter) {
    if (parameter.contains('t_2m')) return Icons.thermostat_outlined;
    if (parameter.contains('precip')) return Icons.water_drop_outlined;
    if (parameter.contains('wind_speed')) return Icons.air;
    if (parameter.contains('relative_humidity')) return Icons.water_outlined;
    if (parameter.contains('pressure')) return Icons.speed;
    if (parameter.contains('cloud_cover')) return Icons.cloud_outlined;
    if (parameter.contains('uv')) return Icons.wb_sunny_outlined;
    if (parameter.contains('visibility')) return Icons.visibility;
    if (parameter.contains('dew_point')) return Icons.opacity;
    if (parameter.contains('global_rad')) return Icons.wb_sunny;
    return Icons.analytics;
  }

  void _generateAlert() {
    final tempVar = variables.firstWhere(
          (v) => v.parameter.contains('t_2m'),
      orElse: () => variables.first,
    );

    if (tempVar.maxValue > 32) {
      alertTitle = 'Alerta de Calor Extremo';
      alertMessage = 'Temperaturas podem exceder 32°C. Mantenha-se hidratado e evite exposição prolongada ao sol.';
      alertProbability = math.min((tempVar.maxValue - 32) * 10 + 50, 100);
    } else if (tempVar.minValue < 10) {
      alertTitle = 'Alerta de Frio Intenso';
      alertMessage = 'Temperaturas baixas detectadas. Use roupas adequadas e mantenha-se aquecido.';
      alertProbability = math.min((10 - tempVar.minValue) * 8 + 40, 100);
    } else {
      alertTitle = 'Condições Favoráveis';
      alertMessage = 'As condições climáticas estão dentro do esperado para esta região no período selecionado.';
      alertProbability = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;
    final maxWidth = isWeb ? 1200.0 : double.infinity;
    final horizontalPadding = isWeb ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B4F9F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4F9F),
        elevation: 0,
        centerTitle: isWeb,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: isWeb ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              widget.location.split(',').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              _buildAlertCard(),
              SizedBox(height: horizontalPadding),

              // Grid layout para web, lista para mobile
              if (isWeb && variables.isNotEmpty)
                _buildVariablesGrid()
              else
                ...variables.map((variable) => Padding(
                  padding: EdgeInsets.only(bottom: horizontalPadding),
                  child: _buildVariableCard(variable),
                )),

              SizedBox(height: horizontalPadding), // ADICIONE ESTA LINHA
              _buildMapCard(),
              SizedBox(height: horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariablesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4, // Era 1.8, agora 1.4 para mais altura
          ),
          itemCount: variables.length,
          itemBuilder: (context, index) {
            return _buildVariableCard(variables[index]);
          },
        );
      },
    );
  }

  Widget _buildAlertCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF000000), Color(0xFF1A3A52)],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.public, size: 60, color: Colors.blue.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alertMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (alertProbability > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${alertProbability.toInt()}% de probabilidade',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildVariableCard(VariableData variable) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(variable.icon, color: const Color(0xFF00D9FF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variable.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${variable.currentValue.toStringAsFixed(1)}${variable.unit}',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (variable.change != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: variable.change >= 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${variable.change >= 0 ? '+' : ''}${variable.change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: variable.change >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Mensagem para data única
          if (variable.timeSeriesData.length == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(
                  'Dados de ponto único',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Time Series Chart
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: TimeSeriesChartPainter(variable.timeSeriesData),
              child: Container(),
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Mín', variable.minValue, variable.unit),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildStatItem('Méd', variable.avgValue, variable.unit),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildStatItem('Máx', variable.maxValue, variable.unit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: widget.coordinates,
            initialZoom: 11.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'climetry',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.coordinates,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VariableData {
  final String name;
  final String parameter;
  final String unit;
  final IconData icon;
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final double change;
  final List<TimeSeriesPoint> timeSeriesData;

  VariableData({
    required this.name,
    required this.parameter,
    required this.unit,
    required this.icon,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.change,
    required this.timeSeriesData,
  });
}

class TimeSeriesPoint {
  final DateTime time;
  final double value;

  TimeSeriesPoint(this.time, this.value);
}

class TimeSeriesChartPainter extends CustomPainter {
  final List<TimeSeriesPoint> data;

  TimeSeriesChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final minValue = data.map((p) => p.value).reduce(math.min);
    final maxValue = data.map((p) => p.value).reduce(math.max);
    final range = maxValue - minValue;

    // Caso especial: apenas um ponto
    if (data.length == 1) {
      final pointPaint = Paint()
        ..color = const Color(0xFF00D9FF)
        ..style = PaintingStyle.fill;

      // Desenha ponto central
      final centerPoint = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(centerPoint, 6, pointPaint);

      // Desenha um círculo ao redor
      final circlePaint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(centerPoint, 12, circlePaint);

      return;
    }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      // Adiciona verificação para range zero
      final normalizedValue = range > 0 ? (data[i].value - minValue) / range : 0.5;
      final y = size.height * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    // Draw filled area
    // if (points.length > 1) {
    //   final fillPath = Path();
    //   fillPath.moveTo(points[0].dx, size.height);
    //   fillPath.lineTo(points[0].dx, points[0].dy);
    //
    //   for (int i = 1; i < points.length; i++) {
    //     fillPath.lineTo(points[i].dx, points[i].dy);
    //   }
    //
    //   fillPath.lineTo(points.last.dx, size.height);
    //   fillPath.close();
    //   canvas.drawPath(fillPath, fillPaint);
    // }
    //
    // // Draw line
    // if (points.length > 1) {
    //   final linePath = Path();
    //   linePath.moveTo(points[0].dx, points[0].dy);
    //
    //   for (int i = 1; i < points.length; i++) {
    //     linePath.lineTo(points[i].dx, points[i].dy);
    //   }
    //
    //   canvas.drawPath(linePath, paint);
    // }

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}