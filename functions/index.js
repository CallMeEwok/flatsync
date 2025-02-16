"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendMessageNotification = exports.sendChoreReminders = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");

// ✅ Initialize Firebase Admin SDK
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const messaging = (0, messaging_1.getMessaging)();

// ✅ Cloud Function to send notifications when a new message is added
exports.sendMessageNotification = (0, firestore_1.onDocumentCreated)(
    "households/{householdId}/messages/{messageId}",
    async (event) => {
        var _a;
        const messageData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!messageData) return;

        const householdId = event.params.householdId;
        const senderName = messageData.senderName;
        const content = messageData.content;

        // ✅ Fetch all users in the household
        const usersSnapshot = await db.collection("users").where("householdId", "==", householdId).get();
        const tokens = [];
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

// ✅ Scheduled Function to Send Chore Due Date Reminders
exports.sendChoreReminders = (0, scheduler_1.onSchedule)("every 1 hours", async () => {
    console.log("⏰ Running scheduled task to check for chore reminders...");

    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    const oneDayLater = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    try {
        // ✅ Get all households
        const householdsSnapshot = await db.collection("households").get();
        for (const householdDoc of householdsSnapshot.docs) {
            const householdId = householdDoc.id;

            // ✅ Fetch chores that are due soon (either in 1 hour or 1 day)
            const choresSnapshot = await db
                .collection("households")
                .doc(householdId)
                .collection("chores")
                .where("completed", "==", false)
                .where("dueDate", ">=", now)
                .where("dueDate", "<=", oneDayLater)
                .get();

            for (const choreDoc of choresSnapshot.docs) {
                const choreData = choreDoc.data();
                const choreId = choreDoc.id;
                const task = choreData.task;
                const dueDate = choreData.dueDate.toDate();
                const assignedTo = choreData.assignedTo;

                let reminderType = null;
                if (dueDate <= oneHourLater) {
                    reminderType = "⏳ 1 Hour Reminder";
                } else if (dueDate <= oneDayLater) {
                    reminderType = "📅 1 Day Reminder";
                }

                if (reminderType) {
                    // ✅ Fetch assignee details
                    const userDoc = await db.collection("users").doc(assignedTo).get();
                    const fcmToken = userDoc.data()?.fcmToken;
                    const assigneeName = userDoc.data()?.name || "Unknown";

                    if (fcmToken) {
                        console.log(`🔔 Sending ${reminderType} to ${assigneeName} for chore: ${task}`);

                        // ✅ Send FCM Notification
                        const payload = {
                            notification: {
                                title: `${reminderType} - Chore Due`,
                                body: `Reminder: Your chore '${task}' is due soon.`,
                            },
                            token: fcmToken,
                        };

                        await messaging.send(payload);
                    }
                }
            }
        }
        console.log("✅ Chore reminder check completed.");
    } catch (error) {
        console.error("❌ Error sending chore reminders:", error);
    }
});