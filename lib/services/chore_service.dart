// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Add chore with `assigneeUid` and send notification
  Future<void> addChore({
    required String task,
    required String assigneeUid,
    required DateTime dueDate,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final String userId = user.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) throw Exception("Household ID not found");

    // Fetch assignee's name and FCM token
    final assigneeDoc = await _firestore.collection('users').doc(assigneeUid).get();
    final String assigneeName = assigneeDoc.data()?['name'] ?? 'Unknown';
    final String? assigneeFcmToken = assigneeDoc.data()?['fcmToken']; // ✅ Get FCM token

    await _firestore.collection('households').doc(householdId).collection('chores').add({
      'task': task,
      'assignedTo': assigneeUid,
      'assignedToName': assigneeName,
      'completed': false,
      'createdBy': userId,
      'dueDate': Timestamp.fromDate(dueDate),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Send FCM notification to the assignee
    if (assigneeFcmToken != null) {
      await _sendFCMNotification(
        token: assigneeFcmToken,
        title: "New Chore Assigned",
        body: "You have been assigned a new chore: $task",
      );
    }
  }

  /// ✅ Get household chores
  Stream<List<Map<String, dynamic>>> getChores() async* {
    final User? user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    final String userId = user.uid;
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

    final String userId = user.uid;
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

    final String userId = user.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) return;

    await _firestore.collection('households').doc(householdId).collection('chores').doc(choreId).delete();
  }

  /// ✅ Send FCM Notification
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('fcmRequests').add({
        "to": token,
        "notification": {
          "title": title,
          "body": body,
          "sound": "default",
        },
        "priority": "high",
      });
    } catch (e) {
      print("❌ Error sending FCM notification: $e");
    }
  }
}