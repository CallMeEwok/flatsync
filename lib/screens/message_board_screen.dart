import 'package:flutter/material.dart';
import '../services/message_service.dart';

class MessageBoardScreen extends StatefulWidget {
  const MessageBoardScreen({super.key});

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        await _messageService.sendMessage(content: _messageController.text.trim());
        _messageController.clear();

        if (!mounted) return; // ✅ Fix: Ensure widget is still mounted before using context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
      } catch (e) {
        if (!mounted) return; // ✅ Fix: Prevent using context if widget is unmounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Board')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _sendMessage,
            child: const Text('Post Message'),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageService.getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ListTile(
                      title: Text(msg['content']),
                      subtitle: Text('— ${msg['senderName']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _messageService.deleteMessage(msg['id']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
