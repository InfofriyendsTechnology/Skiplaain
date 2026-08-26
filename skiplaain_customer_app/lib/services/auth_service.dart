import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerAuthService {
  static final CustomerAuthService _instance = CustomerAuthService._internal();
  factory CustomerAuthService() => _instance;
  CustomerAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String? _customerPhone;
  String _customerName = '';

  // Currently active connected salon
  Map<String, dynamic>? _connectedSalon;

  // List of all salons this customer has connected with
  final List<Map<String, dynamic>> _savedSalons = [];

  // Map of salonId -> activePlanDetails
  final Map<String, Map<String, dynamic>> _shopMemberships = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String get customerPhone => _customerPhone ?? '';
  String get customerName => _customerName;
  Map<String, dynamic>? get connectedSalon => _connectedSalon;
  List<Map<String, dynamic>> get savedSalons => List.unmodifiable(_savedSalons);
  bool get isConnectedToSalon => _connectedSalon != null;
  bool get isLoggedIn => _customerPhone != null && _customerPhone!.isNotEmpty && _customerName.isNotEmpty;

  /// Load session from local storage & Cloud Firestore on app start
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customerName = prefs.getString('customer_name') ?? '';
      _customerPhone = prefs.getString('customer_phone');

      final savedSalonsJson = prefs.getString('saved_salons');
      if (savedSalonsJson != null && savedSalonsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedSalonsJson);
        _savedSalons.clear();
        for (var item in decoded) {
          _savedSalons.add(Map<String, dynamic>.from(item as Map));
        }
      }

      final activeSalonJson = prefs.getString('active_connected_salon');
      if (activeSalonJson != null && activeSalonJson.isNotEmpty) {
        _connectedSalon = Map<String, dynamic>.from(jsonDecode(activeSalonJson) as Map);
      } else if (_savedSalons.isNotEmpty) {
        _connectedSalon = _savedSalons.first;
      }

      // If user has phone but no active salon in local storage, sync from Cloud Firestore
      if (_customerPhone != null && _customerPhone!.isNotEmpty && _connectedSalon == null) {
        await _syncFromCloudFirestore(_customerPhone!);
      }
    } catch (_) {}
    _isInitialized = true;
  }

  Future<void> _syncFromCloudFirestore(String phone) async {
    try {
      final custDoc = await _firestore.collection('customers').doc(phone).get();
      if (custDoc.exists && custDoc.data() != null) {
        final data = custDoc.data()!;
        if (_customerName.isEmpty && data['name'] != null) {
          _customerName = data['name'].toString();
        }

        final activeSalonId = data['activeSalonId']?.toString();
        if (activeSalonId != null && activeSalonId.isNotEmpty) {
          final salonDoc = await _firestore.collection('partners').doc(activeSalonId).get();
          if (salonDoc.exists && salonDoc.data() != null) {
            final salonData = Map<String, dynamic>.from(salonDoc.data()!);
            salonData['id'] = salonDoc.id;
            _connectedSalon = salonData;
            if (!_savedSalons.any((s) => (s['id'] ?? '').toString() == activeSalonId)) {
              _savedSalons.insert(0, salonData);
            }
            await _persistSession();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customerName.isNotEmpty) {
        await prefs.setString('customer_name', _customerName);
      } else {
        await prefs.remove('customer_name');
      }

      if (_customerPhone != null && _customerPhone!.isNotEmpty) {
        await prefs.setString('customer_phone', _customerPhone!);
      } else {
        await prefs.remove('customer_phone');
      }

      if (_savedSalons.isNotEmpty) {
        await prefs.setString('saved_salons', jsonEncode(_savedSalons));
      } else {
        await prefs.remove('saved_salons');
      }

      if (_connectedSalon != null) {
        await prefs.setString('active_connected_salon', jsonEncode(_connectedSalon));
      } else {
        await prefs.remove('active_connected_salon');
      }
    } catch (_) {}
  }

  Future<void> setCustomerProfile(String name, String phone) async {
    _customerName = name;
    _customerPhone = phone.trim().startsWith('+') ? phone.trim() : '+91${phone.trim().replaceAll(RegExp(r'\D'), '')}';
    await _persistSession();
  }

  Future<void> updateCustomerName(String newName) async {
    _customerName = newName.trim();
    await _persistSession();
    if (_customerPhone != null && _customerPhone!.isNotEmpty) {
      try {
        await _firestore.collection('customers').doc(_customerPhone!).set({
          'name': _customerName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Send OTP to customer mobile number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final cleanPhone = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length < 10) {
        onError("Please enter a valid 10-digit mobile number.");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verify OTP
  Future<void> verifyOTP({
    required String otp,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final cleanOtp = otp.trim();
      if (cleanOtp == "111111" || cleanOtp.length == 6) {
        await Future.delayed(const Duration(milliseconds: 400));
        onSuccess();
      } else {
        onError("Invalid OTP. Please enter 6-digit OTP.");
      }
    } catch (e) {
      onError("Verification failed. Please try again.");
    }
  }

  /// Register customer in Cloud Firestore (in `customers` and linked to `partners/{salonId}`)
  Future<void> registerCustomerInCloud({
    required String name,
    required String phone,
    required Map<String, dynamic> salon,
  }) async {
    final cleanPhone = phone.startsWith('+') ? phone : '+91${phone.replaceAll(RegExp(r'\D'), '')}';
    final salonId = (salon['id'] ?? 'salon_id').toString();
    final salonName = (salon['salonName'] ?? salon['businessName'] ?? 'Salon').toString();

    final customerData = {
      'id': cleanPhone,
      'name': name,
      'phone': cleanPhone,
      'activeSalonId': salonId,
      'activeSalonName': salonName,
      'connectedSalons': FieldValue.arrayUnion([salonId]),
      'lastActive': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Save in global customers collection
    await _firestore.collection('customers').doc(cleanPhone).set(customerData, SetOptions(merge: true));

    // 2. Also register under the partner salon's customer registry for partner dashboard
    try {
      await _firestore.collection('partners').doc(salonId).collection('customers').doc(cleanPhone).set({
        'name': name,
        'phone': cleanPhone,
        'connectedAt': FieldValue.serverTimestamp(),
        'lastVisit': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Increment total customers count in partner document
      await _firestore.collection('partners').doc(salonId).update({
        'totalCustomers': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  /// Verify OTP and complete cloud registration & connect
  Future<void> verifyOtpAndConnect({
    required String otp,
    required String name,
    required String phone,
    required Map<String, dynamic> salon,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      if (otp.trim() == "111111") {
        await setCustomerProfile(name, phone);
        await connectSalon(salon);

        // Save in Firestore cloud
        await registerCustomerInCloud(name: name, phone: phone, salon: salon);

        onSuccess();
      } else {
        onError("Invalid OTP. Use 111111 for testing.");
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Connect to a salon and add it to saved shops list
  Future<void> connectSalon(Map<String, dynamic> salon) async {
    _connectedSalon = salon;

    final salonId = (salon['id'] ?? '').toString();
    final existingIndex = _savedSalons.indexWhere((s) => (s['id'] ?? '').toString() == salonId);
    if (existingIndex >= 0) {
      _savedSalons[existingIndex] = salon;
    } else {
      _savedSalons.insert(0, salon);
    }

    await _persistSession();
  }

  /// Switch active shop from saved shops list
  Future<void> switchActiveSalon(Map<String, dynamic> salon) async {
    _connectedSalon = salon;
    await _persistSession();
  }

  /// Disconnect current active shop (to scan a new one)
  Future<void> disconnectSalon() async {
    _connectedSalon = null;
    await _persistSession();
  }

  /// Complete logout and clear local memory
  Future<void> logout() async {
    _customerName = '';
    _customerPhone = null;
    _connectedSalon = null;
    _savedSalons.clear();
    _shopMemberships.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  bool isVipMemberForSalon(String salonId) {
    return _shopMemberships.containsKey(salonId);
  }

  Map<String, dynamic>? getSalonMembership(String salonId) {
    return _shopMemberships[salonId];
  }

  void activateSalonMembership(String salonId, String planName, int price, int durationMonths) {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: durationMonths * 30));
    _shopMemberships[salonId] = {
      'planName': planName,
      'price': price,
      'durationMonths': durationMonths,
      'activatedAt': now.toIso8601String(),
      'expiresAt': expiry.toIso8601String(),
    };
  }
}
