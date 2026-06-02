import 'package:flutter/material.dart';
import 'package:health_mate_mobile_app/auth_screen.dart';

class OnboardingRoot extends StatefulWidget {
  const OnboardingRoot({super.key});

  @override
  State<OnboardingRoot> createState() => _OnboardingRootState();
}

class _OnboardingRootState extends State<OnboardingRoot> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBF2FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: Stack(
          children: [
            // Page Viewer holding our 2 screens
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildScreenOne(),
                _buildScreenTwo(),
              ],
            ),

            // Bottom Navigation Overlay (Dots indicator & Main Button)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? const Color(0xFF003F9A) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),

                  // Standardised Navigation Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == 0) {
                        _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003F9A),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 0 ? "Get Started" : "Next Step",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_currentPage == 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 1: SPLASH INTRO
  // ==========================================
  Widget _buildScreenOne() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo Graphic Wrapper
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
                color: const Color(0xFF0052CC),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: const Color(0xFF0052CC).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: const Icon(Icons.add_moderator_rounded, size: 64, color: Colors.white), // Standard Material Medical alternative to image
          ),
          const SizedBox(height: 40),
          const Text(
            "HealthMate 2.0",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003F9A)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Your journey to a healthier, more\nbalanced life begins here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 60),
          // Lower Subtitle tag
          const Text(
            "• YOUR AI-POWERED HEALTH COMPANION •",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0E7490), letterSpacing: 0.5),
          ),
          const SizedBox(height: 80), // Creates spacing cushion for layout stack components
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 2: METRIC REPORT CARDS & DETAILS
  // ==========================================
  Widget _buildScreenTwo() {
    return Stack(
      children: [
        // Skip Button position
        Positioned(
          top: 60,
          right: 24,
          child: TextButton(
            onPressed: _completeOnboarding,
            child: const Text("Skip", style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Interface Container Mock
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Daily Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF003F9A), size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mock Metric Bar 1
                    _buildMockProgressBar(Colors.teal, 0.75, Icons.favorite_border),
                    const SizedBox(height: 12),
                    // Mock Metric Bar 2
                    _buildMockProgressBar(Colors.green, 0.45, Icons.directions_run_rounded),
                    const SizedBox(height: 20),
                    // AI Segment Capsule
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("AI Insight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF312E81))),
                          SizedBox(height: 4),
                          Text(
                            "Heart rate variability is optimal. Recovery looks excellent for today's session.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF3730A3), height: 1.4),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                "AI Health Tracking",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              const Text(
                "Experience medical-grade health reports powered by advanced AI. We monitor your vitals with clinical precision.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 100), // Spacing cushion allocation
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMockProgressBar(Color color, double progressWidthFactor, IconData icon) {
    return Row(
      children: [
        CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Expanded(flex: (progressWidthFactor * 100).toInt(), child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)))),
                Expanded(flex: ((1 - progressWidthFactor) * 100).toInt(), child: const SizedBox()),
              ],
            ),
          ),
        )
      ],
    );
  }
}