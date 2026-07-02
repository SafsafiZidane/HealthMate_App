import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConsultationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  List<dynamic> doctors = [];
  List<dynamic> myConsultations = [];

  bool get isLoading => _isLoading;

  Future<void> fetchDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/consultations/doctors');
      if (response.statusCode == 200) {
        doctors = jsonDecode(response.body);
      }
    } catch (e) {
      print("Fetch doctors error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyConsultations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/consultations/mine');
      if (response.statusCode == 200) {
        myConsultations = jsonDecode(response.body);
      }
    } catch (e) {
      print("Fetch consultations error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestConsultation(int doctorId, String description) async {
    try {
      final response = await _apiService.post('/api/consultations', {
        'doctor_id': doctorId,
        'condition_description': description,
      });
      if (response.statusCode == 200) {
        fetchMyConsultations();
        return true;
      }
    } catch (e) {
      print("Request consultation error: $e");
    }
    return false;
  }
}
