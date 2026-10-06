import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/partner_service.dart';
import '../utils/popup_utils.dart';
import '../utils/transitions.dart';
import 'onboarding/welcome_partner_screen.dart';
import 'dashboard/main_dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final AuthService authService;
  final bool isNewUser;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.authService,
    required this.isNewUser,
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
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimeout = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _resendTimeout--;
        });
      }
    });
  }

  void _resendOTP() {
    if (!_canResend) return;

    widget.authService.sendOTP(
      phoneNumber: widget.phoneNumber,
      onSuccess: () {
        _startResendTimer();
        PopupUtils.showSuccessNotification(
          context,
          'OTP sent again successfully!',
        );
      },
      onError: (error) {
        PopupUtils.showErrorNotification(context, error);
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
    final cleanOtp = _otpController.text.trim();
    if (cleanOtp.length != 6) {
      PopupUtils.showErrorNotification(
        context,
        'Please enter the complete 6-digit OTP',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    widget.authService.verifyOTP(
      otp: cleanOtp,
      onSuccess: () async {
        final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final targetId = 'partner_$cleanPhone';

        // 1. Save session to SharedPreferences immediately
        await PartnerService().savePartnerSession(phoneNumber: widget.phoneNumber, partnerId: targetId);

        // 2. Create / merge partner entry in Firestore
        try {
          await FirebaseFirestore.instance.collection('partners').doc(targetId).set({
            'id': targetId,
            'phone': widget.phoneNumber,
            'status': 'active',
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}

        if (!mounted) return;
        setState(() => _isLoading = false);

        PopupUtils.showSuccessNotification(
          context,
          widget.isNewUser 
              ? 'Phone verified! Let\'s set up your salon'
              : 'Welcome back to Skiplaain!',
        );

        // Small delay for notification visibility before navigation
        await Future.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        if (widget.isNewUser) {
          // New user - always go to onboarding
          Navigator.pushAndRemoveUntil(
            context,
            PremiumTransition(page: WelcomePartnerScreen(phoneNumber: widget.phoneNumber)),
            (route) => false,
          );
        } else {
          // Existing user - go to dashboard
          Navigator.pushAndRemoveUntil(
            context,
            PremiumTransition(page: const MainDashboardScreen()),
            (route) => false,
          );
        }
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        PopupUtils.showErrorNotification(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                  Text(
                    widget.isNewUser ? 'Welcome to Skiplaain!' : 'Welcome Back!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: widget.isNewUser 
                          ? 'Enter code to set up your salon: '
                          : 'Enter the 6-digit code sent to ',
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
                  const SizedBox(height: 36),
                  
                  // ORIGINAL 6-BOX PREMIUM OTP UI
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 6 Individual Square Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            String char = "";
                            if (_otpController.text.length > index) {
                              char = _otpController.text[index];
                            }

                            bool isFocused = _otpController.text.length == index;
                            bool isFilled = char.isNotEmpty;

                            return Expanded(
                              child: Container(
                                height: 56,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFocused
                                        ? const Color(0xFF00FF00)
                                        : (isFilled
                                            ? const Color(0xFF00FF00).withOpacity(0.6)
                                            : const Color(0xFF262626)),
                                    width: isFocused ? 2 : 1.2,
                                  ),
                                  boxShadow: isFocused
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00FF00).withOpacity(0.25),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Invisible Input Handler
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _otpController,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              autofocus: true,
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {});
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
                  
                  const SizedBox(height: 24),
                  
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _resendOTP,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            'Resend code in 00:${_resendTimeout.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  
                  const Spacer(),
                  
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify & Proceed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
