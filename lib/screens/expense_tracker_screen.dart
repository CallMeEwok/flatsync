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
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _splitBetweenController = TextEditingController();

  void _addExpense() async {
    if (_expenseNameController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _paidByController.text.isNotEmpty &&
        _splitBetweenController.text.isNotEmpty) {
      try {
        await _expenseService.addExpense(
          name: _expenseNameController.text.trim(),
          amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
          paidBy: _paidByController.text.trim(),
          splitBetween: _splitBetweenController.text
              .trim()
              .split(',')
              .map((name) => name.trim())
              .toList(),
        );
        _expenseNameController.clear();
        _amountController.clear();
        _paidByController.clear();
        _splitBetweenController.clear();

        if (!mounted) return; // ✅ Fix: Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!')),
        );
      } catch (e) {
        if (!mounted) return; // ✅ Fix: Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: $e')),
        );
      }
    } else {
      if (!mounted) return; // ✅ Fix: Check if widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
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

                    // ✅ Fix: Use null-safe values with defaults
                    final String name = expense['name'] ?? 'Unknown Expense';
                    final double amount =
                        (expense['amount'] as num?)?.toDouble() ?? 0.0;
                    final String paidBy = expense['paidBy'] ?? 'Unknown';
                    final List<String> splitBetween =
                        (expense['splitBetween'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                    final bool isPaid = expense['paid'] ?? false;

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                          'Paid by: $paidBy\nAmount: \$${amount.toStringAsFixed(2)}\nSplit between: ${splitBetween.join(', ')}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isPaid,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                _expenseService
                                    .markAsPaid(expense['id'], newValue);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _expenseService.deleteExpense(expense['id']),
                          ),
                        ],
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
