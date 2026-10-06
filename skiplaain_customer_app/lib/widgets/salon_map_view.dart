import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../services/mapbox_service.dart';

class SalonMapView extends StatefulWidget {
  final List<Map<String, dynamic>> salons;
  final Function(Map<String, dynamic> salon)? onSalonTap;

  const SalonMapView({
    super.key,
    required this.salons,
    this.onSalonTap,
  });

  @override
  State<SalonMapView> createState() => _SalonMapViewState();
}

class _SalonMapViewState extends State<SalonMapView> {
  final MapboxService _mapboxService = MapboxService();
  MapboxMapController? _mapController;
  final Map<String, Symbol> _salonMarkers = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addSalonMarkers() async {
    if (_mapController == null) return;

    // Clear existing markers
    for (var symbol in _salonMarkers.values) {
      await _mapController!.removeSymbol(symbol);
    }
    _salonMarkers.clear();

    // Add new markers
    for (var salon in widget.salons) {
      final lat = salon['latitude'] as double?;
      final lng = salon['longitude'] as double?;
      
      if (lat != null && lng != null) {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(lat, lng),
            iconImage: 'marker-15',
            iconSize: 2.0,
            textField: salon['salonName'] ?? 'Salon',
            textSize: 12,
            textOffset: const Offset(0, 2),
            textColor: '#00FF00',
          ),
        );
        _salonMarkers[salon['id']] = symbol;
      }
    }

    // Fit bounds to show all salons
    if (widget.salons.isNotEmpty && widget.salons.length > 1) {
      _fitBoundsToSalons();
    }
  }

  void _fitBoundsToSalons() {
    if (_mapController == null || widget.salons.isEmpty) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (var salon in widget.salons) {
      final lat = salon['latitude'] as double?;
      final lng = salon['longitude'] as double?;
      
      if (lat != null && lng != null) {
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 50, top: 50, right: 50, bottom: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultCenter = widget.salons.isNotEmpty && 
                          widget.salons.first['latitude'] != null
        ? LatLng(
            widget.salons.first['latitude'] as double,
            widget.salons.first['longitude'] as double,
          )
        : const LatLng(19.0760, 72.8777); // Mumbai

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MapboxMap(
          accessToken: _mapboxService.apiKey ?? '',
          initialCameraPosition: CameraPosition(
            target: defaultCenter,
            zoom: 12,
          ),
          onMapCreated: (controller) async {
            _mapController = controller;
            await _addSalonMarkers();
          },
          onStyleLoadedCallback: () {
            _addSalonMarkers();
          },
          styleString: 'mapbox://styles/mapbox/dark-v11',
          myLocationEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
