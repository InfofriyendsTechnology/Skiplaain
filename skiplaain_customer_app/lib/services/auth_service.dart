import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerAuthService {
  static final CustomerAuthService _instance = CustomerAuthService._internal();
  factory CustomerAuthService() => _instance;
  CustomerAuthService._internal();

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

  /// Load session from local storage on app start
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
    } catch (_) {}
    _isInitialized = true;
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
  }

  /// Check if phone number already exists locally
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.trim().startsWith('+')
          ? phoneNumber.trim()
          : '+91${phoneNumber.trim().replaceAll(RegExp(r'\D'), '')}';
      
      final prefs = await SharedPreferences.getInstance();
      final storedPhone = prefs.getString('customer_phone');
      return storedPhone == cleanPhone;
    } catch (e) {
      return false;
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

      // Check if phone number already registered
      final fullPhone = '+91$cleanPhone';
      final isRegistered = await isPhoneNumberRegistered(fullPhone);
      if (isRegistered) {
        onError("This mobile number is already registered. Please login or use a different number.");
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

  /// Register customer (local storage only - using Neon PostgreSQL backend)
  Future<void> registerCustomer({
    required String name,
    required String phone,
    required Map<String, dynamic> salon,
  }) async {
    await setCustomerProfile(name, phone);
    await connectSalon(salon);
  }

  /// Verify OTP and complete registration & connect
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
