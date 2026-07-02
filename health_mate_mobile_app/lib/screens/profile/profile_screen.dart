import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => auth.fetchProfile(),
          )
        ],
      ),
      body: auth.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => auth.fetchProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(auth, user),
                    const SizedBox(height: 30),
                    _buildInfoSection(user),
                    const SizedBox(height: 30),
                    _buildActions(context, auth),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth, Map<String, dynamic>? user) {
    String initials = "U";
    String displayName = "User";
    
    if (user != null) {
      String firstName = user['first_name'] ?? "";
      String lastName = user['last_name'] ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        displayName = "$firstName $lastName".trim();
        initials = (firstName.isNotEmpty ? firstName[0] : "") + (lastName.isNotEmpty ? lastName[0] : "");
      } else {
        displayName = user['username'] ?? "User";
        initials = displayName[0].toUpperCase();
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0052CC), width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(auth.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            auth.role?.toUpperCase() ?? "USER",
            style: TextStyle(color: _getRoleColor(auth.role), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin': return Colors.redAccent;
      case 'doctor': return const Color(0xFF0D9488);
      default: return const Color(0xFF0052CC);
    }
  }

  Widget _buildInfoSection(Map<String, dynamic>? user) {
    if (user == null) {
      return const Center(child: Text("Unable to load user details"));
    }

    String joinedDate = "N/A";
    if (user['created_at'] != null) {
      try {
        DateTime dt = DateTime.parse(user['created_at']);
        joinedDate = DateFormat('MMMM yyyy').format(dt);
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.alternate_email_rounded, "Username", user['username'] ?? "N/A"),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.email_outlined, "Email Address", user['email'] ?? "N/A"),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.person_outline_rounded, "Full Name", 
              "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim().isEmpty ? "Not set" : "${user['first_name']} ${user['last_name']}"),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.calendar_today_rounded, "Member Since", joinedDate),
          if (user['role'] == 'doctor' && user['doctor_profile'] != null) ...[
            const Divider(height: 32, color: Color(0xFFF1F5F9)),
            _buildInfoRow(Icons.medical_services_outlined, "Specialty", user['doctor_profile']['specialty'] ?? "N/A"),
            const Divider(height: 32, color: Color(0xFFF1F5F9)),
            _buildInfoRow(Icons.history_edu_rounded, "Experience", "${user['doctor_profile']['experience_years']} Years"),
            const Divider(height: 32, color: Color(0xFFF1F5F9)),
            _buildInfoRow(Icons.location_on_outlined, "Clinic", user['doctor_profile']['clinic_address'] ?? "N/A"),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                auth.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                foregroundColor: const Color(0xFFE11D48),
                side: const BorderSide(color: Color(0xFFFECDD3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 12),
                  Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
