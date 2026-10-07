import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// NEW API-based Partner Auth & Management Service
class ApiPartnerService {
  static final ApiPartnerService _instance = ApiPartnerService._internal();
  factory ApiPartnerService() => _instance;
  ApiPartnerService._internal();

  final ApiService _api = ApiService();

  String? _partnerId;
  String? _partnerPhone;
  String _salonName = '';
  String _status = 'pending';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String get partnerId => _partnerId ?? '';
  String get partnerPhone => _partnerPhone ?? '';
  String get salonName => _salonName;
  String get status => _status;
  bool get isApproved => _status == 'approved';
  bool get isLoggedIn => _partnerId != null && _partnerId!.isNotEmpty;

  /// Initialize session
  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _partnerId = prefs.getString('partner_id');
      _partnerPhone = prefs.getString('partner_phone');
      _salonName = prefs.getString('salon_name') ?? '';
      _status = prefs.getString('partner_status') ?? 'pending';
    } catch (_) {}
    _isInitialized = true;
  }

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final result = await _api.post('/auth/send-otp', {
      'phone': phone,
      'purpose': 'login',
    });
    return result;
  }

  /// Verify OTP and login (partner)
  Future<Map<String, dynamic>> verifyOtpAndLogin({
    required String phone,
    required String otp,
  }) async {
    final result = await _api.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
      'userType': 'partner',
    });

    if (result['success'] == true) {
      final token = result['data']['token'];
      final user = result['data']['user'];

      await _api.saveToken(token);

      _partnerId = user['id'];
      _partnerPhone = user['phone'];
      _salonName = user['salonName'] ?? '';
      _status = user['status'] ?? 'pending';

      await _persistSession();
    }

    return result;
  }

  /// Register new partner
  Future<Map<String, dynamic>> registerPartner({
    required String phone,
    required String ownerName,
    required String salonName,
    required String address,
    String? city,
    String? pincode,
    String? email,
    double? latitude,
    double? longitude,
    String? profileImage,
    List<Map<String, dynamic>>? barbers,
    List<Map<String, dynamic>>? services,
  }) async {
    final result = await _api.post('/partners', {
      'phone': phone,
      'ownerName': ownerName,
      'salonName': salonName,
      'address': address,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
      if (email != null) 'email': email,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (profileImage != null) 'profileImage': profileImage,
      'barbers': barbers ?? [],
      'services': services ?? [],
    });

    return result;
  }

  /// Get partner details
  Future<Map<String, dynamic>> getCurrentPartner() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      throw Exception('Partner not logged in');
    }

    final result = await _api.get('/partners/$_partnerId');

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      _salonName = data['salonName'] ?? _salonName;
      _status = data['status'] ?? _status;
      await _persistSession();
      return data;
    }

    throw Exception('Failed to fetch partner data');
  }

  /// Get partner details (legacy method)
  Future<Map<String, dynamic>?> getPartnerDetails() async {
    if (_partnerId == null) return null;

    final result = await _api.get('/partners/$_partnerId');

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    }

    return null;
  }

  /// Get partner bookings
  Future<List<Map<String, dynamic>>> getPartnerBookings(String partnerId, {String? status}) async {
    final endpoint = status != null
        ? '/bookings/partner/$partnerId?status=$status'
        : '/bookings/partner/$partnerId';

    final result = await _api.get(endpoint);

    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    }

    return [];
  }

  /// Complete booking
  Future<Map<String, dynamic>> completeBooking(String bookingId) async {
    return await _api.patch('/bookings/$bookingId/status', {
      'status': 'completed',
    });
  }

  /// Cancel booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId, String reason) async {
    return await _api.patch('/bookings/$bookingId/status', {
      'status': 'cancelled',
      'cancelReason': reason,
    });
  }

  /// Persist session
  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_partnerId != null) await prefs.setString('partner_id', _partnerId!);
      if (_partnerPhone != null) await prefs.setString('partner_phone', _partnerPhone!);
      if (_salonName.isNotEmpty) await prefs.setString('salon_name', _salonName);
      await prefs.setString('partner_status', _status);
    } catch (_) {}
  }

  /// Logout
  Future<void> logout() async {
    _partnerId = null;
    _partnerPhone = null;
    _salonName = '';
    _status = 'pending';

    await _api.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Getter for currentPartnerId (used in other services)
  String? get currentPartnerId => _partnerId;
}
