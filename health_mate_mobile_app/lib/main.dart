import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';   // Imported your auth page
import 'main_layout.dart';   // Imported your home page with the bottom navigation bar

int? isFirstTimeLaunch;

void main() async {
  // Ensures Flutter engine bindings are completely ready before checking shared preferences
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Try to read the initialization value. If it's null, it's the user's first time ever installing.
  isFirstTimeLaunch = prefs.getInt('initScreen');

  // Note: We keep this at 0 or null during onboarding, and write '1' once they officially complete it
  // or pass the gate to prevent getting locked out during hot-reloads while developing.

  runApp(const HealthMateApp());
}

class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthMate 2.0',
      theme: ThemeData(
        fontFamily: 'SF Pro Display', // Clean, professional iOS/Android typography look
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        useMaterial3: true, // Maximizes UI components rendering layout compatibility
      ),

      // PERSISTENT ROUTING CONTROLLER
      // 1. If null/0 -> User goes straight to Onboarding steps flow.
      // 2. If 1 -> User completely skips intro and lands immediately on the Auth Login view.
      home: (isFirstTimeLaunch == 0 || isFirstTimeLaunch == null)
          ? const OnboardingRoot()
          : const AuthScreen(),

      // Named routes infrastructure map in case you want explicit back-referencing transitions later
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const MainLayout(),
      },
    );
  }
}