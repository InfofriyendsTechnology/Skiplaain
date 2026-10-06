import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/popup_utils.dart';
import 'home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Rahul Sharma');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final CustomerAuthService _authService = CustomerAuthService();

  bool _isOtpSent = false;
  bool _isLoading = false;

  void _onSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      PopupUtils.showErrorNotification(
        context,
        'Please enter a valid 10-digit mobile number',
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authService.sendOTP(
      phoneNumber: phone,
      onSuccess: () {
        setState(() {
          _isLoading = false;
          _isOtpSent = true;
        });
        PopupUtils.showSuccessNotification(
          context,
          'OTP sent successfully to +91 $phone',
        );
      },
      onError: (err) {
        setState(() => _isLoading = false);
        PopupUtils.showErrorNotification(context, err);
      },
    );
  }

  void _onVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      PopupUtils.showErrorNotification(
        context,
        'Please enter the 6-digit OTP',
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authService.verifyOTP(
      otp: otp,
      onSuccess: () {
        setState(() => _isLoading = false);
        _authService.setCustomerProfile(
          _nameController.text.trim().isEmpty ? 'Customer' : _nameController.text.trim(),
          _phoneController.text.trim(),
        );
        PopupUtils.showSuccessNotification(
          context,
          'Login successful! Welcome to Skiplaain',
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
      },
      onError: (err) {
        setState(() => _isLoading = false);
        PopupUtils.showErrorNotification(context, err);
      },
    );
  }

  void _onContinueAsGuest() {
    _authService.setCustomerProfile('Guest User', '+919876543210');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/full_logo.png',
                      height: 46,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isOtpSent ? 'Verify Phone' : 'Welcome to Skiplaain',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOtpSent
                        ? 'Enter code sent to ${_phoneController.text}'
                        : 'Book instant salon & grooming appointments without waiting',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_isOtpSent) ...[
                    // Customer Name
                    const Text(
                      'Your Name',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00FF00), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    const Text(
                      'Mobile Number',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1),
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00FF00), size: 20),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Send OTP'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton.icon(
                        onPressed: _onContinueAsGuest,
                        icon: const Icon(Icons.arrow_forward, size: 14, color: Colors.white60),
                        label: const Text(
                          'Skip & Explore as Guest',
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Testing Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF262626)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_clock, color: Color(0xFF00FF00), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Testing Code: 111111',
                            style: TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OTP Input
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF262626)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00FF00), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Verify & Continue'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isOtpSent = false),
                        child: const Text(
                          'Change Mobile Number',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
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
