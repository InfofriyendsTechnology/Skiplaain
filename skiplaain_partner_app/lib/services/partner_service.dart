import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid {
    return _auth.currentUser?.uid ?? 'partner_${DateTime.now().millisecondsSinceEpoch}';
  }

  String get currentPhone {
    return _auth.currentUser?.phoneNumber ?? '+918553535342';
  }

  /// Save or update full partner profile during Onboarding
  Future<void> savePartnerProfile({
    String? uid,
    required String salonName,
    required String address,
    required String category,
    required String phoneNumber,
    required String openingTime,
    required String closingTime,
    required String weeklyOff,
    required List<Map<String, dynamic>> services,
    String status = 'active',
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final targetUid = uid ?? _auth.currentUser?.uid ?? 'partner_${cleanPhone.isEmpty ? "test_salon" : cleanPhone}';

    final partnerData = {
      'id': targetUid,
      'salonName': salonName,
      'businessName': salonName,
      'ownerName': 'Partner Owner',
      'phone': phoneNumber,
      'category': category,
      'address': address,
      'location': address,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'weeklyOff': weeklyOff,
      'services': services,
      'status': status,
      'rating': 5.0,
      'reviewCount': 0,
      'totalEarnings': 0,
      'totalAppointments': 0,
      'isOnboarded': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('partners').doc(targetUid).set(partnerData, SetOptions(merge: true));
  }

  /// Get single partner details
  Future<DocumentSnapshot<Map<String, dynamic>>> getPartnerProfile(String uid) async {
    return await _firestore.collection('partners').doc(uid).get();
  }

  /// Listen to partner details in real-time
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPartnerProfile(String uid) {
    return _firestore.collection('partners').doc(uid).snapshots();
  }
}
