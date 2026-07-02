import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/health_provider.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final TextEditingController _heightController = TextEditingController(text: "175");
  final TextEditingController _weightController = TextEditingController(text: "70");
  final TextEditingController _ageController = TextEditingController(text: "25");
  
  String _goal = "lose";
  String _sex = "male";
  String _activityLevel = "moderate";

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Smart Health Plan", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInputForm(healthProvider),
            const SizedBox(height: 32),
            if (healthProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (healthProvider.bmiPlan != null)
              _buildPlanResults(healthProvider.bmiPlan!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0052CC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0052CC).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("AI Health Planner", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Get personalized diet and workout routines.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(HealthProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(_heightController, "Height (cm)", Icons.height_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_weightController, "Weight (kg)", Icons.monitor_weight_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_ageController, "Age", Icons.cake_rounded)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: _inputDecoration("Sex", Icons.person_outline),
                  items: const [
                    DropdownMenuItem(value: "male", child: Text("Male")),
                    DropdownMenuItem(value: "female", child: Text("Female")),
                  ],
                  onChanged: (val) => setState(() => _sex = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: _inputDecoration("Activity Level", Icons.directions_run_rounded),
            items: const [
              DropdownMenuItem(value: "sedentary", child: Text("Sedentary (Office job)")),
              DropdownMenuItem(value: "light", child: Text("Light Exercise")),
              DropdownMenuItem(value: "moderate", child: Text("Moderate Exercise")),
              DropdownMenuItem(value: "active", child: Text("Active (Daily sports)")),
              DropdownMenuItem(value: "very_active", child: Text("Very Active (Physical job)")),
            ],
            onChanged: (val) => setState(() => _activityLevel = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: _inputDecoration("Your Goal", Icons.flag_rounded),
            items: const [
              DropdownMenuItem(value: "lose", child: Text("Lose Weight")),
              DropdownMenuItem(value: "gain", child: Text("Gain Muscle")),
            ],
            onChanged: (val) => setState(() => _goal = val!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () {
                provider.getBmiPlan({
                  "height_cm": double.parse(_heightController.text),
                  "weight_kg": double.parse(_weightController.text),
                  "age": int.parse(_ageController.text),
                  "sex": _sex,
                  "activity_level": _activityLevel,
                  "goal": _goal,
                });
              },
              child: const Text("Generate My Plan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPlanResults(Map<String, dynamic> plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]
          ),
          child: Column(
            children: [
              const Text("BMI ANALYSIS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text("${plan['bmi']}", style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: _getBmiColor(plan['bmi_category']), borderRadius: BorderRadius.circular(20)),
                child: Text("${plan['bmi_category']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text("Ideal Weight Range: ${plan['target_weight_range_kg']} kg", style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildPlanSection("Nutrition Strategy", Icons.restaurant_rounded, Colors.orange, plan['nutrition_plan']),
        const SizedBox(height: 24),
        _buildPlanSection("Exercise Protocol", Icons.fitness_center_rounded, Colors.green, plan['exercise_plan']),
        const SizedBox(height: 24),
        _buildPlanSection("Daily Tips", Icons.tips_and_updates_rounded, Colors.amber, plan['recommendations']),
      ],
    );
  }

  Color _getBmiColor(String category) {
    switch (category.toLowerCase()) {
      case 'normal': return Colors.green;
      case 'overweight': return Colors.orange;
      case 'obese': return Colors.red;
      default: return Colors.blue;
    }
  }

  Widget _buildPlanSection(String title, IconData icon, Color color, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, size: 18, color: color),
              const SizedBox(width: 14),
              Expanded(child: Text(item, style: const TextStyle(color: Color(0xFF334155), height: 1.5, fontSize: 14))),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
