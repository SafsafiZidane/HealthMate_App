import 'package:flutter/material.dart';
import 'package:health_mate_mobile_app/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'main_layout.dart';

int? isFirstTimeLaunch;
String? userToken; // <-- AJOUT : Stocker le jeton récupéré localement

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // 1. Vérification du premier lancement
  isFirstTimeLaunch = prefs.getInt('initScreen');

  // 2. AJOUT : Vérification si l'utilisateur est déjà connecté
  // Lors d'un login réussi dans ton AuthScreen, tu devras faire :
  // prefs.setString('token', tokenDuBackend);
  userToken = prefs.getString('token');

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
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        useMaterial3: true,
      ),

      // PORTIER DE ROUTING INTELLIGENT
      // Étape 1 : Si c'est la première fois -> Onboarding
      // Étape 2 : Si ce n'est pas la première fois, mais qu'il n'y a pas de token -> AuthScreen
      // Étape 3 : Si l'utilisateur est déjà connecté -> Accès direct au MainLayout (Home)
      home: (isFirstTimeLaunch == 0 || isFirstTimeLaunch == null)
          ? const OnboardingRoot()
          : (userToken == null ? const AuthScreen() : const MainLayout()),

      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}