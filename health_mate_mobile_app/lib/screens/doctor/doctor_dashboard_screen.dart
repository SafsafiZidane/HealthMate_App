import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import '../profile/profile_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/api/consultations/doctor/inbox');
      if (response.statusCode == 200) {
        setState(() {
          _consultations = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _replyToConsultation(int id, String reply) async {
    try {
      final response = await _apiService.post('/api/consultations/$id/reply', {
        'doctor_reply': reply,
      });
      if (response.statusCode == 200) {
        _fetchInbox();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Advice sent successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Medical Hub", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchInbox),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorStats(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text("Pending Patient Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
                Expanded(
                  child: _consultations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _consultations.length,
                          itemBuilder: (context, index) {
                            return _buildConsultationCard(_consultations[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorStats() {
    final pendingCount = _consultations.where((c) => c['status'] == 'pending').length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Doctor's Workspace", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text("You have $pendingCount new", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)),
          const Text("Consultation Requests", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("All caught up!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("No pending requests from patients.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> item) {
    final bool isReplied = item['status'] == 'replied';
    final user = item['user'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isReplied ? Colors.green[50] : const Color(0xFFF1F5F9),
          child: Icon(isReplied ? Icons.verified_user : Icons.pending, color: isReplied ? Colors.green : Colors.orange, size: 20),
        ),
        title: Text(user != null ? "${user['first_name']} ${user['last_name']}" : "Patient #${item['user_id']}", 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Requested on ${item['created_at'].toString().split('T')[0]}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("CONDITION DESCRIPTION"),
                const SizedBox(height: 8),
                Text(item['condition_description'], style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF334155))),
                const SizedBox(height: 20),
                if (isReplied) ...[
                  _buildLabel("YOUR PREVIOUS ADVICE"),
                  const SizedBox(height: 8),
                  Text(item['doctor_reply'], style: const TextStyle(fontSize: 15, color: Color(0xFF0D9488), fontWeight: FontWeight.w500)),
                ] else
                  _buildReplyInput(item['id']),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1));
  }

  Widget _buildReplyInput(int id) {
    final controller = TextEditingController();
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Enter your medical advice and recommendations...",
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _replyToConsultation(id, controller.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Submit Advice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}
