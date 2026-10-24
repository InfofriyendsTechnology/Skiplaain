import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Check if phone number already registered as partner
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

  /// Send OTP to the given phone number via API
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

      final response = await _api.post('/auth/send-otp', {
        'phone': phoneNumber,
        'purpose': 'login',
      });

      if (response['success'] == true) {
        print("OTP sent successfully to $phoneNumber");
        onSuccess();
      } else {
        onError(response['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('Error sending OTP: $e');
      onError('Network error. Please try again.');
    }
  }

  /// Verify the OTP entered by the user via API
  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
    required Function(String token, Map<String, dynamic>? userData) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final cleanOtp = otp.trim();

      final response = await _api.post('/auth/verify-otp', {
        'phone': phoneNumber,
        'otp': cleanOtp,
        'userType': 'partner',
      });

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? '';
        final userData = response['data']?['partner'];
        
        // Save token
        if (token.isNotEmpty) {
          await _api.saveToken(token);
        }
        
        print("OTP verified successfully");
        onSuccess(token, userData);
      } else {
        onError(response['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      onError('Verification failed. Please try again.');
    }
  }

  /// Logout - clear token
  Future<void> logout() async {
    try {
      await _api.clearToken();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
