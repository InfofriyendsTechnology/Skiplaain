import 'api_service.dart';

/// NEW API-based Salon/Partner Service (uses /salons endpoints)
class ApiSalonService {
  final ApiService _api = ApiService();

  /// Get all approved salons (customer-safe endpoint)
  Future<List<Map<String, dynamic>>> getAllSalons({String? city, String? search}) async {
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (city != null && city.isNotEmpty) params.add('city=$city');
    
    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final result = await _api.get('/salons$queryString');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Get salon by ID (customer-safe endpoint)
  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    final result = await _api.get('/salons/$salonId');

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }

    return null;
  }

  /// Search salons using backend API (optimized)
  Future<List<Map<String, dynamic>>> searchSalons(String query, {String? city}) async {
    return getAllSalons(search: query, city: city);
  }

  /// Get salon services (already included in salon details)
  Future<List<Map<String, dynamic>>> getSalonServices(String salonId) async {
    final salon = await getSalonById(salonId);
    
    if (salon != null && salon['services'] != null) {
      return List<Map<String, dynamic>>.from(salon['services']);
    }

    return [];
  }

  /// Get salon barbers (already included in salon details)
  Future<List<Map<String, dynamic>>> getSalonBarbers(String salonId) async {
    final salon = await getSalonById(salonId);
    
    if (salon != null && salon['barbers'] != null) {
      return List<Map<String, dynamic>>.from(salon['barbers']);
    }

    return [];
  }
}
