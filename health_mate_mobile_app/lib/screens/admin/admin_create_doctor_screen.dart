import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class AdminCreateDoctorScreen extends StatefulWidget {
  const AdminCreateDoctorScreen({super.key});

  @override
  State<AdminCreateDoctorScreen> createState() => _AdminCreateDoctorScreenState();
}

class _AdminCreateDoctorScreenState extends State<AdminCreateDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _clinicController = TextEditingController();
  final _bioController = TextEditingController();

  Future<void> _createDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "role": "doctor",
      "doctor_profile": {
        "specialty": _specialtyController.text.trim(),
        "experience_years": int.parse(_experienceController.text.trim()),
        "clinic_address": _clinicController.text.trim(),
        "bio": _bioController.text.trim(),
      }
    };

    try {
      final response = await _apiService.post('/admin/users', payload);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor created successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Error creating doctor"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Add New Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Personal Information"),
              const SizedBox(height: 16),
              _buildTextField(_firstNameController, "First Name", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_lastNameController, "Last Name", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_usernameController, "Username", Icons.alternate_email),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, "Password", Icons.lock_outline, obscureText: true),
              
              const SizedBox(height: 32),
              _buildSectionTitle("Professional Profile"),
              const SizedBox(height: 16),
              _buildTextField(_specialtyController, "Specialty (e.g. Cardiology)", Icons.medical_services_outlined),
              const SizedBox(height: 16),
              _buildTextField(_experienceController, "Years of Experience", Icons.history_toggle_off_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_clinicController, "Clinic Address", Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildTextField(_bioController, "Short Bio", Icons.description_outlined, maxLines: 3),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Doctor Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool obscureText = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? "Required field" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }
}
