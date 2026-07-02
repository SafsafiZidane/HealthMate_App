import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  List<dynamic> conversations = [];
  List<dynamic> messages = [];

  bool get isLoading => _isLoading;

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/conversations');
      if (response.statusCode == 200) {
        conversations = jsonDecode(response.body);
      }
    } catch (e) {
      print("Fetch conversations error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/conversations/$conversationId/messages');
      if (response.statusCode == 200) {
        messages = jsonDecode(response.body);
      }
    } catch (e) {
      print("Fetch messages error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> sendMessage(String message, {int? conversation_id}) async {
    try {
      final response = await _apiService.post('/api/chat', {
        'message': message,
        'conversation_id': conversation_id,
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final newConvId = result['conversation_id'];
        
        // Refresh messages from backend to get both user and assistant response
        if (newConvId != null) {
          fetchMessages(newConvId);
        }
        return newConvId;
      }
    } catch (e) {
      print("Send message error: $e");
    }
    return null;
  }
}
