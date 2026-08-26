import 'package:cloud_firestore/cloud_firestore.dart';

class SalonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all active salons from Firestore
  Stream<List<Map<String, dynamic>>> streamSalons({String? category, String? searchKeyword}) {
    return _firestore.collection('partners').snapshots().map((snapshot) {
      final List<Map<String, dynamic>> salons = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'active').toString().toLowerCase();

        // Skip blocked salons
        if (status == 'blocked') continue;

        final salonCategory = (data['category'] ?? 'Unisex').toString();
        final salonName = (data['salonName'] ?? data['businessName'] ?? 'Salon').toString();
        final address = (data['address'] ?? data['location'] ?? '').toString();

        // Category filter
        if (category != null && category != 'All') {
          if (!salonCategory.toLowerCase().contains(category.toLowerCase())) {
            continue;
          }
        }

        // Search filter
        if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
          final query = searchKeyword.toLowerCase();
          final nameMatch = salonName.toLowerCase().contains(query);
          final addressMatch = address.toLowerCase().contains(query);
          final categoryMatch = salonCategory.toLowerCase().contains(query);

          if (!nameMatch && !addressMatch && !categoryMatch) {
            continue;
          }
        }

        salons.add({
          'id': doc.id,
          ...data,
        });
      }

      return salons;
    });
  }

  /// Get single salon by id
  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    final doc = await _firestore.collection('partners').doc(salonId).get();
    if (!doc.exists) return null;
    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }
}
