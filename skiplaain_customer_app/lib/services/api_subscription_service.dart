import 'api_service.dart';

/// Subscription Service — wraps /plans and /subscriptions endpoints
class ApiSubscriptionService {
  final ApiService _api = ApiService();

  static final ApiSubscriptionService _instance = ApiSubscriptionService._internal();
  factory ApiSubscriptionService() => _instance;
  ApiSubscriptionService._internal();

  /// GET /plans?salonId=:id
  /// Returns list of active plans for a salon.
  /// Returns empty list if salon has plansEnabled=false.
  Future<List<Map<String, dynamic>>> getPlansForSalon(String salonId) async {
    final result = await _api.get('/plans?salonId=$salonId');
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }
    return [];
  }

  /// GET /subscriptions/status?salonId=:id
  /// Returns { hasActivePlan, expiresAt, plansEnabled, planName }
  Future<Map<String, dynamic>> getSubscriptionStatus(String salonId) async {
    final result = await _api.get('/subscriptions/status?salonId=$salonId');
    if (result['success'] == true) {
      return Map<String, dynamic>.from(result['data'] ?? {});
    }
    return {'hasActivePlan': false, 'plansEnabled': false};
  }

  /// GET /subscriptions/my
  /// Returns all customer subscriptions (active and expired)
  Future<List<Map<String, dynamic>>> getMySubscriptions() async {
    final result = await _api.get('/subscriptions/my');
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }
    return [];
  }

  /// POST /subscriptions/order
  /// Body: { planId, partnerId }
  /// Returns { orderId, amount (paise), currency, paymentId, planDetails }
  Future<Map<String, dynamic>> createOrder({
    required String planId,
    required String partnerId,
  }) async {
    final result = await _api.post('/subscriptions/order', {
      'planId': planId,
      'partnerId': partnerId,
    });
    if (result['success'] == true) {
      return Map<String, dynamic>.from(result['data'] ?? {});
    }
    throw Exception(result['message'] ?? 'Failed to create subscription order');
  }

  /// POST /subscriptions/verify
  /// Body: { orderId, paymentId, signature }
  /// Returns { membership }
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final result = await _api.post('/subscriptions/verify', {
      'orderId': orderId,
      'paymentId': paymentId,
      'signature': signature,
    });
    if (result['success'] == true) {
      return Map<String, dynamic>.from(result['data'] ?? {});
    }
    throw Exception(result['message'] ?? 'Payment verification failed');
  }
}

