import 'package:flutter/material.dart';
import '../services/partner_service.dart';
import '../utils/transitions.dart';
import 'login_screen.dart';
import 'onboarding/welcome_partner_screen.dart';
import 'dashboard/main_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PartnerService _partnerService = PartnerService();

  @override
  void initState() {
    super.initState();
    _checkSavedSessionAndRoute();
  }

  void _checkSavedSessionAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    try {
      final savedSession = await _partnerService.getSavedSession();

      if (savedSession != null && savedSession['isLoggedIn'] == true) {
        final phone = (savedSession['phone'] ?? '').toString();
        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
        final partnerId = (savedSession['id'] ?? 'partner_$cleanPhone').toString();

        if (phone.isNotEmpty) {
          // Check if salon profile is completed via API
          bool isOnboarded = false;
          try {
            final partnerData = await PartnerService().getPartnerProfile(partnerId);
            if (partnerData != null && 
                (partnerData['isOnboarded'] == true || partnerData['salonName'] != null)) {
              isOnboarded = true;
            }
          } catch (e) {
            print('Error checking onboarding: $e');
          }

          if (!mounted) return;

          if (isOnboarded) {
            // Already onboarded salon -> Go directly to Dashboard!
            Navigator.pushReplacement(
              context,
              PremiumTransition(page: const MainDashboardScreen()),
            );
            return;
          } else {
            // Session saved but onboarding in progress -> Resume Onboarding
            Navigator.pushReplacement(
              context,
              PremiumTransition(page: WelcomePartnerScreen(phoneNumber: phone)),
            );
            return;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    // No active session -> Go to Login
    Navigator.pushReplacement(
      context,
      PremiumTransition(page: const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Solid Black background
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: scale.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/bird_transparent.png',
            height: 110,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
