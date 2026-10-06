import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';
import '../utils/popup_utils.dart';
import '../utils/transitions.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  String _completePhoneNumber = "";
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 90, 
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your phone number to login or register your salon.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00FF00), width: 2),
                      ),
                      counterStyle: const TextStyle(color: Colors.white54), // length counter
                    ),
                    style: const TextStyle(fontSize: 18),
                    initialCountryCode: 'IN', // Default to India
                    dropdownTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
                    dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              String rawNumber = _phoneController.text.trim().replaceAll(' ', '');
                              if (rawNumber.length != 10) {
                                PopupUtils.showErrorNotification(
                                  context,
                                  'Please enter a valid 10-digit number',
                                );
                                return;
                              }
                              
                              // Strictly format for Firebase
                              String finalNumber = "+91$rawNumber";
                              print("Sending OTP to: \$finalNumber"); // Debug log

                              setState(() {
                                _isLoading = true;
                              });

                              // Check if existing partner
                              _authService.isPhoneNumberRegistered(finalNumber).then((isRegistered) {
                                if (isRegistered) {
                                  // Existing partner - Login flow
                                  _authService.sendOTP(
                                    phoneNumber: finalNumber,
                                    onSuccess: () {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      PopupUtils.showSuccessNotification(
                                        context,
                                        'Welcome back! OTP sent',
                                      );
                                      Navigator.push(
                                        context,
                                        PremiumTransition(
                                          page: OtpScreen(
                                            phoneNumber: finalNumber,
                                            authService: _authService,
                                            isNewUser: false,
                                          ),
                                        ),
                                      );
                                    },
                                    onError: (error) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      PopupUtils.showErrorNotification(context, error);
                                    },
                                  );
                                } else {
                                  // New partner - Signup flow
                                  _authService.sendOTP(
                                    phoneNumber: finalNumber,
                                    onSuccess: () {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      PopupUtils.showSuccessNotification(
                                        context,
                                        'Let\'s set up your salon! OTP sent',
                                      );
                                      Navigator.push(
                                        context,
                                        PremiumTransition(
                                          page: OtpScreen(
                                            phoneNumber: finalNumber,
                                            authService: _authService,
                                            isNewUser: true,
                                          ),
                                        ),
                                      );
                                    },
                                    onError: (error) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      PopupUtils.showErrorNotification(context, error);
                                    },
                                  );
                                }
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
