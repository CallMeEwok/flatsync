import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";

// ✅ Initialize Firebase Admin SDK
initializeApp();

// ✅ Simple test function to verify deployment
export const helloWorld = onRequest((req, res) => {
  res.send("Hello from Firebase Cloud Functions!");
});
