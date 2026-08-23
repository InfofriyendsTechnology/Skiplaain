import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/transitions.dart';
import 'onboarding/welcome_partner_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final AuthService authService;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.authService,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  
  // Timer State
  int _resendTimeout = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimeout = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout > 0) {
        setState(() {
          _resendTimeout--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resendOTP() {
    if (_resendTimeout > 0) return;

    _startResendTimer();
    
    widget.authService.sendOTP(
      phoneNumber: widget.phoneNumber,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent again successfully!'),
            backgroundColor: Color(0xFF00FF00),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOTP() {
    if (_otpController.text.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    widget.authService.verifyOTP(
      otp: _otpController.text,
      onSuccess: () {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to Onboarding Welcome Screen
        Navigator.pushAndRemoveUntil(
          context,
          PremiumTransition(page: WelcomePartnerScreen(phoneNumber: widget.phoneNumber)),
          (route) => false,
        );
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Verify Phone',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: 'Enter the 6-digit code sent to ',
                      style: const TextStyle(fontSize: 15, color: Colors.white70),
                      children: [
                        TextSpan(
                          text: widget.phoneNumber,
                          style: const TextStyle(
                            color: Color(0xFF00FF00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: const Text(
                      'Testing OTP: 111111',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The visual boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            String char = "";
                            if (_otpController.text.length > index) {
                              char = _otpController.text[index];
                            }
                            
                            bool isFocused = _otpController.text.length == index;

                            return Expanded(
                              child: Container(
                                height: 60,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFocused ? const Color(0xFF00FF00) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        // The actual invisible TextField that captures input
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0, // Make it completely invisible
                            child: TextField(
                              controller: _otpController,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {}); // Trigger rebuild to update visual boxes
                                if (val.length == 6) {
                                  _verifyOTP();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
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
                              'Verify',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _resendTimeout > 0 ? null : _resendOTP,
                      style: TextButton.styleFrom(
                        foregroundColor: _resendTimeout > 0 ? Colors.white38 : const Color(0xFF00FF00),
                      ),
                      child: Text(
                        _resendTimeout > 0
                            ? "Resend Code in 00:${_resendTimeout.toString().padLeft(2, '0')}"
                            : "Didn't receive the code? Resend",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _resendTimeout > 0 ? FontWeight.normal : FontWeight.bold,
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
