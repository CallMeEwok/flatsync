// ignore_for_file: avoid_print

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

    if (userDoc.exists == true) {
      return userDoc.data()?['name'] ?? "Unknown User";
    }

    return "Unknown User";
  }

  /// Sends a new message to Firestore (Triggers Cloud Function for notifications)
  Future<void> sendMessage({required String content}) async {
    final householdId = await getHouseholdId();
    if (householdId == null) {
      throw Exception("Household ID not found.");
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    final senderName = await getUserName();

    // ✅ Save message in Firestore (Triggers Cloud Function)
    await _firestore.collection('households')
      .doc(householdId)
      .collection('messages')
      .add({
        'content': content,
        'senderId': user.uid,
        'senderName': senderName,
        'householdId': householdId, // ✅ Now storing householdId
        'timestamp': FieldValue.serverTimestamp(),
      });
  }

  /// Fetches all messages for the current user's household
  /// Fetches all messages for the current user's household
Stream<List<Map<String, dynamic>>> getMessages() async* {
  final householdId = await getHouseholdId();
  print("Retrieved Household ID: $householdId"); // Debug log

  if (householdId == null) {
    print("No household ID found, returning empty list.");
    yield [];
    return;
  }

  yield* _firestore
      .collection('households')
      .doc(householdId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        print("Messages retrieved: ${snapshot.docs.length}"); // Debug log
        return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
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
