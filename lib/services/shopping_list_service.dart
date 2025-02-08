// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Retrieves household members' FCM tokens to send notifications.
  Future<List<String>> _getHouseholdMemberTokens(String householdId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('householdId', isEqualTo: householdId)
        .where('fcmToken', isNotEqualTo: null) // Only get members with FCM tokens
        .get();

    return querySnapshot.docs
        .map((doc) => doc['fcmToken'] as String)
        .toList();
  }

  /// ✅ Sends a notification to all household members
  Future<void> sendNotification({
    required String householdId,
    required String title,
    required String message,
  }) async {
    final tokens = await _getHouseholdMemberTokens(householdId);
    if (tokens.isEmpty) {
      return;
    }

    // Store notification in Firestore for UI tracking
    await _firestore.collection('households')
        .doc(householdId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Call Firebase Cloud Messaging to send notifications
    for (String token in tokens) {
      await _sendFCMNotification(token, title, message);
    }
  }

  /// ✅ Calls Firebase Cloud Messaging API
  Future<void> _sendFCMNotification(String token, String title, String body) async {
    final data = {
      "to": token,
      "notification": {
        "title": title,
        "body": body,
        "sound": "default",
      },
      "priority": "high",
    };

    try {
      final response = await FirebaseFirestore.instance
          .collection('fcmRequests')
          .add({"payload": data});

      // ignore: duplicate_ignore
      // ignore: avoid_print
      print("📤 Notification sent: $response");
    } catch (e) {
      print("❌ Error sending FCM notification: $e");
    }
  }
}
