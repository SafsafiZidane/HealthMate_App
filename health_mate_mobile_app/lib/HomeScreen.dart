import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class HealthHabitsInput {
  double sleepHours;
  int sleepQuality;
  double caffeineMg;
  double exerciseMin;
  double moodScore;
  int socialInteraction;
  double waterLiters;
  int mealRegularity;
  int junkFood;
  double workHours;
  double screenTimeH;
  int mindfulness;

  HealthHabitsInput({
    this.sleepHours = 7.0,
    this.sleepQuality = 2,
    this.caffeineMg = 100.0,
    this.exerciseMin = 30.0,
    this.moodScore = 6.0,
    this.socialInteraction = 1,
    this.waterLiters = 1.5,
    this.mealRegularity = 2,
    this.junkFood = 0,
    this.workHours = 8.0,
    this.screenTimeH = 4.0,
    this.mindfulness = 1,
  });

  Map<String, dynamic> toJson() => {
    'sleep_hours': sleepHours,
    'sleep_quality': sleepQuality,
    'caffeine_mg': caffeineMg,
    'exercise_min': exerciseMin,
    'mood_score': moodScore,
    'social_interaction': socialInteraction,
    'water_liters': waterLiters,
    'meal_regularity': mealRegularity,
    'junk_food': junkFood,
    'work_hours': workHours,
    'screen_time_h': screenTimeH,
    'mindfulness': mindfulness,
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instance de nos données locales pour le formulaire
  final HealthHabitsInput _currentHabits = HealthHabitsInput();

  double _stressScore = 0.0;
  String _stressLevel = "Calcul en cours...";
  bool _isLoading = false;

  // Fonction pour envoyer les données au backend FastAPI
  Future<void> _sendDataToBackend() async {
    setState(() => _isLoading = true);

    // Remplace par ton IP locale réseau (ex: 192.168.1.XX:8000) si tu es sur appareil réel
    const String url = "http://10.0.2.2:8000/predict";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer YOUR_TOKEN_HERE" // Décommente si ton get_current_user l'exige
        },
        body: jsonEncode(_currentHabits.toJson()),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _stressScore = result['predicted_stress_score'];
          _stressLevel = result['stress_level'];
        });
      } else {
        _showSnackBar("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Impossible de joindre le backend");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Ouvre la feuille modale du bas pour éditer les propriétés
  void _openEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet à la feuille de prendre plus de place
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder( // Permet de rafraîchir les curseurs à l'intérieur de la modal
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 5, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Mettre à jour mes habitudes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    // --- SLEEP HOURS ---
                    Text("Heures de sommeil : ${_currentHabits.sleepHours.toStringAsFixed(1)}h"),
                    Slider(
                      value: _currentHabits.sleepHours,
                      min: 2.0, max: 12.0, divisions: 20,
                      onChanged: (val) => setModalState(() => _currentHabits.sleepHours = val),
                    ),

                    // --- CAFFEINE ---
                    Text("Caféine : ${_currentHabits.caffeineMg.toInt()} mg"),
                    Slider(
                      value: _currentHabits.caffeineMg,
                      min: 0.0, max: 600.0, divisions: 12,
                      onChanged: (val) => setModalState(() => _currentHabits.caffeineMg = val),
                    ),

                    // --- WATER LITERS ---
                    Text("Eau consommée : ${_currentHabits.waterLiters.toStringAsFixed(1)} L"),
                    Slider(
                      value: _currentHabits.waterLiters,
                      min: 0.0, max: 4.0, divisions: 8,
                      onChanged: (val) => setModalState(() => _currentHabits.waterLiters = val),
                    ),

                    // --- WORK HOURS ---
                    Text("Heures de travail : ${_currentHabits.workHours.toStringAsFixed(1)}h"),
                    Slider(
                      value: _currentHabits.workHours,
                      min: 0.0, max: 16.0, divisions: 16,
                      onChanged: (val) => setModalState(() => _currentHabits.workHours = val),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        onPressed: () {
                          Navigator.pop(context); // Ferme le formulaire
                          _sendDataToBackend();   // Envoie au serveur FastAPI
                        },
                        child: const Text("Analyser mon niveau de stress", style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text("Tableau de Bord Wellness"), backgroundColor: Colors.white, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- CARD COMPOSANT PRINCIPAL (CERCLE SCORE) ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    const Text("Votre score de stress aujourd'hui", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140, height: 140,
                          child: CircularProgressIndicator(
                            value: _stressScore / 10, // Graduation sur 10 selon ton modèle
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        ),
                        Column(
                          children: [
                            Text("$_stressScore", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            Text(_stressLevel, style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- CARTES DE RÉSUMÉ SECONDAIRES ---
            _buildHabitRowTile(Icons.local_drink, "Eau", "${_currentHabits.waterLiters} / 4L", Colors.blue),
            _buildHabitRowTile(Icons.dark_mode, "Sommeil", "${_currentHabits.sleepHours}h / 12h", Colors.indigo),
            _buildHabitRowTile(Icons.work, "Travail", "${_currentHabits.workHours}h", Colors.orange),
          ],
        ),
      ),
      // --- LE BOUTON D'ÉDITION CIRCULAIRE (FAB) ---
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditModal,
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildHabitRowTile(IconData icon, String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}