import 'api_service.dart';

/// Customer profile service
class ApiCustomerService {
  final ApiService _api = ApiService();

  static final ApiCustomerService _instance = ApiCustomerService._internal();
  factory ApiCustomerService() => _instance;
  ApiCustomerService._internal();

  /// GET /customers/me - Get current customer profile
  Future<Map<String, dynamic>> getMe() async {
    final result = await _api.get('/customers/me');
    if (result['success'] == true) {
      return Map<String, dynamic>.from(result['data'] ?? {});
    }
    throw Exception(result['message'] ?? 'Failed to fetch profile');
  }

  /// PUT /customers/me - Update customer profile
  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final result = await _api.put('/customers/me', body);
    if (result['success'] == true) {
      return Map<String, dynamic>.from(result['data'] ?? {});
    }
    throw Exception(result['message'] ?? 'Failed to update profile');
  }
}
