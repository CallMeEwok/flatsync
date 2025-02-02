import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBoardScreen extends StatefulWidget {
  const MessageBoardScreen({super.key});

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  final List<Map<String, String>> _messages = []; // List of messages
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  void _postMessage() {
  if (_messageController.text.trim().isNotEmpty && _authorController.text.trim().isNotEmpty) {
    setState(() {
      _messages.add({
        'message': _messageController.text.trim(),
        'author': _authorController.text.trim(),
        'timestamp': DateFormat('yMMMd H:m').format(DateTime.now()), // Ensure a valid timestamp
      });
      _messageController.clear();
      _authorController.clear();
      _messages.sort((a, b) => b['timestamp']!.compareTo(a['timestamp']!));
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter both a message and an author.'),
      ),
    );
  }
}

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Your Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _postMessage,
                  child: const Text('Post Message'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Be the first to post!',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(message['message'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('— ${message['author']}'),
                              Text(
                                message['timestamp'] ?? '', // Display the timestamp
                                style: const TextStyle(fontSize: 12, color: Colors.grey), // Style it smaller and lighter
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMessage(index),
                          ),
                        ),
                      );
                    },
                  )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _messages.clear();
          });
        },
        tooltip: 'Clear All Messages',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
