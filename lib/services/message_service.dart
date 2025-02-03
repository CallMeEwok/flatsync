import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// Sends a new message to Firestore and triggers a push notification
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

    // ✅ Save message in Firestore
    await _firestore.collection('households')
      .doc(householdId)
      .collection('messages')
      .add({
        'content': content,
        'senderId': user.uid,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
      });

    // ✅ Send push notifications to all household members
    await sendNotificationsToHousehold(householdId, senderName, content);
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

  /// Fetches all household members and sends a push notification
  Future<void> sendNotificationsToHousehold(
      String householdId, String senderName, String content) async {
    final householdUsers = await _firestore
        .collection('users')
        .where('householdId', isEqualTo: householdId)
        .get();

    for (var userDoc in householdUsers.docs) {
      String? fcmToken = userDoc.data()['fcmToken'];
      if (fcmToken != null) {
        await sendPushNotification(fcmToken, "New Message from $senderName", content);
      }
    }
  }

  /// Sends a push notification using Firebase Cloud Messaging
  Future<void> sendPushNotification(
      String token, String title, String body) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=YOUR_SERVER_KEY' // 🔴 Replace with Firebase server key
    };

    final bodyData = {
      'to': token,
      'notification': {'title': title, 'body': body}
    };

    await http.post(url, headers: headers, body: jsonEncode(bodyData));
  }
}
