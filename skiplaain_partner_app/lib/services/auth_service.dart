import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Check if phone number already registered as partner
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');
      final partnerId = 'partner_$cleanPhone';
      
      final doc = await _firestore.collection('partners').doc(partnerId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Send OTP to the given phone number (Testing mode: 111111 for ALL numbers)
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

      print("Testing Mode: OTP for $phoneNumber is 111111");
      // Simulate quick network response
      await Future.delayed(const Duration(milliseconds: 600));
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verify the OTP entered by the user (Universal OTP: 111111)
  Future<void> verifyOTP({
    required String otp,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final cleanOtp = otp.trim();

      if (cleanOtp == "111111") {
        print("Testing Mode: Verified universal OTP 111111 successfully.");
        await Future.delayed(const Duration(milliseconds: 500));
        onSuccess();
      } else {
        onError("Invalid OTP. Please enter 111111 for testing.");
      }
    } catch (e) {
      onError("Verification failed. Please try again.");
    }
  }
}
