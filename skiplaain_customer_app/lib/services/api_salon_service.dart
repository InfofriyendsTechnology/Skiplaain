import 'api_service.dart';

/// NEW API-based Salon/Partner Service (replaces Firebase Firestore)
class ApiSalonService {
  final ApiService _api = ApiService();

  /// Get all salons/partners (no status filter for search)
  Future<List<Map<String, dynamic>>> getAllSalons() async {
    final result = await _api.get('/partners');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Get salon by ID
  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    final result = await _api.get('/partners/$salonId');

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }

    return null;
  }

  /// Search salons using backend API (optimized)
  Future<List<Map<String, dynamic>>> searchSalons(String query, {String? city}) async {
    if (query.isEmpty && city == null) {
      return await getAllSalons();
    }

    // Build query params
    final params = <String>[];
    if (query.isNotEmpty) params.add('search=$query');
    if (city != null && city.isNotEmpty) params.add('city=$city');
    
    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final result = await _api.get('/partners$queryString');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Get salon services
  Future<List<Map<String, dynamic>>> getSalonServices(String salonId) async {
    final salon = await getSalonById(salonId);
    
    if (salon != null && salon['services'] != null) {
      return List<Map<String, dynamic>>.from(salon['services']);
    }

    return [];
  }

  /// Get salon barbers
  Future<List<Map<String, dynamic>>> getSalonBarbers(String salonId) async {
    final salon = await getSalonById(salonId);
    
    if (salon != null && salon['barbers'] != null) {
      return List<Map<String, dynamic>>.from(salon['barbers']);
    }

    return [];
  }
}
