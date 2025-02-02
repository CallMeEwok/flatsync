import 'package:flutter/material.dart';
import '../services/chore_service.dart'; // ✅ Ensure this file exists!

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final ChoreService _choreService = ChoreService();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();

  void _addChore() async {
    if (_taskController.text.isNotEmpty && _assigneeController.text.isNotEmpty) {
      try {
        await _choreService.addChore(
          task: _taskController.text.trim(),
          assignee: _assigneeController.text.trim(),
        );
        _taskController.clear();
        _assigneeController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chore added successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding chore: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a task and an assignee.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household Chores')),
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _choreService.getChores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No chores yet. Add some tasks!',
                        style: TextStyle(fontSize: 16)),
                  );
                }
                final chores = snapshot.data!;
                return ListView.builder(
                  itemCount: chores.length,
                  itemBuilder: (context, index) {
                    final chore = chores[index];

                    final String task = chore['task'] ?? 'Unknown Task';
                    final String assignee = chore['assignee'] ?? 'Unknown';
                    final bool completed = chore['completed'] ?? false;

                    return ListTile(
                      title: Text(task),
                      subtitle: Text('Assigned to: $assignee'),
                      leading: Checkbox(
                        value: completed,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            _choreService.toggleChoreCompletion(chore['id'], newValue);
                          }
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _choreService.deleteChore(chore['id']),
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
