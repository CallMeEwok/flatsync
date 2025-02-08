import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/shopping_list_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService();
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

  /// ✅ Adds an item & sends notification
  void _addItem(String name) async {
    if (name.trim().isEmpty || _shoppingList == null || _householdId == null) return;

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

      // ✅ Send Notification
      await _shoppingListService.sendNotification(
        householdId: _householdId!,
        title: "🛒 New Shopping Item Added",
        message: "$formattedName has been added to the shopping list.",
      );
    } catch (e) {
      debugPrint("❌ Error adding item: $e");
    }
  }

  /// ✅ Deletes an item & sends notification
  void _deleteItem(String id, String itemName) async {
    if (_shoppingList == null || _householdId == null) return;

    try {
      await _shoppingList!.doc(id).delete();

      // ✅ Send Notification
      await _shoppingListService.sendNotification(
        householdId: _householdId!,
        title: "🗑️ Item Removed",
        message: "$itemName has been removed from the shopping list.",
      );
    } catch (e) {
      debugPrint("❌ Error deleting item: $e");
    }
  }

  /// ✅ Toggles completed status & sends notification
  void _toggleCompleted(String id, bool currentValue, String itemName) async {
    if (_shoppingList == null || _householdId == null) return;

    try {
      await _shoppingList!.doc(id).update({'completed': !currentValue});

      // ✅ Send Notification
      await _shoppingListService.sendNotification(
        householdId: _householdId!,
        title: "✅ Item Completed",
        message: "$itemName has been marked as completed.",
      );
    } catch (e) {
      debugPrint("❌ Error toggling completion status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: _shoppingList == null
          ? const Center(child: CircularProgressIndicator())
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
                          onSubmitted: (text) => _addItem(text),
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
                                  onPressed: () => _toggleCompleted(item.id, isCompleted, itemName),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteItem(item.id, itemName),
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
