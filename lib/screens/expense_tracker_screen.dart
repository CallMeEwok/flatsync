import 'package:flutter/material.dart';
import '../services/expense_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> _householdMembers = [];
  final Map<String, double> _selectedSplit = {}; // Stores selected users and their share %

  @override
  void initState() {
    super.initState();
    _loadHouseholdMembers();
  }

  Future<void> _loadHouseholdMembers() async {
    final members = await _expenseService.getHouseholdMembers();
    setState(() {
      _householdMembers = members;
    });
  }

  void _addExpense() async {
    if (_expenseNameController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedSplit.isNotEmpty) {
      try {
        await _expenseService.addExpense(
          name: _expenseNameController.text.trim(),
          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
          splitBetween: _selectedSplit.entries
              .map((entry) => {'uid': entry.key, 'share': entry.value})
              .toList(),
        );
        _expenseNameController.clear();
        _amountController.clear();
        setState(() {
          _selectedSplit.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Expense Tracker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _expenseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSplitDropdown(),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addExpense,
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No expenses recorded yet.',
                        style: TextStyle(fontSize: 16)),
                  );
                }
                final expenses = snapshot.data!;
                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];

                    final String name = expense['name'] ?? 'Unknown Expense';
                    final double amount =
                        (expense['amount'] as num?)?.toDouble() ?? 0.0;
                    final List<dynamic> splitBetween =
                        expense['splitBetween'] ?? [];

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'Amount: \$${amount.toStringAsFixed(2)}\nSplit: ${splitBetween.map((s) => '${s['name']}: ${s['share']}%').join(', ')}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _expenseService.deleteExpense(expense['id']),
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

  Widget _buildSplitDropdown() {
    return Column(
      children: _householdMembers.map((member) {
        return CheckboxListTile(
          title: Text(member['name']),
          value: _selectedSplit.containsKey(member['uid']),
          onChanged: (bool? isSelected) {
            setState(() {
              if (isSelected == true) {
                _selectedSplit[member['uid']] = 50.0; // Default split (to be changed manually)
              } else {
                _selectedSplit.remove(member['uid']);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
