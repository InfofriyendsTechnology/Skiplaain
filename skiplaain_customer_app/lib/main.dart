import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/api_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiAuthService().initSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skiplaain',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // Use system default instead of Google Fonts
      ),
      home: const SplashScreen(),
    );
  }
}
