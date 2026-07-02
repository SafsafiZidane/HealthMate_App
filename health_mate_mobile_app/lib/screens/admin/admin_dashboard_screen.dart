import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'admin_user_management_screen.dart';
import 'admin_create_doctor_screen.dart';
import '../profile/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/admin/statistics');
      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Admin Command Center", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchStats),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  const Text("System Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildStatCard("Total Users", _stats?['total_users']?.toString() ?? "0", Icons.people, Colors.blue),
                      _buildStatCard("Doctors", _stats?['doctors']?.toString() ?? "0", Icons.medical_services, Colors.teal),
                      _buildStatCard("Consultations", _stats?['total_consultations']?.toString() ?? "0", Icons.assignment, Colors.orange),
                      _buildStatCard("Stress Avg", "${_stats?['average_stress_score'] ?? '0.0'}", Icons.psychology, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Recent Users"),
                  const SizedBox(height: 16),
                  ...(_stats?['latest_users'] as List? ?? []).map((user) => _buildUserTile(user)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                "Manage Users", 
                Icons.person_search, 
                const Color(0xFF0052CC),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserManagementScreen(roleFilter: 'user')))
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionBtn(
                "Manage Doctors", 
                Icons.local_hospital, 
                const Color(0xFF0D9488),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserManagementScreen(roleFilter: 'doctor')))
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionBtn(
            "Register New Doctor", 
            Icons.add_moderator_outlined, 
            const Color(0xFF0F766E),
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateDoctorScreen()))
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF1F5F9),
          child: Text(user['username'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user['email']),
        trailing: Text(user['role'].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: user['role'] == 'admin' ? Colors.red : Colors.blue)),
      ),
    );
  }
}
