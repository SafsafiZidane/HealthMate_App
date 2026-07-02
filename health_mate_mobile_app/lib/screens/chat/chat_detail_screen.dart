import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final int? conversationId;
  const ChatDetailScreen({super.key, this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _activeConversationId;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    if (_activeConversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ChatProvider>(context, listen: false).fetchMessages(_activeConversationId!);
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Optimistic addition of user message to UI
    setState(() {
      chatProvider.messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    final newConvId = await chatProvider.sendMessage(text, conversation_id: _activeConversationId);
    
    if (_activeConversationId == null && newConvId != null) {
      setState(() {
        _activeConversationId = newConvId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Health Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_activeConversationId == null ? "New Chat" : "Conversation #$_activeConversationId", 
                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading && _activeConversationId != null && chatProvider.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              reverse: true,
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final msg = chatProvider.messages[chatProvider.messages.length - 1 - index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content'], isUser, msg['created_at']);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, String timestamp) {
    DateTime time = DateTime.parse(timestamp);
    String formattedTime = DateFormat('HH:mm').format(time);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0052CC) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1E293B), fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: TextStyle(color: isUser ? Colors.white70 : Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFF0052CC),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
