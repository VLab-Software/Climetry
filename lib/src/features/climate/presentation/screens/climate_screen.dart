// ==============================
// 📁 lib/src/features/climate/presentation/screens/climate_screen.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../state/climate_view_model.dart'; // presentation/state
import '../widgets/location_field.dart';
import '../widgets/timeframe_selector.dart';
import '../widgets/variable_selector.dart';
import 'climate_details_screen.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  static const double kDesktop = 1100;
  static const double kMaxWidth = 1200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earth Data Analysis'), centerTitle: true),
      body: const SafeArea(child: _ResponsiveBody()),
    );
  }
}

class _ResponsiveBody extends StatelessWidget {
  const _ResponsiveBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ClimateScreen.kDesktop;
        return Scrollbar(
          thumbVisibility: true,
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ClimateScreen.kMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isDesktop ? const _DesktopLayout() : const _StackedLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClimateViewModel>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna esquerda: localização + data + botão
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(context, 'Location', LocationField(vm: vm)),
              const SizedBox(height: 16),
              _section(context, 'Date', TimeframeSelector(vm: vm)),
              const SizedBox(height: 24),
              _analysisButton(context, vm, alignedLeft: true),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Coluna direita: variáveis + mapa
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                context,
                'Variables (${vm.selectedCount}/${vm.maxVariables})',
                VariableSelector(vm: vm),
              ),
              const SizedBox(height: 16),
              _section(context, 'Map', _Map(vm: vm)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClimateViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(context, 'Location', LocationField(vm: vm)),
        const SizedBox(height: 16),
        _section(context, 'Date', TimeframeSelector(vm: vm)),
        const SizedBox(height: 16),
        _section(
          context,
          'Variables (${vm.selectedCount}/${vm.maxVariables})',
          VariableSelector(vm: vm),
        ),
        const SizedBox(height: 16),
        _section(context, 'Map', _Map(vm: vm)),
        const SizedBox(height: 24),
        _analysisButton(context, vm),
      ],
    );
  }
}

Widget _section(BuildContext context, String title, Widget child) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _analysisButton(BuildContext context, ClimateViewModel vm, {bool alignedLeft = false}) {
  final btn = ElevatedButton.icon(
    icon: const Icon(Icons.analytics),
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    onPressed: vm.isLoading
        ? null
        : () async {
      try {
        final payload = await vm.generateAnalysis();
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClimateDetailsScreen(
              location: vm.locationController.text,
              date: vm.userFriendlyDateRange,
              coordinates: vm.currentLocation,
              // 👇 sua tela atual espera `weatherData: Map<String,dynamic>`
              weatherData: payload.raw,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    },
    label: vm.isLoading
        ? const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
      ),
    )
        : const Text('Analyze'),
  );

  return alignedLeft ? Align(alignment: Alignment.centerLeft, child: btn) : Center(child: btn);
}

class _Map extends StatelessWidget {
  final ClimateViewModel vm;
  const _Map({required this.vm});

  double _heightForWidth(double w) {
    if (w >= 1100) return 420;
    if (w >= 768) return 320;
    return 220;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = _heightForWidth(w);

    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: vm.currentLocation,
            initialZoom: 5.0,
            onTap: (tapPosition, point) {
              vm.currentLocation = point;
              vm.notifyListeners();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: vm.currentLocation,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
