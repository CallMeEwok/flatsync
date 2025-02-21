import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Import for date formatting
import '../services/chore_service.dart';
import '../services/household_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final ChoreService _choreService = ChoreService();
  final HouseholdService _householdService = HouseholdService();
  final TextEditingController _taskController = TextEditingController();

  String? _selectedAssigneeUid;
  List<Map<String, String>> _householdMembers = [];
  DateTime? _selectedDueDate; // ✅ Store selected due date

  @override
  void initState() {
    super.initState();
    _fetchHouseholdMembers();
  }

  void _fetchHouseholdMembers() async {
    final members = await _householdService.getHouseholdMembers();
    setState(() {
      _householdMembers = members;
    });
  }

  /// ✅ Opens a Date Picker for selecting due date
  void _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // ✅ Up to 1 year ahead
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  /// ✅ Adds a new chore with a due date
  void _addChore() async {
    if (_taskController.text.isNotEmpty && _selectedAssigneeUid != null && _selectedDueDate != null) {
      try {
        await _choreService.addChore(
          task: _taskController.text.trim(),
          assigneeUid: _selectedAssigneeUid!,
          dueDate: _selectedDueDate!, // ✅ Send due date to Firestore
        );
        _taskController.clear();
        setState(() {
          _selectedAssigneeUid = null;
          _selectedDueDate = null; // ✅ Reset due date after adding
        });

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
        const SnackBar(content: Text('Please enter a task, assignee, and due date.')),
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
                DropdownButtonFormField<String>(
                  value: _selectedAssigneeUid,
                  hint: const Text('Assign to'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _householdMembers.map((member) {
                    return DropdownMenuItem(
                      value: member['uid'],
                      child: Text(member['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAssigneeUid = newValue;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // ✅ Due Date Picker
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDueDate == null
                            ? 'No due date selected'
                            : 'Due: ${DateFormat.yMMMd().format(_selectedDueDate!)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDueDate(context),
                    ),
                  ],
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
                    final String assignee = chore['assignedToName'] ?? 'Unknown';
                    final bool completed = chore['completed'] ?? false;
                    final Timestamp? dueTimestamp = chore['dueDate'];
                    final DateTime? dueDate = dueTimestamp?.toDate();
                    
                    final bool isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

                    return ListTile(
                      title: Text(
                        task,
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.black, // ✅ Red for overdue
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Assigned to: $assignee\nDue: ${dueDate != null ? DateFormat.yMMMd().format(dueDate) : "No due date"}'
                        '${isOverdue ? " (Overdue!)" : ""}', // ✅ Add "Overdue!" label
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.black,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
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