import 'api_service.dart';

/// NEW API-based Booking Service (replaces Firebase Firestore)
class ApiBookingService {
  final ApiService _api = ApiService();

  /// Create a new appointment booking
  Future<Map<String, dynamic>> createBooking({
    required String salonId,
    required String salonName,
    required String salonPhone,
    required String salonAddress,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> selectedServices,
    required double totalAmount,
    required String bookingDate,
    required String timeSlot,
    String? barberId,
    String? barberName,
    String? specialInstructions,
  }) async {
    final result = await _api.post('/bookings', {
      'salonId': salonId,
      'salonName': salonName,
      'salonPhone': salonPhone,
      'salonAddress': salonAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'selectedServices': selectedServices,
      'totalAmount': totalAmount,
      'bookingDate': bookingDate,
      'timeSlot': timeSlot,
      if (barberId != null) 'barberId': barberId,
      if (barberName != null) 'barberName': barberName,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
    });

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>;
    }

    throw Exception(result['message'] ?? 'Failed to create booking');
  }

  /// Get customer bookings by phone
  Future<List<Map<String, dynamic>>> getCustomerBookings(String phone) async {
    final result = await _api.get('/bookings/customer/$phone');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Get partner bookings
  Future<List<Map<String, dynamic>>> getPartnerBookings(String partnerId) async {
    final result = await _api.get('/bookings/partner/$partnerId');

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Update booking status (complete/cancel)
  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) async {
    final result = await _api.patch('/bookings/$bookingId/status', {
      'status': status,
      if (cancelReason != null) 'cancelReason': cancelReason,
    });

    return result;
  }

  /// Create VIP membership
  Future<Map<String, dynamic>> createMembership({
    required String salonId,
    required String salonName,
    required String customerPhone,
    required String customerName,
    required String planName,
    required int price,
    required int durationMonths,
  }) async {
    final result = await _api.post('/memberships', {
      'salonId': salonId,
      'salonName': salonName,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'planName': planName,
      'price': price,
      'durationMonths': durationMonths,
    });

    return result;
  }

  /// Get customer membership for a specific salon
  Future<Map<String, dynamic>?> getCustomerMembership({
    required String customerPhone,
    required String salonId,
  }) async {
    final result = await _api.get('/memberships/customer/$customerPhone/$salonId');

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }

    return null;
  }
}
