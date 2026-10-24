import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../services/mapbox_service.dart';

/// Placeholder location picker — mapbox_gl removed due to Flutter 3.24 incompatibility.
/// Uses geolocator + Mapbox REST API for address resolution instead of the map widget.
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
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  double? _selectedLat;
  double? _selectedLng;
  String _addressText = 'Tap to select location';

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    try {
      _mapboxService.init(dotenv.env['MAPBOX_API_KEY'] ?? '');
    } catch (_) {
      // Mapbox key not configured — search will still work without it
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _selectedLat = pos.latitude;
      _selectedLng = pos.longitude;

      final result = await _mapboxService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _addressText = result?['place_name'] ?? '${pos.latitude}, ${pos.longitude}';
        });
        widget.onLocationSelected({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'address': _addressText,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _mapboxService.searchPlaces(query.trim());
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectResult(Map<String, dynamic> result) {
    final center = result['center'] as List?;
    if (center != null && center.length >= 2) {
      _selectedLng = (center[0] as num).toDouble();
      _selectedLat = (center[1] as num).toDouble();
    }
    setState(() {
      _addressText = result['place_name'] ?? 'Selected location';
      _searchResults = [];
      _searchController.clear();
    });
    widget.onLocationSelected({
      'latitude': _selectedLat,
      'longitude': _selectedLng,
      'address': _addressText,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Select Location', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for an address...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF00))),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF262626)),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final r = _searchResults[i];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Color(0xFF00FF00), size: 20),
                      title: Text(
                        (r['place_name'] ?? '').toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      onTap: () => _selectResult(r),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_searching, color: const Color(0xFF00FF00).withValues(alpha: 0.5), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _addressText,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location, color: Colors.black),
                      label: const Text('Use my current location', style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
