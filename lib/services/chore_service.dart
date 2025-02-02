import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves the household ID of the current user
  Future<String?> getHouseholdId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['householdId'];
  }

  /// Adds a new chore to Firestore
  Future<void> addChore({
    required String task,
    required String assignee,
  }) async {
    final householdId = await getHouseholdId();
    if (householdId == null) {
      throw Exception("Household ID not found.");
    }

    await _firestore.collection('households')
      .doc(householdId)
      .collection('chores')
      .add({
        'task': task,
        'assignee': assignee,
        'completed': false, // Default: Not completed
        'createdAt': FieldValue.serverTimestamp(),
      });
  }

  /// Fetches all chores for the current user's household
  Stream<List<Map<String, dynamic>>> getChores() async* {
    final householdId = await getHouseholdId();
    if (householdId == null) yield [];

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Marks a chore as completed or incomplete
  Future<void> toggleChoreCompletion(String choreId, bool isCompleted) async {
    final householdId = await getHouseholdId();
    if (householdId == null) return;

    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .doc(choreId)
        .update({'completed': isCompleted});
  }

  /// Deletes a chore from Firestore
  Future<void> deleteChore(String choreId) async {
    final householdId = await getHouseholdId();
    if (householdId == null) return;

    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .doc(choreId)
        .delete();
  }
}
