import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/health_provider.dart';
import 'providers/auth_provider.dart';
import 'models/health_habits.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthHabitsInput _currentHabits = HealthHabitsInput();

  void _sendDataToBackend() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    await healthProvider.predictStress(_currentHabits.toJson());
  }

  void _openEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 24, right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50, height: 5,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Daily Wellness Log",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const Text("Update your habits to analyze stress levels", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),

                    _buildSliderLabel("Sleep Hours", "${_currentHabits.sleepHours.toStringAsFixed(1)}h"),
                    Slider(
                      value: _currentHabits.sleepHours,
                      min: 2.0, max: 12.0, divisions: 20,
                      activeColor: const Color(0xFF0052CC),
                      onChanged: (val) => setModalState(() => _currentHabits.sleepHours = val),
                    ),

                    _buildSliderLabel("Caffeine", "${_currentHabits.caffeineMg.toInt()} mg"),
                    Slider(
                      value: _currentHabits.caffeineMg,
                      min: 0.0, max: 600.0, divisions: 12,
                      activeColor: const Color(0xFF0052CC),
                      onChanged: (val) => setModalState(() => _currentHabits.caffeineMg = val),
                    ),

                    _buildSliderLabel("Water Intake", "${_currentHabits.waterLiters.toStringAsFixed(1)} L"),
                    Slider(
                      value: _currentHabits.waterLiters,
                      min: 0.0, max: 4.0, divisions: 8,
                      activeColor: const Color(0xFF0052CC),
                      onChanged: (val) => setModalState(() => _currentHabits.waterLiters = val),
                    ),

                    _buildSliderLabel("Work Hours", "${_currentHabits.workHours.toStringAsFixed(1)} h"),
                    Slider(
                      value: _currentHabits.workHours,
                      min: 0.0, max: 16.0, divisions: 16,
                      activeColor: const Color(0xFF0052CC),
                      onChanged: (val) => setModalState(() => _currentHabits.workHours = val),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052CC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _sendDataToBackend();
                        },
                        child: const Text("Analyze Wellness", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Wellness Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          )
        ],
      ),
      body: healthProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hello,", style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
            const Text("Wellness Tracker", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 24),
            
            // --- MAIN SCORE CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052CC), Color(0xFF003F9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0052CC).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                children: [
                  const Text("Today's Stress Level", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160, height: 160,
                        child: CircularProgressIndicator(
                          value: healthProvider.stressScore / 10,
                          strokeWidth: 14,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          Text("${healthProvider.stressScore}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(healthProvider.stressLevel.toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text("Habit Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryTile(Icons.local_drink_rounded, "Water", "${_currentHabits.waterLiters}L", Colors.blue),
                _buildSummaryTile(Icons.bed_rounded, "Sleep", "${_currentHabits.sleepHours}h", Colors.indigo),
                _buildSummaryTile(Icons.work_rounded, "Work", "${_currentHabits.workHours}h", Colors.orange),
                _buildSummaryTile(Icons.coffee_rounded, "Caffeine", "${_currentHabits.caffeineMg.toInt()}mg", Colors.brown),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditModal,
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text("Log Today", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryTile(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          )
        ],
      ),
    );
  }
}
