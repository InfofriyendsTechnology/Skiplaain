import 'dart:async';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  /// Get all bookings for a partner
  Future<List<Map<String, dynamic>>> getPartnerBookings(String partnerId) async {
    try {
      final response = await _api.get('/bookings/partner/$partnerId');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching partner bookings: $e');
      return [];
    }
  }

  /// Stream partner bookings with polling (30s interval)
  /// Returns a stream that polls the API periodically
  Stream<List<Map<String, dynamic>>> streamPartnerBookings(String partnerId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? timer;

    Future<void> fetchAndEmit() async {
      try {
        final bookings = await getPartnerBookings(partnerId);
        if (!controller.isClosed) {
          controller.add(bookings);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Fetch immediately
    fetchAndEmit();

    // Then poll every 30 seconds
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchAndEmit();
    });

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  /// Get booking by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final response = await _api.get('/bookings/$bookingId');
      
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching booking: $e');
      return null;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(
    String bookingId, {
    String? cancelledBy,
    String? reason,
  }) async {
    try {
      final response = await _api.patch('/bookings/$bookingId/status', {
        'status': 'cancelled',
        'cancelReason': reason ?? '',
      });
      
      return response['success'] == true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  /// Complete booking (partner only)
  Future<bool> completeBooking(String bookingId) async {
    try {
      final response = await _api.patch('/bookings/$bookingId/status', {
        'status': 'completed',
      });
      
      return response['success'] == true;
    } catch (e) {
      print('Error completing booking: $e');
      return false;
    }
  }

  /// Update booking status
  Future<bool> updateBookingStatus(
    String bookingId, 
    String status, {
    String? reason,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
      };
      
      if (reason != null) {
        payload['cancelReason'] = reason;
      }

      final response = await _api.patch('/bookings/$bookingId/status', payload);
      
      return response['success'] == true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  /// Get memberships for a partner
  Future<List<Map<String, dynamic>>> getPartnerMemberships(String partnerId) async {
    try {
      final response = await _api.get('/memberships?partnerId=$partnerId');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching memberships: $e');
      return [];
    }
  }

  /// Get customers who have booked with this partner
  Future<List<Map<String, dynamic>>> getPartnerCustomers(String partnerId) async {
    try {
      // Get all bookings for this partner
      final bookings = await getPartnerBookings(partnerId);
      
      // Extract unique customers
      final Map<String, Map<String, dynamic>> uniqueCustomers = {};
      
      for (var booking in bookings) {
        final phone = booking['customerPhone'] as String?;
        if (phone != null && !uniqueCustomers.containsKey(phone)) {
          uniqueCustomers[phone] = {
            'phone': phone,
            'name': booking['customerName'] ?? 'Customer',
            'lastVisit': booking['bookingDate'] ?? '',
            'totalBookings': 1,
          };
        } else if (phone != null) {
          uniqueCustomers[phone]!['totalBookings'] = 
            (uniqueCustomers[phone]!['totalBookings'] as int) + 1;
        }
      }
      
      return uniqueCustomers.values.toList();
    } catch (e) {
      print('Error fetching partner customers: $e');
      return [];
    }
  }
}
