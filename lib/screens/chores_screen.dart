import 'package:flutter/material.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final List<Map<String, String>> _chores = []; // List of chores (task + assignee)
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();

  void _addChore() {
    if (_taskController.text.trim().isNotEmpty && _assigneeController.text.trim().isNotEmpty) {
      setState(() {
        _chores.add({
          'task': _taskController.text.trim(),
          'assignee': _assigneeController.text.trim(),
        });
        _taskController.clear();
        _assigneeController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both a task and an assignee.'),
        ),
      );
    }
  }

  void _removeChore(int index) {
    setState(() {
      _chores.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Chores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'Chore',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _assigneeController,
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addChore,
                  child: const Text('Add Chore'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _chores.isEmpty
                ? const Center(
                    child: Text(
                      'No chores yet. Add some tasks!',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chores.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_chores[index]['task'] ?? ''),
                        subtitle: Text('Assigned to: ${_chores[index]['assignee']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeChore(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _chores.clear();
          });
        },
        tooltip: 'Clear All Chores',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
