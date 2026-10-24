import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class PartnerService {
  static final PartnerService _instance = PartnerService._internal();
  factory PartnerService() => _instance;
  PartnerService._internal();

  final ApiService _api = ApiService();

  String? _cachedPhone;
  String? _cachedPartnerId;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  String get currentPhone => _cachedPhone ?? '';
  
  String get currentUid {
    if (_cachedPartnerId != null && _cachedPartnerId!.isNotEmpty) {
      return _cachedPartnerId!;
    }
    final cleanPhone = currentPhone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.isNotEmpty ? 'partner_$cleanPhone' : 'partner_active';
  }

  String? get currentPartnerId {
    if (_cachedPartnerId != null && _cachedPartnerId!.isNotEmpty) {
      return _cachedPartnerId!;
    }
    final cleanPhone = currentPhone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.isNotEmpty ? 'partner_$cleanPhone' : null;
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
    } catch (e) {
      print('Error initializing partner session: $e');
    }
  }

  /// Persist partner session to local storage
  Future<void> savePartnerSession({
    required String phoneNumber, 
    String? partnerId
  }) async {
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
    } catch (e) {
      print('Error saving partner session: $e');
    }
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
      
      // Clear API token
      await _api.clearToken();
    } catch (e) {
      print('Error clearing partner session: $e');
    }
  }

  /// Check if phone number already exists as a partner
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final response = await _api.post('/partners/check-phone', {
        'phone': phoneNumber,
      });
      
      return response['exists'] == true;
    } catch (e) {
      print('Error checking phone registration: $e');
      return false;
    }
  }

  /// Get partner profile from API
  Future<Map<String, dynamic>?> getPartnerProfile(String partnerId) async {
    try {
      final response = await _api.get('/partners/$partnerId');
      
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching partner profile: $e');
      return null;
    }
  }

  /// Update partner profile
  Future<bool> updatePartnerProfile({
    required String partnerId,
    String? salonName,
    String? address,
    String? category,
    String? openingTime,
    String? closingTime,
    String? weeklyOff,
    List<Map<String, dynamic>>? services,
    List<Map<String, dynamic>>? barbers,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (salonName != null) updateData['salonName'] = salonName;
      if (address != null) updateData['address'] = address;
      if (category != null) updateData['category'] = category;
      if (openingTime != null) updateData['openingTime'] = openingTime;
      if (closingTime != null) updateData['closingTime'] = closingTime;
      if (weeklyOff != null) updateData['weeklyOff'] = weeklyOff;
      if (services != null) updateData['services'] = services;
      if (barbers != null) updateData['barbers'] = barbers;

      final response = await _api.put('/partners/$partnerId', updateData);
      
      return response['success'] == true;
    } catch (e) {
      print('Error updating partner profile: $e');
      return false;
    }
  }

  /// Update only barbers list for a partner salon
  Future<bool> updateSalonBarbers(
    String partnerId, 
    List<Map<String, dynamic>> barbers
  ) async {
    try {
      final response = await _api.put('/partners/$partnerId', {
        'barbers': barbers,
      });
      
      return response['success'] == true;
    } catch (e) {
      print('Error updating salon barbers: $e');
      return false;
    }
  }

  /// Save or update full partner profile during Onboarding
  Future<bool> savePartnerProfile({
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
    try {
      final partnerId = uid ?? currentPartnerId;
      
      if (partnerId == null) {
        print('Error: No partner ID available');
        return false;
      }

      final success = await updatePartnerProfile(
        partnerId: partnerId,
        salonName: salonName,
        address: address,
        category: category,
        openingTime: openingTime,
        closingTime: closingTime,
        weeklyOff: weeklyOff,
        services: services,
        barbers: barbers,
      );

      if (success) {
        await savePartnerSession(
          phoneNumber: phoneNumber, 
          partnerId: partnerId
        );
      }

      return success;
    } catch (e) {
      print('Error saving partner profile: $e');
      return false;
    }
  }
}
