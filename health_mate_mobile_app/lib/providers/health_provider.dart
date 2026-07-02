import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HealthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  double stressScore = 0.0;
  String stressLevel = "N/A";

  Map<String, dynamic>? bmiPlan;

  bool get isLoading => _isLoading;

  Future<void> predictStress(Map<String, dynamic> habits) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/predict', habits);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        stressScore = data['predicted_stress_score'];
        stressLevel = data['stress_level'];
      }
    } catch (e) {
      print("Stress prediction error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getBmiPlan(Map<String, dynamic> planInput) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/bmi-plan', planInput);
      if (response.statusCode == 200) {
        bmiPlan = jsonDecode(response.body);
      }
    } catch (e) {
      print("BMI plan error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
