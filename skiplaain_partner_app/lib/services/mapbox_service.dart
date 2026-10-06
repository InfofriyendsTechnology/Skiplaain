import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MapboxService {
  static final MapboxService _instance = MapboxService._internal();
  factory MapboxService() => _instance;
  MapboxService._internal();

  String? _apiKey;
  final Map<String, dynamic> _cache = {};
  static const String _baseUrl = 'https://api.mapbox.com';

  // India bounds
  static const double minLat = 8.4;
  static const double maxLat = 35.5;
  static const double minLng = 68.7;
  static const double maxLng = 97.4;
  static const defaultCenter = {'lat': 19.0760, 'lng': 72.8777}; // Mumbai

  void init(String apiKey) {
    _apiKey = apiKey;
  }

  String? get apiKey => _apiKey;

  /// Geocoding: Address → Coordinates
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    if (_apiKey == null) throw Exception('Mapbox API key not initialized');
    
    final cacheKey = 'geocode_$address';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
        '$_baseUrl/geocoding/v5/mapbox.places/$encoded.json'
        '?access_token=$_apiKey'
        '&country=IN'
        '&limit=1'
        '&bbox=$minLng,$minLat,$maxLng,$maxLat'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final feature = data['features'][0];
          final result = {
            'latitude': feature['center'][1],
            'longitude': feature['center'][0],
            'placeName': feature['place_name'],
            'address': feature['place_name'],
          };
          _cache[cacheKey] = result;
          return result;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Mapbox geocoding error: $e');
      return null;
    }
  }

  /// Reverse Geocoding: Coordinates → Address
  Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude) async {
    if (_apiKey == null) throw Exception('Mapbox API key not initialized');

    final cacheKey = 'reverse_${latitude}_$longitude';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json'
        '?access_token=$_apiKey'
        '&country=IN'
        '&limit=1'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final feature = data['features'][0];
          final result = {
            'latitude': latitude,
            'longitude': longitude,
            'placeName': feature['place_name'],
            'address': feature['place_name'],
            'text': feature['text'],
          };
          _cache[cacheKey] = result;
          return result;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Mapbox reverse geocoding error: $e');
      return null;
    }
  }

  /// Autocomplete Search
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (_apiKey == null) throw Exception('Mapbox API key not initialized');
    if (query.length < 3) return [];

    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$_baseUrl/geocoding/v5/mapbox.places/$encoded.json'
        '?access_token=$_apiKey'
        '&country=IN'
        '&limit=5'
        '&bbox=$minLng,$minLat,$maxLng,$maxLat'
        '&types=address,place,locality,neighborhood'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List? ?? [];
        
        return features.map((feature) => {
          'placeName': feature['place_name'],
          'text': feature['text'],
          'latitude': feature['center'][1],
          'longitude': feature['center'][0],
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Mapbox search error: $e');
      return [];
    }
  }

  /// Get Static Map Image URL
  String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int width = 600,
    int height = 400,
    int zoom = 15,
  }) {
    if (_apiKey == null) return '';
    
    return '$_baseUrl/styles/v1/mapbox/streets-v12/static/'
        'pin-s+00ff00($longitude,$latitude)/'
        '$longitude,$latitude,$zoom,0/$width'
        'x$height'
        '?access_token=$_apiKey';
  }

  void clearCache() {
    _cache.clear();
  }
}
