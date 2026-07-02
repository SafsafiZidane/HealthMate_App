import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _role;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  String? get token => _token;
  String? get role => _role;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    if (_token != null) {
      fetchProfile();
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.get('/me');
      if (response.statusCode == 200) {
        _userData = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print("Profile fetch error: $e");
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        _token = data['result']['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        // Determine role
        _role = await _determineRole();
        await prefs.setString('role', _role!);
        
        // Fetch full profile immediately
        await fetchProfile();

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': data['message'], 'role': _role};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> register(String firstName, String lastName, String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/register', {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<String> _determineRole() async {
    try {
      // We check admin first
      final adminCheck = await _apiService.get('/admin/statistics');
      if (adminCheck.statusCode == 200) return 'admin';
      
      // Then check doctor
      final docCheck = await _apiService.get('/api/consultations/doctor/inbox');
      if (docCheck.statusCode == 200) return 'doctor';
    } catch (_) {}
    return 'user';
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    notifyListeners();
  }
}
