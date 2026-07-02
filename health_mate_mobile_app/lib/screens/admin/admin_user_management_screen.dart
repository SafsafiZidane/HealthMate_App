import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class AdminUserManagementScreen extends StatefulWidget {
  final String roleFilter; // 'user' or 'doctor'
  const AdminUserManagementScreen({super.key, required this.roleFilter});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.roleFilter == 'doctor' ? '/admin/doctors' : '/admin/users?role=user';
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      final response = await _apiService.delete('/admin/users/$id');
      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Manage ${widget.roleFilter == 'doctor' ? 'Doctors' : 'Users'}", 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(user['username'][0].toUpperCase()),
                    ),
                    title: Text("${user['first_name']} ${user['last_name']}"),
                    subtitle: Text(user['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(user['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
