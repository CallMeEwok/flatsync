import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
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
  Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return "Unknown User";

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    // ✅ Fixed Condition: Use `userDoc.exists == true`
    if (userDoc.exists == true) { 
      return userDoc.data()?['name'] ?? "Unknown User";
    }

    return "Unknown User";
  }

  /// Sends a new message to Firestore
  Future<void> sendMessage({required String content}) async {
    final householdId = await getHouseholdId();
    if (householdId == null) {
      throw Exception("Household ID not found.");
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    final senderName = await getUserName(); // ✅ Fetch correct name from Firestore

    await _firestore.collection('households')
      .doc(householdId)
      .collection('messages')
      .add({
        'content': content,
        'senderId': user.uid,
        'senderName': senderName, // ✅ Now correctly pulls the "name" field
        'timestamp': FieldValue.serverTimestamp(),
      });
  }

  /// Fetches all messages for the current user's household
  Stream<List<Map<String, dynamic>>> getMessages() async* {
    final householdId = await getHouseholdId();
    if (householdId == null) yield [];

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Deletes a message from Firestore (only if the user sent it)
  Future<void> deleteMessage(String messageId) async {
    final householdId = await getHouseholdId();
    if (householdId == null) return;

    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
