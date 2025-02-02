import 'package:flutter/material.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final List<Map<String, dynamic>> _expenses = []; // List of expenses
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _splitBetweenController = TextEditingController();

  void _addExpense() {
    if (_expenseNameController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _paidByController.text.isNotEmpty &&
        _splitBetweenController.text.isNotEmpty) {
      setState(() {
        _expenses.add({
          'name': _expenseNameController.text.trim(),
          'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
          'paidBy': _paidByController.text.trim(),
          'splitBetween': _splitBetweenController.text
              .trim()
              .split(',') // Split by commas for multiple names
              .map((name) => name.trim())
              .toList(),
        });
        _expenseNameController.clear();
        _amountController.clear();
        _paidByController.clear();
        _splitBetweenController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
    }
  }

  void _removeExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Expense Tracker'),
      ),
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
                TextField(
                  controller: _paidByController,
                  decoration: const InputDecoration(
                    labelText: 'Paid By',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _splitBetweenController,
                  decoration: const InputDecoration(
                    labelText: 'Split Between (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addExpense,
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(
                    child: Text(
                      'No expenses recorded yet.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return ListTile(
                        title: Text(expense['name']),
                        subtitle: Text(
                            'Paid by: ${expense['paidBy']}\nAmount: \$${expense['amount'].toStringAsFixed(2)}\nSplit between: ${expense['splitBetween'].join(', ')}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeExpense(index),
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
            _expenses.clear();
          });
        },
        tooltip: 'Clear All Expenses',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
