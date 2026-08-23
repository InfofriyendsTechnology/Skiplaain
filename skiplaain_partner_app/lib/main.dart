import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkiplaainPartnerApp());
}

class SkiplaainPartnerApp extends StatelessWidget {
  const SkiplaainPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skiplaain Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF00), // Pure Neon Green
        scaffoldBackgroundColor: const Color(0xFF000000), // Solid Black
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
          ThemeData.dark().textTheme.apply(
            bodyColor: const Color(0xFFFFFFFF),
            displayColor: const Color(0xFFFFFFFF),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212), // Surface Gray
          elevation: 0,
        ),
        cardColor: const Color(0xFF1A1A1A), // Lighter Surface
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF00),
          secondary: Color(0xFF00FF00),
          surface: Color(0xFF121212),
          background: Color(0xFF000000),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// We will keep the DashboardScreen here for now, but it's no longer the default home.

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skiplaain Partner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // The "Busy Switch" mockup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Accepting Walk-ins'),
                const SizedBox(width: 8),
                Switch(
                  value: true,
                  onChanged: (val) {},
                  activeColor: Colors.green,
                ),
              ],
            ),
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Skiplaain Partner Dashboard\n\nDatabase: Firebase (Pending Config)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
