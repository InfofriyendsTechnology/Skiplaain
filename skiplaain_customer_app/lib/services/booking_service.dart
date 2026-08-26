import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new appointment booking in Cloud Firestore
  Future<String> createBooking({
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
    final bookingId = 'SKP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final serviceSummary = selectedServices.map((s) => s['name']).join(', ');

    final bookingData = {
      'id': bookingId,
      'bookingId': bookingId,
      'salonId': salonId,
      'salonName': salonName,
      'salonPhone': salonPhone,
      'salonAddress': salonAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'barberId': barberId ?? 'any',
      'barberName': barberName ?? 'Any Available Barber',
      'services': selectedServices,
      'service': serviceSummary,
      'totalAmount': totalAmount,
      'price': '₹${totalAmount.toStringAsFixed(0)}',
      'bookingDate': bookingDate,
      'timeSlot': timeSlot,
      'time': timeSlot,
      'specialInstructions': specialInstructions ?? '',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save to global bookings collection
    await _firestore.collection('bookings').doc(bookingId).set(bookingData);

    // Update partner stats
    try {
      await _firestore.collection('partners').doc(salonId).update({
        'totalAppointments': FieldValue.increment(1),
        'totalEarnings': FieldValue.increment(totalAmount),
      });
    } catch (_) {}

    return bookingId;
  }

  /// Save / Activate Shop VIP Membership in Cloud Firestore
  Future<Map<String, dynamic>> saveShopMembership({
    required String salonId,
    required String salonName,
    required String customerPhone,
    required String customerName,
    required String planName,
    required int price,
    required int durationMonths,
  }) async {
    final membershipId = 'VIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: durationMonths * 30));

    final membershipData = {
      'id': membershipId,
      'membershipId': membershipId,
      'salonId': salonId,
      'salonName': salonName,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'planName': planName,
      'price': price,
      'durationMonths': durationMonths,
      'status': 'active',
      'activatedAt': now.toIso8601String(),
      'expiresAt': expiryDate.toIso8601String(),
      'expiryDisplay': '${expiryDate.day} ${_getMonthName(expiryDate.month)} ${expiryDate.year}',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docKey = '${salonId}_${customerPhone.replaceAll(RegExp(r'\D'), '')}';
    await _firestore.collection('memberships').doc(docKey).set(membershipData);

    return membershipData;
  }

  /// Stream membership for a specific salon & customer
  Stream<Map<String, dynamic>?> streamSalonMembership(String salonId, String customerPhone) {
    final cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    final docKey = '${salonId}_$cleanPhone';

    return _firestore.collection('memberships').doc(docKey).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return snap.data();
      }
      return null;
    });
  }

  /// Stream all active memberships for a customer across all salons
  Stream<List<Map<String, dynamic>>> streamCustomerMemberships(String customerPhone) {
    final cleanTargetPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    return _firestore.collection('memberships').snapshots().map((snapshot) {
      final List<Map<String, dynamic>> list = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docPhone = (data['customerPhone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
        if (cleanTargetPhone.isNotEmpty && (docPhone.contains(cleanTargetPhone) || cleanTargetPhone.contains(docPhone))) {
          list.add({'id': doc.id, ...data});
        }
      }
      return list;
    });
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  /// Stream customer's bookings in real-time
  Stream<List<Map<String, dynamic>>> streamCustomerBookings(String customerPhone) {
    return _firestore
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
      final List<Map<String, dynamic>> list = [];
      final cleanTargetPhone = customerPhone.replaceAll(RegExp(r'\D'), '');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docPhone = (data['customerPhone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

        if (cleanTargetPhone.isEmpty || docPhone.contains(cleanTargetPhone) || cleanTargetPhone.contains(docPhone)) {
          list.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      list.sort((a, b) => (b['id'] ?? '').toString().compareTo((a['id'] ?? '').toString()));
      return list;
    });
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
