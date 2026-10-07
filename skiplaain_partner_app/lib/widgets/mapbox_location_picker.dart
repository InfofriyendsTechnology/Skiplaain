import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../services/mapbox_service.dart';

class MapboxLocationPicker extends StatefulWidget {
  final Function(Map<String, dynamic> location) onLocationSelected;
  final double? initialLat;
  final double? initialLng;

  const MapboxLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapboxLocationPicker> createState() => _MapboxLocationPickerState();
}

class _MapboxLocationPickerState extends State<MapboxLocationPicker> {
  final MapboxService _mapboxService = MapboxService();
  final TextEditingController _searchController = TextEditingController();
  
  MapboxMapController? _mapController;
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Default Mumbai
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // High accuracy location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      // Zoom to 17 for better street-level view
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 17),
      );
      _updateAddress(_currentPosition.latitude, _currentPosition.longitude);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Location error: $e');
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    final result = await _mapboxService.reverseGeocode(lat, lng);
    if (result != null) {
      setState(() {
        _selectedAddress = result['address'] ?? '';
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await _mapboxService.searchPlaces(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _onSearchResultTap(Map<String, dynamic> result) {
    final lat = result['latitude'] as double;
    final lng = result['longitude'] as double;
    
    setState(() {
      _currentPosition = LatLng(lat, lng);
      _selectedAddress = result['placeName'];
      _searchResults = [];
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 17),
    );
  }

  void _onMapTap(LatLng position) {
    setState(() => _currentPosition = position);
    _updateAddress(position.latitude, position.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  void _confirmLocation() {
    widget.onLocationSelected({
      'latitude': _currentPosition.latitude,
      'longitude': _currentPosition.longitude,
      'address': _selectedAddress,
    });
    Navigator.pop(context, {
      'latitude': _currentPosition.latitude,
      'longitude': _currentPosition.longitude,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Mapbox Map with all features enabled
          MapboxMap(
            accessToken: _mapboxService.apiKey ?? '',
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) async {
              _mapController = controller;
              // Enable all map features for production-quality rendering
              await controller.setSymbolIconAllowOverlap(true);
              await controller.setSymbolTextAllowOverlap(false);
            },
            onMapClick: (point, latLng) => _onMapTap(latLng),
            styleString: 'mapbox://styles/mapbox/streets-v12',
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.None,
            myLocationRenderMode: MyLocationRenderMode.NORMAL,
          ),

          // Center Pin
          Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: const Color(0xFF00FF00),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search location in India...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF00)),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00FF00),
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                
                // Search Results
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF00FF00)),
                          title: Text(
                            result['text'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            result['placeName'],
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () => _onSearchResultTap(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: const Color(0xFF00FF00),
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // Bottom Sheet - Address Display & Confirm
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: Color(0xFF00FF00), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress.isNotEmpty ? _selectedAddress : 'Move map to select',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
