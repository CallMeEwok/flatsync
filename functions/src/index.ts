import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// ✅ Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ✅ Cloud Function to send notifications when a new message is added
export const sendMessageNotification = onDocumentCreated(
  "households/{householdId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    const householdId = event.params.householdId;
    const senderName = messageData.senderName;
    const content = messageData.content;

    // ✅ Fetch all users in the household
    const usersSnapshot = await
    db.collection("users").where("householdId", "==", householdId).get();

    const tokens: string[] = [];
    usersSnapshot.forEach((userDoc) => {
      const fcmToken = userDoc.data().fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    });

    if (tokens.length > 0) {
      // ✅ Send push notification
      const payload = {
        notification: {
          title: `New Message from ${senderName}`,
          body: content,
        },
        tokens,
      };

      await messaging.sendEachForMulticast(payload);
    }
  }
);
