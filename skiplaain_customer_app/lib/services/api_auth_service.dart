import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// NEW API-based Auth Service (replaces Firebase Auth)
class ApiAuthService {
  static final ApiAuthService _instance = ApiAuthService._internal();
  factory ApiAuthService() => _instance;
  ApiAuthService._internal();

  final ApiService _api = ApiService();

  String? _customerPhone;
  String _customerName = '';
  Map<String, dynamic>? _connectedSalon;
  final List<Map<String, dynamic>> _savedSalons = [];
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String get customerPhone => _customerPhone ?? '';
  String get customerName => _customerName;
  Map<String, dynamic>? get connectedSalon => _connectedSalon;
  List<Map<String, dynamic>> get savedSalons => List.unmodifiable(_savedSalons);
  bool get isConnectedToSalon => _connectedSalon != null;
  bool get isLoggedIn => _customerPhone != null && _customerPhone!.isNotEmpty && _customerName.isNotEmpty;

  /// Initialize session from local storage
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

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final result = await _api.post('/auth/send-otp', {
      'phone': phone,
      'purpose': 'login',
    });
    return result;
  }

  /// Verify OTP and login
  Future<Map<String, dynamic>> verifyOtpAndLogin({
    required String phone,
    required String otp,
    required String name,
  }) async {
    final result = await _api.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
      'userType': 'customer',
      'name': name,
    });

    if (result['success'] == true) {
      final token = result['data']['token'];
      final user = result['data']['user'];

      await _api.saveToken(token);
      await _api.saveUserPhone(user['phone']);

      _customerPhone = user['phone'];
      _customerName = user['name'];

      await _persistSession();
    }

    return result;
  }

  /// Persist session to local storage
  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customerName.isNotEmpty) {
        await prefs.setString('customer_name', _customerName);
      }
      if (_customerPhone != null && _customerPhone!.isNotEmpty) {
        await prefs.setString('customer_phone', _customerPhone!);
      }
      if (_savedSalons.isNotEmpty) {
        await prefs.setString('saved_salons', jsonEncode(_savedSalons));
      }
      if (_connectedSalon != null) {
        await prefs.setString('active_connected_salon', jsonEncode(_connectedSalon));
      }
    } catch (_) {}
  }

  /// Connect to a salon
  Future<void> connectToSalon(Map<String, dynamic> salonData) async {
    _connectedSalon = salonData;
    
    // Add to saved salons if not already there
    final salonId = salonData['id']?.toString() ?? '';
    if (!_savedSalons.any((s) => (s['id'] ?? '').toString() == salonId)) {
      _savedSalons.insert(0, salonData);
    }

    await _persistSession();
  }

  /// Connect to salon (legacy compatibility)
  Future<void> connectSalon(Map<String, dynamic> salonData) async {
    await connectToSalon(salonData);
  }

  /// Disconnect from salon
  Future<void> disconnectSalon() async {
    _connectedSalon = null;
    await _persistSession();
  }

  /// Switch active salon
  Future<void> switchSalon(Map<String, dynamic> salonData) async {
    _connectedSalon = salonData;
    await _persistSession();
  }

  /// Switch active salon (legacy compatibility)
  Future<void> switchActiveSalon(Map<String, dynamic> salonData) async {
    await switchSalon(salonData);
  }

  /// Activate salon membership (stub - implement later)
  Future<void> activateSalonMembership(String salonId, String planName, int duration) async {
    // TODO: Call API to activate membership
    await _persistSession();
  }

  /// Update customer name
  Future<void> updateCustomerName(String newName) async {
    _customerName = newName;
    await _persistSession();
  }

  /// Logout
  Future<void> logout() async {
    _customerPhone = null;
    _customerName = '';
    _connectedSalon = null;
    _savedSalons.clear();

    await _api.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
