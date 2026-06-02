import 'package:flutter/material.dart';
import 'package:health_mate_mobile_app/main.dart';
import 'package:health_mate_mobile_app/main_layout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignInTab = true; // Controls the sliding toggle state
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Change this URL string based on deployment environments
  final String backendBaseUrl = "http://10.0.2.2:8000";
  // final String backendBaseUrl = "http://192.168.1.50:8000";

  // ==========================================
  // BACKEND API CONNECTION LOGIC
  // ==========================================
    void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String endpoint = isSignInTab ? "/login" : "/register";
    final Map<String, dynamic> requestPayload = isSignInTab
        ? {
      "email": _emailController.text.trim(),
      "password": _passwordController.text
    }
        : {
      "first_name": "User", // Defaults for your Register Schema properties
      "last_name": "Mate",
      "username": _emailController.text.split('@')[0],
      "email": _emailController.text.trim(),
      "password": _passwordController.text
    };

    try {
      final response = await http.post(
        Uri.parse("$backendBaseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestPayload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showStatusSnackbar(responseData['message'], Colors.green);

        if (isSignInTab) {
          // 1. Extract your JWT token if needed for storage
          // String accessToken = responseData['result']['access_token'];

          // 2. Redirect to main screen permanently so they can't go back to Login
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainLayout()),
                (Route<dynamic> route) => false, // Clears the previous navigation history stack
          );
        } else {
          // Switch automatically to the Login view tab upon successful registration
          setState(() => isSignInTab = true);
        }
      } else {
        _showStatusSnackbar(responseData['message'] ?? "Authentication failed", Colors.redAccent);
      }
    } catch (e) {
      _showStatusSnackbar("Cannot reach backend engine server connection.", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStatusSnackbar(String text, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: backgroundColor, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F7FC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // App Logo Icon Unit
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                      color: const Color(0xFF0052CC),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0052CC).withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 8))
                      ]
                  ),
                  child: const Icon(Icons.analytics_outlined, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 24),

                const Text(
                  "HealthMate 2.0",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF003F9A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your personalized wellness journey starts\nhere.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 32),

                // ==========================================
                // SEGMENTED SLIDING CONTROL BAR
                // ==========================================
                Container(
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isSignInTab = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSignInTab ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSignInTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Sign In",
                              style: TextStyle(fontWeight: FontWeight.bold, color: isSignInTab ? const Color(0xFF003F9A) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isSignInTab = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isSignInTab ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !isSignInTab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Create Account",
                              style: TextStyle(fontWeight: FontWeight.bold, color: !isSignInTab ? const Color(0xFF003F9A) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // MAIN WHITE FORM BLOCK WITH SHADOWS
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value != null && value.contains('@') ? null : "Enter a valid email address",
                        decoration: InputDecoration(
                          hintText: "name@example.com",
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Password", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                          if (isSignInTab)
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text("Forgot?", style: TextStyle(color: Color(0xFF0052CC), fontWeight: FontWeight.bold, fontSize: 14)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) => value != null && value.length >= 6 ? null : "Password must be at least 6 characters",
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Execution Submission Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAuthForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052CC),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isSignInTab ? "Sign In" : "Sign Up",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Decorative Divider Line
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Or continue with", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
                          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Social Media Logins Wrapper
                      Row(
                        children: [
                          Expanded(child: _buildSocialCard("Google", Icons.g_mobiledata_rounded, Colors.red)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSocialCard("Apple", Icons.apple_rounded, Colors.black)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Terms and Conditions Legal Notice Text Link
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text.rich(
                    TextSpan(
                        text: "By signing in, you agree to our ",
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                        children: [
                          TextSpan(text: "Terms of Service", style: TextStyle(color: Color(0xFF003F9A), fontWeight: FontWeight.bold)),
                          TextSpan(text: " and "),
                          TextSpan(text: "Privacy Policy", style: TextStyle(color: Color(0xFF003F9A), fontWeight: FontWeight.bold)),
                          TextSpan(text: "."),
                        ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCard(String label, IconData iconData, Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 24, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}