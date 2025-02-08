// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves the household ID of the current user
  Future<String?> getHouseholdId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['householdId'];
  }

  /// Retrieves the current user's name from Firestore
  Future<String> getUserName(String uid) async {
    if (uid.isEmpty) return "Unknown User"; // ✅ Handle empty UIDs early

    print("🔍 Fetching name for UID: $uid"); // ✅ Debugging log

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      print("❌ No user found for UID: $uid");
      return "Unknown User";
    }

    final userData = userDoc.data();
    if (userData == null || userData['name'] == null) {
      print("⚠️ User data is null for UID: $uid");
      return "Unknown User";
    }

    print("✅ Found user: ${userData['name']}");
    return userData['name'];
  }

  /// Retrieves all household members (for dropdown selection)
  Future<List<Map<String, dynamic>>> getHouseholdMembers() async {
    final householdId = await getHouseholdId();
    if (householdId == null) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .where('householdId', isEqualTo: householdId)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'uid': doc.id,
              'name': doc.data()['name'] ?? 'Unknown User',
            })
        .toList();
  }

  /// Adds a new expense to Firestore under the correct household
  Future<void> addExpense({
    required String name,
    required double amount,
    required List<Map<String, dynamic>> splitBetween,
  }) async {
    final householdId = await getHouseholdId();
    if (householdId == null) {
      throw Exception("Household ID not found.");
    }

    await _firestore.collection('households')
        .doc(householdId)
        .collection('expenses')
        .add({
      'name': name,
      'amount': amount,
      'splitBetween': splitBetween,
      'date': FieldValue.serverTimestamp(),
      'paid': false,
    });
  }

  /// Fetches all expenses for the current user's household
  Stream<List<Map<String, dynamic>>> getExpenses() async* {
    final householdId = await getHouseholdId();
    if (householdId == null) yield [];

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((doc) async {
        final expense = doc.data();
        final splitBetween = expense['splitBetween'] as List<dynamic>? ?? [];

        print("🔥 Firestore Expense Data: $expense"); // ✅ Debugging log

        // Convert UIDs to names
        final updatedSplit = await Future.wait(splitBetween.map((entry) async {
          if (entry == null || entry['uid'] == null) {
            print("⚠️ Skipping invalid entry in splitBetween: $entry");
            return {"name": "Unknown User", "share": 0.0};
          }
          final name = await getUserName(entry['uid']);
          return {"name": name, "share": entry['share']};
        }));

        print("✅ Final mapped names: $updatedSplit"); // ✅ Debugging log

        return {
          'id': doc.id,
          'name': expense['name'] ?? 'Unknown Expense',
          'amount': (expense['amount'] as num?)?.toDouble() ?? 0.0,
          'splitBetween': updatedSplit,
          'paid': expense['paid'] ?? false,
        };
      }).toList());
    });
  }

  /// Deletes an expense
  Future<void> deleteExpense(String expenseId) async {
    final householdId = await getHouseholdId();
    if (householdId == null) return;

    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  /// Marks an expense as paid
  Future<void> markAsPaid(String expenseId, bool isPaid) async {
    final householdId = await getHouseholdId();
    if (householdId == null) return;

    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('expenses')
        .doc(expenseId)
        .update({'paid': isPaid});
  }
}
