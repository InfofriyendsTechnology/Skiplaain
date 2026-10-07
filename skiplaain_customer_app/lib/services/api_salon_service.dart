import 'api_service.dart';

/// NEW API-based Salon/Partner Service (replaces Firebase Firestore)
class ApiSalonService {
  final ApiService _api = ApiService();

  /// Get all approved salons/partners
  Future<List<Map<String, dynamic>>> getAllSalons() async {
    final result = await _api.get('/partners?status=approved');

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

  /// Search salons (client-side filtering for now)
  Future<List<Map<String, dynamic>>> searchSalons(String query) async {
    final allSalons = await getAllSalons();
    
    if (query.isEmpty) return allSalons;

    final lowerQuery = query.toLowerCase();
    return allSalons.where((salon) {
      final name = (salon['salonName'] ?? '').toString().toLowerCase();
      final address = (salon['address'] ?? '').toString().toLowerCase();
      final city = (salon['city'] ?? '').toString().toLowerCase();
      
      return name.contains(lowerQuery) ||
             address.contains(lowerQuery) ||
             city.contains(lowerQuery);
    }).toList();
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
