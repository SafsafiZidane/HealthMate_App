import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/health_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/consultation_provider.dart';
import 'package:health_mate_mobile_app/screens/admin/admin_dashboard_screen.dart';
import 'package:health_mate_mobile_app/screens/doctor/doctor_dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'main_layout.dart';
import 'HomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? isFirstTimeLaunch = prefs.getInt('initScreen');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConsultationProvider()),
      ],
      child: HealthMateApp(isFirstTimeLaunch: isFirstTimeLaunch),
    ),
  );
}

class HealthMateApp extends StatelessWidget {
  final int? isFirstTimeLaunch;
  const HealthMateApp({super.key, this.isFirstTimeLaunch});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthMate 2.0',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0052CC)),
        useMaterial3: true,
      ),
      home: (isFirstTimeLaunch == 0 || isFirstTimeLaunch == null)
          ? const OnboardingRoot()
          : (authProvider.isAuthenticated 
              ? (authProvider.role == 'admin' 
                  ? const AdminDashboardScreen() 
                  : (authProvider.role == 'doctor' ? const DoctorDashboardScreen() : const MainLayout()))
              : const AuthScreen()),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
