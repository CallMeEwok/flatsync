import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  String? _householdId;
  CollectionReference? _shoppingList;

  @override
  void initState() {
    super.initState();
    _fetchHouseholdId();
  }

  Future<void> _fetchHouseholdId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists || !userDoc.data()!.containsKey('householdId')) {
        debugPrint("⚠️ No household ID found for user.");
        return;
      }

      setState(() {
        _householdId = userDoc['householdId'];
        _shoppingList = FirebaseFirestore.instance
            .collection('households')
            .doc(_householdId)
            .collection('shoppingList');
      });

      debugPrint("✅ Household ID found: $_householdId");
    } catch (e) {
      debugPrint("❌ Error fetching household ID: $e");
    }
  }

  void _addItem(String name) async {
    if (name.trim().isEmpty || _shoppingList == null) return;

    String formattedName = name.trim().toLowerCase();

    try {
      final existingItems = await _shoppingList!.where("name", isEqualTo: formattedName).get();
      if (existingItems.docs.isNotEmpty) {
        debugPrint("⚠️ Item '$name' already exists.");
        return;
      }

      await _shoppingList!.add({
        'name': formattedName,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemController.clear();
    } catch (e) {
      debugPrint("❌ Error adding item: $e");
    }
  }

  void _deleteItem(String id) async {
    if (_shoppingList == null) return;

    try {
      await _shoppingList!.doc(id).delete();
    } catch (e) {
      debugPrint("❌ Error deleting item: $e");
    }
  }

  void _toggleCompleted(String id, bool currentValue) async {
    if (_shoppingList == null) return;

    try {
      await _shoppingList!.doc(id).update({'completed': !currentValue});
    } catch (e) {
      debugPrint("❌ Error toggling completion status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: _shoppingList == null
          ? const Center(child: CircularProgressIndicator()) // ✅ Prevents accessing before initialized
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          decoration: const InputDecoration(
                            labelText: 'Add an item',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (text) => _addItem(text), // ✅ Fix: Call _addItem properly
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addItem(_itemController.text),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _shoppingList!.orderBy("createdAt", descending: false).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No items in the shopping list'));
                      }

                      final items = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final itemName = item['name'] ?? "Unknown Item";
                          final isCompleted = item['completed'] ?? false;
                          
                          // ✅ Fix: Ensure `createdAt` is safely converted
                          Timestamp? createdAtTimestamp = item['createdAt'] as Timestamp?;
                          DateTime createdAt = createdAtTimestamp?.toDate() ?? DateTime.now();

                          return ListTile(
                            title: Text(
                              itemName,
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            subtitle: Text("Added: ${createdAt.toLocal()}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                  ),
                                  onPressed: () => _toggleCompleted(item.id, isCompleted),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteItem(item.id),
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
