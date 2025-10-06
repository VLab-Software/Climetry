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
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _nameController = TextEditingController(text: widget.initialLocationName);
    _searchController = TextEditingController();
    _updateMarker();

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
      final cityName = await _locationService.getCityName(
        location.latitude,
        location.longitude,
      );

      if (mounted) {
        setState(() {
          _nameController.text = cityName;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching endereço: $e');
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

  void _onCameraMove(CameraPosition position) {
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
    }
    
    setState(() {
      _selectedLocation = position.target;
      _updateMarker();
    });
  }

  void _onCameraIdle() {
    if (_isMapMoving) {
      setState(() => _isMapMoving = false);
      _getAddressFromCoordinates(_selectedLocation);
    }
  }

  void _confirm() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'name': _nameController.text.isEmpty
          ? 'Local Selecionado'
          : _nameController.text,
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
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final inputBackgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.withOpacity(0.1);
    final accentColor = Colors.blue[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false, // Impede que o layout suba com o teclado
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text('Selecionar Location', style: TextStyle(color: textColor)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16, // Menos padding quando teclado aberto
            ),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Search Location',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LocationAutocompleteField(
                  controller: _searchController,
                  hintText: 'Digite: São Paulo, Monte Carlo...',
                  prefixIcon: Icons.search,
                  onLocationSelected: (suggestion) {
                    setState(() {
                      _selectedLocation = suggestion.coordinates;
                      _nameController.text = suggestion.displayName;
                      _searchController.clear();
                      _updateMarker();
                    });

                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedLocation, 13.0),
                    );

                    FocusScope.of(context).unfocus();
                  },
                  backgroundColor: inputBackgroundColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nome do Local',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Ex: São Paulo, SP',
                    hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                    filled: true,
                    fillColor: inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _isLoadingAddress
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                          )
                        : null,
                  ),
                  onTap: () {
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inputBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (_isMapMoving)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildMapControlButton(
                        icon: Icons.add,
                        onPressed: _zoomIn,
                        isDark: isDark,
                        heroTag: 'zoom_in',
                      ),
                      const SizedBox(height: 8),
                      _buildMapControlButton(
                        icon: Icons.remove,
                        onPressed: _zoomOut,
                        isDark: isDark,
                        heroTag: 'zoom_out',
                      ),
                      const SizedBox(height: 8),
                      _buildMapControlButton(
                        icon: Icons.my_location,
                        onPressed: _centerOnLocation,
                        isDark: isDark,
                        heroTag: 'center',
                        isAccent: true,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Arraste o mapa ou toque para selecionar',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required String heroTag,
    bool isAccent = false,
  }) {
    final bgColor = isAccent
        ? Colors.blue[700]!
        : (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    
    return FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: bgColor,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: isAccent ? Colors.white : (isDark ? Colors.white : Colors.black87),
        size: 20,
      ),
    );
  }
}
