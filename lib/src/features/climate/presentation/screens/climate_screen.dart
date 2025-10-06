import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../state/climate_view_model.dart';
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
      appBar: AppBar(
        title: const Text('Earth Data Analysis'),
        centerTitle: true,
      ),
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
                constraints: const BoxConstraints(
                  maxWidth: ClimateScreen.kMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isDesktop
                      ? const _DesktopLayout()
                      : const _StackedLayout(),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Selector<ClimateViewModel, bool>(
          selector: (_, m) => m.locationMenuOpen,
          builder: (_, menuOpen, __) {
            return AbsorbPointer(
              absorbing: menuOpen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 120),
                        const SizedBox(height: 16),
                        _section(context, 'Date', TimeframeSelector(vm: vm)),
                        const SizedBox(height: 24),
                        _analysisButton(context, vm, alignedLeft: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        _section(
                          context,
                          'Map',
                          AbsorbPointer(
                            absorbing: menuOpen,
                            child: _Map(vm: vm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: MediaQuery.of(context).size.width >= ClimateScreen.kDesktop
              ? MediaQuery.of(context).size.width * 0.58
              : 0,
          child: IgnorePointer(
            ignoring: false, // Permite cliques no LocationField
            child: _locationSection(context, vm),
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

    return Stack(
      clipBehavior: Clip.none, // Importante!
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120), // Espaço para Location card
          child: Selector<ClimateViewModel, bool>(
            selector: (_, m) => m.locationMenuOpen,
            builder: (_, menuOpen, __) {
              return AbsorbPointer(
                absorbing:
                    menuOpen, // 🔒 congela tudo atrás enquanto o menu está aberto
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(context, 'Date', TimeframeSelector(vm: vm)),
                    const SizedBox(height: 16),
                    _section(
                      context,
                      'Variables (${vm.selectedCount}/${vm.maxVariables})',
                      VariableSelector(vm: vm),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      context,
                      'Map',
                      AbsorbPointer(
                        absorbing: menuOpen, // 🔒 evita toques no mapa
                        child: _Map(vm: vm),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _analysisButton(context, vm),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _locationSection(context, vm), // Seção especial com overflow
        ),
      ],
    );
  }
}

Widget _locationSection(BuildContext context, ClimateViewModel vm) {
  return Material(
    color: Colors.transparent,
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Location',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LocationField(vm: vm),
        ],
      ),
    ),
  );
}

Widget _section(
  BuildContext context,
  String title,
  Widget child, {
  bool allowOverflow = false, // Novo parâmetro
}) {
  return Container(
    clipBehavior: allowOverflow
        ? Clip.none
        : Clip.hardEdge, // Controla o overflow
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _analysisButton(
  BuildContext context,
  ClimateViewModel vm, {
  bool alignedLeft = false,
}) {
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
                    weatherData: payload.raw,
                  ),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
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

  return alignedLeft
      ? Align(alignment: Alignment.centerLeft, child: btn)
      : Center(child: btn);
}

class _Map extends StatefulWidget {
  final ClimateViewModel vm;
  const _Map({required this.vm});

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarker();
  }

  @override
  void didUpdateWidget(_Map oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.currentLocation != widget.vm.currentLocation) {
      _updateMarker();
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: widget.vm.currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _onMapTap(LatLng position) {
    widget.vm.currentLocation = position;
    _updateMarker();
  }

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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.vm.currentLocation,
            zoom: 5.0,
          ),
          onTap: _onMapTap,
          markers: _markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
      ),
    );
  }
}
