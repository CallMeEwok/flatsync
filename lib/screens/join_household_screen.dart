import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinHouseholdScreen extends StatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  State<JoinHouseholdScreen> createState() => _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends State<JoinHouseholdScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  Future<void> _joinHousehold() async {
    final String inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an invite code.";
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "You must be logged in to join a household.";
          _isJoining = false;
        });
        return;
      }

      final String userId = user.uid;

      // ✅ 1. Check if the invite exists and is valid
      final inviteDoc = await FirebaseFirestore.instance.collection('invites').doc(inviteCode).get();
      if (!inviteDoc.exists || inviteDoc.data() == null || inviteDoc['used'] == true) {
        setState(() {
          _errorMessage = "Invalid or expired invite code.";
          _isJoining = false;
        });
        return;
      }

      final String householdId = inviteDoc['householdId'];

      // ✅ 2. Ensure user document exists before updating
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // If user document doesn't exist, create it before assigning household
        await userDocRef.set({
          'householdId': householdId,
          'name': user.displayName ?? "Unknown", // Fallback for missing name
          'email': user.email ?? "",
          'createdAt': FieldValue.serverTimestamp(),
          'role': "member", // Default role for a new household member
        });
      } else {
        // ✅ 3. Update the user's householdId if document exists
        await userDocRef.update({
          'householdId': householdId,
        });
      }

      // ✅ 4. Mark the invite as used
      await FirebaseFirestore.instance.collection('invites').doc(inviteCode).update({
        'used': true,
      });

      debugPrint("✅ Successfully joined household: $householdId");

      // ✅ 5. Navigate to the home screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      debugPrint("❌ Error joining household: $e");
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Household')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your invite code to join an existing household:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: "Invite Code",
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isJoining ? null : _joinHousehold,
              child: _isJoining
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Join Household"),
            ),
          ],
        ),
      ),
    );
  }
}
