import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Add chore with `assigneeUid`
  Future<void> addChore({required String task, required String assigneeUid}) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final String userId = user.uid; // ✅ This is always available, no need for nullable `?`
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) throw Exception("Household ID not found");

    // Fetch assignee's name
    final assigneeDoc = await _firestore.collection('users').doc(assigneeUid).get();
    final String assigneeName = assigneeDoc.data()?['name'] ?? 'Unknown'; // ✅ Non-nullable

    await _firestore.collection('households').doc(householdId).collection('chores').add({
      'task': task,
      'assignedTo': assigneeUid, // ✅ Storing UID instead of name
      'assignedToName': assigneeName, // ✅ Also store name for UI
      'completed': false,
      'createdBy': userId, // ✅ Ensuring task creator is stored
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Get household chores
  Stream<List<Map<String, dynamic>>> getChores() async* {
    final User? user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    final String userId = user.uid; // ✅ No need for nullable
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('chores')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// ✅ Toggle chore completion
  Future<void> toggleChoreCompletion(String choreId, bool completed) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final String userId = user.uid; // ✅ No need for nullable
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) return;

    await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).update({
      'completed': completed,
    });
  }

  /// ✅ Delete chore
  Future<void> deleteChore(String choreId) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final String userId = user.uid; // ✅ No need for nullable
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) return;

    await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).delete();
  }
}
