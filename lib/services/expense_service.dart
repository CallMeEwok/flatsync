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

  /// Adds a new expense to the Firestore database under the correct household
  Future<void> addExpense({
    required String name,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
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
        'paidBy': paidBy,
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
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
