import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Conversations IA")),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: chatProvider.conversations.length,
        itemBuilder: (context, index) {
          final conv = chatProvider.conversations[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.chat)),
            title: Text("Conversation #${conv['id']}"),
            subtitle: Text("Créée le ${conv['created_at'].toString().split('T')[0]}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(conversationId: conv['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatDetailScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}
