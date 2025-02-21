"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendMessageNotification = exports.sendChoreReminders = void 0;

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// ✅ Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ✅ Force Firestore to Always Use SSL
db.settings({ host: "firestore.googleapis.com", ssl: true });

// ✅ Cloud Function to send notifications for all services\\
exports.sendMessageNotification = onDocumentCreated(
    "households/{householdId}/notifications/{notificationId}",
    async (event) => {
        const notificationData = event.data?.data();
        if (!notificationData) return;

        const householdId = event.params.householdId;
        const title = notificationData.title;
        const body = notificationData.body;
        const senderId = notificationData.senderId; // Prevent sender from receiving their own notification

        // ✅ Fetch all users in the household (EXCEPT the sender)
        const usersSnapshot = await db
            .collection("users")
            .where("householdId", "==", householdId)
            .get();

        const tokens = [];
        usersSnapshot.forEach((userDoc) => {
            const userData = userDoc.data();
            if (userData.fcmToken && userDoc.id !== senderId) {
                tokens.push(userData.fcmToken);
            }
        });

        // ✅ Send Push Notification if tokens exist
        if (tokens.length > 0) {
            const payload = {
                notification: {
                    title: title,
                    body: body,
                },
                tokens,
            };
            await messaging.sendEachForMulticast(payload);
        }
    }
);

// ✅ Scheduled Function to Send Chore Due Date Reminders
exports.sendChoreReminders = onSchedule("every 1 hours", async () => {
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