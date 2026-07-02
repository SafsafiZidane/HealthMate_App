import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000"; // For Android Emulator

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers,
    );
  }
}
