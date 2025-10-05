import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/location_autocomplete_field.dart';
import '../../../../core/services/location_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng initialLocation;
  final String initialLocationName;

  const LocationPickerWidget({
    super.key,
    required this.initialLocation,
    required this.initialLocationName,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late LatLng _selectedLocation;
  late TextEditingController _nameController;
  late TextEditingController _searchController;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoadingAddress = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _nameController = TextEditingController(text: widget.initialLocationName);
    _searchController = TextEditingController();
    _updateMarker();
    
    // Se não tiver nome inicial, buscar endereço
    if (widget.initialLocationName.isEmpty) {
      _getAddressFromCoordinates(_selectedLocation);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    
    try {
      // Usar LocationService para obter apenas o nome da cidade principal
      final cityName = await _locationService.getCityName(
        location.latitude,
        location.longitude,
      );
      
      if (mounted) {
        setState(() {
          _nameController.text = cityName;
        });
        
        // Mostrar snackbar de confirmação
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Localização: $cityName'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF2A3A4D),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar endereço: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Não foi possível buscar o endereço automaticamente'),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF2A3A4D),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  void _updateMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarker();
    });
    _getAddressFromCoordinates(position);
  }

  void _confirm() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'name': _nameController.text.isEmpty ? 'Local Selecionado' : _nameController.text,
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _centerOnLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 13.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        title: const Text('Selecionar Localização'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _confirm,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A3A4D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buscar Localização',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LocationAutocompleteField(
                  controller: _searchController,
                  hintText: 'Digite: Monte Carmelo, Monte Carlo...',
                  prefixIcon: Icons.search,
                  onLocationSelected: (suggestion) {
                    setState(() {
                      _selectedLocation = suggestion.coordinates;
                      _nameController.text = suggestion.displayName;
                      _searchController.clear();
                      _updateMarker();
                    });
                    
                    // Mover o mapa para a nova localização
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedLocation, 13.0),
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Localização encontrada: ${suggestion.displayName}'),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF1E2A3A),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF1E2A3A),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nome do Local (Opcional)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ex: Minha Casa, Escritório...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1E2A3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _isLoadingAddress
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9EFF)),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF4A9EFF), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 13.0,
                  ),
                  onTap: _onMapTap,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_in_button',
                        backgroundColor: const Color(0xFF2A3A4D),
                        onPressed: _zoomIn,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_out_button',
                        backgroundColor: const Color(0xFF2A3A4D),
                        onPressed: _zoomOut,
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'center_location_button',
                        backgroundColor: const Color(0xFF4A9EFF),
                        onPressed: _centerOnLocation,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3A4D).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app, color: Color(0xFF4A9EFF), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Busque acima ou toque no mapa para selecionar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A3A4D),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9EFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirmar Localização',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
