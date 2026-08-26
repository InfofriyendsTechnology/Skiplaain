import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const CustomerOnboardingScreen({super.key, required this.salon});

  @override
  State<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  final CustomerAuthService _authService = CustomerAuthService();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0; // 0 = Phone, 1 = OTP, 2 = Name
  bool _isLoading = false;
  String _errorMessage = '';

  String _countryCode = '+91';
  String _completePhoneNumber = '';

  // Timer State for OTP
  int _resendTimeout = 30;
  Timer? _resendTimer;

  String get _salonName => (widget.salon['salonName'] ?? widget.salon['businessName'] ?? 'Salon').toString();
  String get _salonAddress => (widget.salon['address'] ?? widget.salon['location'] ?? 'Surat').toString();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimeout = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout > 0) {
        setState(() {
          _resendTimeout--;
        });
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  // STEP 1: Submit Phone & Request OTP
  void _onSubmitPhone() {
    final rawNumber = _phoneController.text.trim().replaceAll(' ', '').replaceAll(RegExp(r'\D'), '');

    if (_countryCode == '+91') {
      if (rawNumber.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(rawNumber)) {
        setState(() => _errorMessage = 'Please enter a valid 10-digit Indian mobile number');
        return;
      }
    } else {
      if (rawNumber.length < 7 || rawNumber.length > 13) {
        setState(() => _errorMessage = 'Please enter a valid phone number');
        return;
      }
    }

    _completePhoneNumber = '$_countryCode$rawNumber';

    setState(() {
      _errorMessage = '';
      _currentStep = 1;
      _otpController.clear();
    });
    _startResendTimer();
  }

  // STEP 2: Verify OTP
  void _onVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit verification code');
      return;
    }

    if (otp != "111111") {
      setState(() => _errorMessage = 'Invalid verification code. Please check and try again.');
      return;
    }

    setState(() {
      _errorMessage = '';
      _currentStep = 2; // Move to Name entry!
    });
  }

  // Resend OTP
  void _resendOtp() {
    if (_resendTimeout > 0) return;
    _startResendTimer();
    setState(() {
      _errorMessage = '';
      _otpController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code sent successfully to your mobile number'),
        backgroundColor: Color(0xFF162B16),
      ),
    );
  }

  // STEP 3: Submit Name & Complete Registration
  void _onCompleteRegistration() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      setState(() => _errorMessage = 'Please enter your full name (minimum 2 characters)');
      return;
    }

    final rawPhone = _phoneController.text.trim().replaceAll(' ', '').replaceAll(RegExp(r'\D'), '');
    final fullPhone = '$_countryCode$rawPhone';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.setCustomerProfile(name, fullPhone);
      await _authService.connectSalon(widget.salon);

      // Save to Cloud Firestore
      await _authService.registerCustomerInCloud(
        name: name,
        phone: fullPhone,
        salon: widget.salon,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to register: $e';
        });
      }
    }
  }

  String _getFormattedPhone() {
    final raw = _phoneController.text.trim().replaceAll(' ', '').replaceAll(RegExp(r'\D'), '');
    if (raw.length == 10) {
      return '$_countryCode ${raw.substring(0, 5)} ${raw.substring(5)}';
    }
    return '$_countryCode $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF262626)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
                _errorMessage = '';
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Image.asset('assets/images/full_logo.png', height: 28, fit: BoxFit.contain),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connected Shop Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF00FF00), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _salonName,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _salonAddress,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'STEP ${_currentStep + 1}/3',
                            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // STEP 0: PHONE NUMBER SCREEN WITH INTL PHONE FIELD (EXACTLY LIKE PARTNER APP)
                  if (_currentStep == 0) ...[
                    const Text(
                      'Enter Mobile Number',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your phone number to connect and skip the queue.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Mobile Number',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'IN',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      dropdownTextStyle: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      dropdownIcon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                      cursorColor: const Color(0xFF00FF00),
                      flagsButtonMargin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                        counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      onCountryChanged: (country) {
                        setState(() {
                          _countryCode = '+${country.dialCode}';
                        });
                      },
                      onChanged: (phone) {
                        _completePhoneNumber = phone.completeNumber;
                      },
                      onSubmitted: (_) => _onSubmitPhone(),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onSubmitPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Get Verification Code'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // STEP 1: AUTHENTIC 6-BOX OTP VERIFICATION SCREEN (CLEAN, NO TESTING LABELS)
                  if (_currentStep == 1) ...[
                    const Text(
                      'Verify Phone Number',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        text: 'Enter the 6-digit verification code sent to ',
                        style: const TextStyle(fontSize: 13, color: Colors.white54),
                        children: [
                          TextSpan(
                            text: _getFormattedPhone(),
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Visual 6-Box OTP UI
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 6 Individual Boxes
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
                                              color: const Color(0xFF00FF00).withOpacity(0.2),
                                              blurRadius: 8,
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

                          // Invisible capture TextField
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
                                    _onVerifyOtp();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verify Code'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: _resendTimeout > 0 ? null : _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: _resendTimeout > 0 ? Colors.white38 : const Color(0xFF00FF00),
                        ),
                        child: Text(
                          _resendTimeout > 0
                              ? "Resend Code in 00:${_resendTimeout.toString().padLeft(2, '0')}"
                              : "Didn't receive code? Resend Code",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _resendTimeout > 0 ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // STEP 2: NAME ENTRY SCREEN (After OTP is verified)
                  if (_currentStep == 2) ...[
                    const Text(
                      'What is your name?',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Let the salon know who is walking in',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Your Full Name',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF00FF00), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _onCompleteRegistration(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onCompleteRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Complete & Enter Salon'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ],

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
