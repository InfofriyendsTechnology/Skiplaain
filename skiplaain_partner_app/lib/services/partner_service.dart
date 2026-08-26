import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartnerService {
  static final PartnerService _instance = PartnerService._internal();
  factory PartnerService() => _instance;
  PartnerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _cachedPhone;
  String? _cachedPartnerId;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  String get currentPhone => _cachedPhone ?? _auth.currentUser?.phoneNumber ?? '';
  String get currentUid {
    if (_cachedPartnerId != null && _cachedPartnerId!.isNotEmpty) {
      return _cachedPartnerId!;
    }
    final cleanPhone = currentPhone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.isNotEmpty ? 'partner_$cleanPhone' : 'partner_active';
  }

  /// Initialize session from local storage on app start
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('partner_is_logged_in') ?? false;
      _cachedPhone = prefs.getString('partner_phone');
      _cachedPartnerId = prefs.getString('partner_id');
      if (_cachedPhone != null && _cachedPhone!.isNotEmpty) {
        final cleanPhone = _cachedPhone!.replaceAll(RegExp(r'\D'), '');
        _cachedPartnerId ??= 'partner_$cleanPhone';
      }
    } catch (_) {}
  }

  /// Persist partner session to local storage
  Future<void> savePartnerSession({required String phoneNumber, String? partnerId}) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final targetId = partnerId ?? 'partner_$cleanPhone';

      _cachedPhone = phoneNumber;
      _cachedPartnerId = targetId;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('partner_is_logged_in', true);
      await prefs.setString('partner_phone', phoneNumber);
      await prefs.setString('partner_id', targetId);
    } catch (_) {}
  }

  /// Retrieve saved partner session
  Future<Map<String, dynamic>?> getSavedSession() async {
    await initSession();
    if (_isLoggedIn && _cachedPhone != null && _cachedPhone!.isNotEmpty) {
      return {
        'isLoggedIn': true,
        'phone': _cachedPhone!,
        'id': currentUid,
      };
    }
    return null;
  }

  /// Clear partner session on logout
  Future<void> clearPartnerSession() async {
    try {
      _cachedPhone = null;
      _cachedPartnerId = null;
      _isLoggedIn = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('partner_is_logged_in');
      await prefs.remove('partner_phone');
      await prefs.remove('partner_id');
      await _auth.signOut();
    } catch (_) {}
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
    List<Map<String, dynamic>>? barbers,
    String status = 'active',
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final targetUid = uid ?? 'partner_${cleanPhone.isEmpty ? "default_salon" : cleanPhone}';

    final defaultBarbers = barbers ?? [];

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
      'barbers': defaultBarbers,
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

    // Save session in memory & SharedPreferences
    await savePartnerSession(phoneNumber: phoneNumber, partnerId: targetUid);
  }

  /// Update only barbers list for a partner salon
  Future<void> updateSalonBarbers(String partnerId, List<Map<String, dynamic>> barbers) async {
    await _firestore.collection('partners').doc(partnerId).update({
      'barbers': barbers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
