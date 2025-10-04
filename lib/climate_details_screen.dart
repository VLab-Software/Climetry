import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../state/climate_details_view_model.dart';
import '../../domain/entities/variable_data.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/alert_info.dart';
import '../../../climate/domain/entities/weather_payload.dart';

class ClimateDetailsScreen extends StatelessWidget {
  final String location;
  final String date;
  final LatLng coordinates;
  final WeatherPayload weatherPayload;

  const ClimateDetailsScreen({super.key, required this.location, required this.date, required this.coordinates, required this.weatherPayload});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClimateDetailsViewModel(location: location, date: date, coordinates: coordinates, payload: weatherPayload),
      child: const _DetailsScaffold(),
    );
  }
}

class _DetailsScaffold extends StatelessWidget {
  const _DetailsScaffold();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClimateDetailsViewModel>();
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
              vm.location.split(',').first,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(vm.date, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
      body: !vm.ready
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              _AlertCard(alert: vm.alert),
              SizedBox(height: horizontalPadding),
              if (isWeb && vm.variables.isNotEmpty) _VariablesGrid(vars: vm.variables) else ...vm.variables.map((v) => Padding(padding: EdgeInsets.only(bottom: horizontalPadding), child: _VariableCard(v: v))),
              SizedBox(height: horizontalPadding),
              _MapCard(coords: vm.coordinates),
              SizedBox(height: horizontalPadding),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariablesGrid extends StatelessWidget {
  final List<VariableData> vars;
  const _VariablesGrid({required this.vars});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth > 900 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.4),
        itemCount: vars.length,
        itemBuilder: (_, i) => _VariableCard(v: vars[i]),
      );
    });
  }
}

class _AlertCard extends StatelessWidget {
  final AlertInfo alert;
  const _AlertCard({required this.alert});
  @override
  Widget build(BuildContext context) {
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
              child: Center(
                child: Icon(Icons.public, size: 60, color: Colors.blue.withOpacity(0.3)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (alert.probability > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${alert.probability.toInt()}% de probabilidade',
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
}

class _VariableCard extends StatelessWidget {
  final VariableData v;
  const _VariableCard({required this.v});
  @override
  Widget build(BuildContext context) {
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
                child: Icon(v.icon, color: const Color(0xFF00D9FF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${v.currentValue.toStringAsFixed(1)}${v.unit}',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (v.change != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: v.change >= 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${v.change >= 0 ? '+' : ''}${v.change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: v.change >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Mensagem para data única
          if (v.timeSeriesData.length == 1)
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
              painter: _TimeSeriesChartPainter(v.timeSeriesData),
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('Mín', v.minValue, v.unit),
              Container(width: 1, height: 30, color: Colors.white24),
              _stat('Méd', v.avgValue, v.unit),
              Container(width: 1, height: 30, color: Colors.white24),
              _stat('Máx', v.maxValue, v.unit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, String unit) => Column(
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

class _MapCard extends StatelessWidget {
  final LatLng coords;
  const _MapCard({required this.coords});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: coords,
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
                  point: coords,
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

class _TimeSeriesChartPainter extends CustomPainter {
  final List<TimeSeriesPoint> data;
  _TimeSeriesChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final dotPaint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..style = PaintingStyle.fill;

    // min/max
    double min = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double max = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final range = (max - min);

    if (data.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, 6, dotPaint);
      final ring = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, 12, ring);
      return;
    }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final norm = range > 0 ? (data[i].value - min) / range : 0.5;
      final y = size.height * (1 - norm);
      points.add(Offset(x, y));
    }

    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}